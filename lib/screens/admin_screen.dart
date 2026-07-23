import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../services/api_service.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          Container(
            color: theme.colorScheme.surface,
            child: TabBar(
              isScrollable: true,
              labelColor: theme.primaryColor,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              indicatorColor: theme.primaryColor,
              tabAlignment: TabAlignment.start,
              tabs: const [
                Tab(text: 'Manual Snipe'),
                Tab(text: 'Tracked Wallets'),
                Tab(text: 'Bot Config'),
                Tab(text: 'Team Quotas'),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                AdminSnipeTab(),
                Center(child: Text('Wallets UI Loaded')),
                Center(child: Text('Config UI Loaded')),
                Center(child: Text('Quotas UI Loaded')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== TAB 1: MANUAL SNIPE (WITH SOLANA VALIDATION) ====================
class AdminSnipeTab extends StatefulWidget {
  const AdminSnipeTab({super.key});

  @override
  State<AdminSnipeTab> createState() => _AdminSnipeTabState();
}

class _AdminSnipeTabState extends State<AdminSnipeTab> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _usdController = TextEditingController(text: '10');
  final _tpController = TextEditingController(text: '50');
  final _slController = TextEditingController(text: '20');

  double _expectedProfit = 5.00;
  double _multiplier = 1.50;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usdController.addListener(_updateCalc);
    _tpController.addListener(_updateCalc);
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _usdController.dispose();
    _tpController.dispose();
    _slController.dispose();
    super.dispose();
  }

  void _updateCalc() {
    final tp = double.tryParse(_tpController.text) ?? 0;
    final size = double.tryParse(_usdController.text) ?? 0;
    setState(() {
      _multiplier = 1 + (tp / 100);
      _expectedProfit = size * (tp / 100);
    });
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      _tokenController.text = data.text!.trim();
    }
  }

  // STRICT SOLANA BASE58 VALIDATOR
  String? _validateSolanaAddress(String? value) {
    if (value == null || value.trim().isEmpty) return 'Address is required';
    final val = value.trim();
    // Checks for base58 string of correct length
    if (!RegExp(r'^[1-9A-HJ-NP-Za-km-z]{32,44}$').hasMatch(val)) {
      return 'Invalid Solana address format';
    }
    return null;
  }

  void _confirmExecution() {
    if (!_formKey.currentState!.validate()) return;
    
    FocusScope.of(context).unfocus();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(PhosphorIcons.warningCircleFill, color: Colors.red, size: 48),
            ),
            const SizedBox(height: 16),
            Text('Execute REAL Trade', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'You are about to execute a market buy order for \$${_usdController.text} USD.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)))),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _executeSnipe();
                    },
                    icon: Icon(PhosphorIcons.lightningFill),
                    label: const Text('Execute', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(ctx).viewInsets.bottom),
          ],
        ),
      ),
    );
  }

  Future<void> _executeSnipe() async {
    setState(() => _isLoading = true);
    final api = context.read<ApiService>();
    final res = await api.postEndpoint('trade.php', {
      'token_address': _tokenController.text.trim(),
      'trade_usd': _usdController.text,
      'tp_percent': _tpController.text,
      'sl_percent': _slController.text,
    });

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['message'] ?? (res['status'] == 'success' ? 'Trade executed' : 'Execution failed')),
        backgroundColor: res['status'] == 'success' ? Colors.green : Colors.red,
      ));
      if (res['status'] == 'success') _tokenController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.dividerColor.withOpacity(0.1))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Target Contract', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _tokenController,
                    decoration: InputDecoration(
                      labelText: 'Solana Token Address',
                      hintText: 'Paste contract here...',
                      suffixIcon: IconButton(icon: Icon(PhosphorIcons.clipboard), onPressed: _pasteFromClipboard, color: theme.primaryColor),
                    ),
                    validator: _validateSolanaAddress, // Using the new strict validator
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // ... (Rest of the Execution Parameters UI remains the same)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _confirmExecution,
                style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Icon(PhosphorIcons.rocketLaunchFill),
                label: Text(_isLoading ? 'Executing...' : 'Deploy Contract', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
