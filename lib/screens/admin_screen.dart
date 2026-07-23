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
      length: 3,
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
                Tab(text: 'Team Quotas'),
                Tab(text: 'Tracked Wallets'),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                AdminSnipeTab(),
                Center(child: Text('Team Quotas (Next Phase)')),
                Center(child: Text('Tracked Wallets (Next Phase)')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(PhosphorIcons.warningCircleFill, color: Colors.red, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              'Execute REAL Trade',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'You are about to execute a market buy order for \$${_usdController.text} USD using real funds from the master wallet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _executeSnipe();
                    },
                    icon: Icon(PhosphorIcons.lightningFill),
                    label: const Text('Execute Snipe', style: TextStyle(fontWeight: FontWeight.bold)),
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
      'token_address': _tokenController.text,
      'trade_usd': _usdController.text,
      'tp_percent': _tpController.text,
      'sl_percent': _slController.text,
    });

    if (mounted) {
      setState(() => _isLoading = false);
      if (res['status'] == 'success') {
        _tokenController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Trade executed'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Execution failed'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(PhosphorIcons.magnifyingGlassBold, color: theme.primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Text('Target Contract', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _tokenController,
                    decoration: InputDecoration(
                      labelText: 'Solana Token Address',
                      hintText: 'Paste contract here...',
                      suffixIcon: IconButton(
                        icon: Icon(PhosphorIcons.clipboard),
                        onPressed: _pasteFromClipboard,
                        color: theme.primaryColor,
                      ),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Address required' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(PhosphorIcons.slidersBold, color: theme.primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Text('Execution Parameters', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _usdController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Trade Size (USD)',
                      prefixIcon: Icon(PhosphorIcons.currencyDollar),
                    ),
                    validator: (v) => v == null || double.tryParse(v) == null ? 'Invalid size' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _tpController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Take Profit (%)',
                            prefixIcon: Icon(PhosphorIcons.trendUp, color: Colors.green),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _slController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Stop Loss (%)',
                            prefixIcon: Icon(PhosphorIcons.trendDown, color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(PhosphorIcons.calculatorFill, color: theme.colorScheme.onSurfaceVariant, size: 16),
                      const SizedBox(width: 8),
                      Text('LIVE PROFIT CALCULATOR', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Target Multiplier:', style: TextStyle(fontWeight: FontWeight.w500)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text('${_multiplier.toStringAsFixed(2)}x', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Expected Profit at TP:', style: TextStyle(fontWeight: FontWeight.w500)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text('\$${_expectedProfit.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _confirmExecution,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                icon: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Icon(PhosphorIcons.rocketLaunchFill),
                label: Text(
                  _isLoading ? 'Executing...' : 'Deploy Contract', 
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
