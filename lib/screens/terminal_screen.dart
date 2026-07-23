import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';

class TerminalScreen extends StatefulWidget {
  const TerminalScreen({super.key});
  @override State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _usdController = TextEditingController(text: '10');
  final _tpController = TextEditingController(text: '50');
  final _slController = TextEditingController(text: '20');
  double _expectedProfit = 5.00;
  bool _isLoading = false;

  @override void initState() {
    super.initState();
    _usdController.addListener(_updateCalc);
    _tpController.addListener(_updateCalc);
  }
  
  void _updateCalc() {
    final tp = double.tryParse(_tpController.text) ?? 0;
    final size = double.tryParse(_usdController.text) ?? 0;
    setState(() => _expectedProfit = size * (tp / 100));
  }
  
  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) _tokenController.text = data.text!.trim();
  }
  
  String? _validateSolanaAddress(String? value) {
    if (value == null || value.trim().isEmpty) return 'Address required';
    if (!RegExp(r'^[1-9A-HJ-NP-Za-km-z]{32,44}$').hasMatch(value.trim())) return 'Invalid Solana address format';
    return null;
  }
  
  Future<void> _executeSnipe() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final api = context.read<ApiService>();
    final res = await api.postEndpoint('trade.php?action=manual_snipe', {
      'token_address': _tokenController.text.trim(),
      'trade_usd': _usdController.text,
      'tp_percent': _tpController.text,
      'sl_percent': _slController.text,
    });
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['message'] ?? 'Trade deployed!'),
        backgroundColor: res['status'] == 'success' ? Colors.green : Colors.red,
      ));
      if (res['status'] == 'success') _tokenController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: const Text('MANUAL TERMINAL', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 2, color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [Icon(PhosphorIcons.crosshairFill, color: theme.primaryColor), const SizedBox(width: 8), const Text('Target Contract', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))]),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _tokenController,
                      style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13),
                      decoration: InputDecoration(labelText: 'Solana Token Address', labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant), suffixIcon: IconButton(icon: Icon(PhosphorIcons.clipboard, color: theme.primaryColor), onPressed: _pasteFromClipboard), filled: true, fillColor: Colors.black.withOpacity(0.2), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                      validator: _validateSolanaAddress,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('EXECUTION PARAMETERS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: TextFormField(controller: _usdController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: 'Trade Size (\$)', labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant), filled: true, fillColor: Colors.black.withOpacity(0.2), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))),
                        const SizedBox(width: 12),
                        Expanded(child: TextFormField(controller: _tpController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.greenAccent), decoration: InputDecoration(labelText: 'Take Profit (%)', labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant), filled: true, fillColor: Colors.black.withOpacity(0.2), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(12)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Projected Target Profit:', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)), Text('+\$${_expectedProfit.toStringAsFixed(2)}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14))])),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: LinearGradient(colors: [theme.primaryColor, const Color(0xFFE024CE)]), boxShadow: [BoxShadow(color: theme.primaryColor.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5))]),
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _executeSnipe,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 18)),
                    icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Icon(PhosphorIcons.rocketLaunchFill, color: Colors.white),
                    label: Text(_isLoading ? 'SNIPING...' : 'DEPLOY CONTRACT', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
