import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = true;
  bool _hasWallet = false;
  String? _publicAddress;
  bool _biometricEnabled = true;

  bool _allowTelegram = false;
  final _telegramCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    setState(() => _isLoading = true);
    final res = await context.read<ApiService>().getEndpoint('wallet.php?action=get');
    if (mounted) {
      setState(() {
        if (res['status'] == 'success' && res['data'] != null) {
          _hasWallet = res['data']['has_wallet'] ?? false;
          _publicAddress = res['data']['public_address'];
          _allowTelegram = res['data']['allow_telegram_alerts'] ?? false;
          _telegramCtrl.text = res['data']['telegram_chat_id'] ?? '';
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _saveTelegramId() async {
    if (_telegramCtrl.text.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saving...')));
    
    final res = await context.read<ApiService>().postEndpoint('wallet.php?action=set_telegram', {
      'telegram_chat_id': _telegramCtrl.text.trim()
    });
    
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(res['message'] ?? ''),
      backgroundColor: res['status'] == 'success' ? Colors.green : Colors.red,
    ));
  }

  // ... [Keep your existing _showUpdateKeyModal and _showDeleteKeyModal here exactly as they were] ...

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _isLoading 
      ? const Center(child: CircularProgressIndicator()) 
      : ListView(
          padding: const EdgeInsets.all(24),
          children: [
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.1), shape: BoxShape.circle), child: Icon(PhosphorIcons.shieldCheckFill, color: theme.primaryColor)),
                      const SizedBox(width: 16),
                      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Account Credentials', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)), Text('Manage security & password', style: TextStyle(color: Colors.white54, fontSize: 12))])),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: const [Icon(PhosphorIcons.fingerprint, color: Colors.white54, size: 20), SizedBox(width: 8), Text('Biometric Quick-Lock', style: TextStyle(color: Colors.white))]), Switch(value: _biometricEnabled, activeColor: theme.primaryColor, onChanged: (v) => setState(() => _biometricEnabled = v))]),
                ],
              ),
            ),
            const SizedBox(height: 24),
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [Icon(PhosphorIcons.telegramLogoFill, color: Colors.blueAccent), const SizedBox(width: 8), const Text('Personal Telegram Alerts', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))]),
                  const SizedBox(height: 16),
                  if (!_allowTelegram)
                    const Text('Your admin has disabled personal Telegram alerts for your account.', style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold))
                  else ...[
                    const Text('Send /start to your bot on Telegram to get your Chat ID, then paste it below to receive personal trade notifications.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _telegramCtrl,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(hintText: 'Enter Telegram Chat ID', hintStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: Colors.black26, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(vertical: 14)),
                          onPressed: _saveTelegramId,
                          child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        )
                      ],
                    )
                  ]
                ],
              ),
            ),
          ],
        );
  }
}
