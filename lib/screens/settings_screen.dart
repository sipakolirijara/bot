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
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _showUpdateKeyModal() async {
    final ctrl = TextEditingController();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: const Color(0xFF13131A),
          title: Row(
            children: [
              Icon(PhosphorIcons.keyFill, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              const Text('Update Private Key', style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          content: TextField(
            controller: ctrl,
            obscureText: true,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Paste Solana Base58 Private Key or Array',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.black26,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
              onPressed: isSubmitting ? null : () async {
                if (ctrl.text.trim().isEmpty) return;
                setStateDialog(() => isSubmitting = true);
                
                final res = await this.context.read<ApiService>().postEndpoint('wallet.php?action=set_key', {'private_key': ctrl.text.trim()});
                
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(
                    content: Text(res['message'] ?? ''),
                    backgroundColor: res['status'] == 'success' ? Colors.green : Colors.red,
                  ));
                  
                  // IMMEDIATELY UPDATE UI STATE
                  if (res['status'] == 'success' && res['data'] != null) {
                    setState(() {
                      _hasWallet = true;
                      _publicAddress = res['data']['public_address'];
                    });
                  }
                }
              },
              child: isSubmitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Save Key', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteKeyModal() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF13131A),
        title: const Row(
          children: [
            Icon(PhosphorIcons.warningCircleFill, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Remove Wallet?', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: const Text('This will permanently delete your encrypted private key from the server. You will not be able to execute trades until you add a new one.', style: TextStyle(color: Colors.white70, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final res = await context.read<ApiService>().postEndpoint('wallet.php?action=delete_key', {});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['message'] ?? ''),
        backgroundColor: res['status'] == 'success' ? Colors.green : Colors.red,
      ));
      
      // IMMEDIATELY UPDATE UI STATE
      if (res['status'] == 'success') {
        setState(() {
          _hasWallet = false;
          _publicAddress = null;
        });
      }
    }
  }

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
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                        child: Icon(PhosphorIcons.shieldCheckFill, color: theme.primaryColor),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Account Credentials', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('Manage security & password', style: TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                      ),
                      Icon(PhosphorIcons.pencilSimple, color: Colors.white54),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [Icon(PhosphorIcons.fingerprint, color: Colors.white54, size: 20), const SizedBox(width: 8), const Text('Biometric Quick-Lock', style: TextStyle(color: Colors.white))]),
                      Switch(value: _biometricEnabled, activeColor: theme.primaryColor, onChanged: (v) => setState(() => _biometricEnabled = v)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [Icon(PhosphorIcons.walletFill, color: theme.primaryColor), const SizedBox(width: 8), const Text('Execution Wallet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))]),
                      if (_hasWallet)
                        IconButton(
                          icon: const Icon(PhosphorIcons.trash, color: Colors.redAccent, size: 20),
                          onPressed: _showDeleteKeyModal,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('PUBLIC ADDRESS', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _hasWallet ? (_publicAddress ?? 'Error loading') : 'No wallet connected',
                            style: TextStyle(color: _hasWallet ? Colors.white : Colors.white38, fontFamily: 'monospace', fontSize: 13),
                          ),
                        ),
                        if (_hasWallet) const Icon(PhosphorIcons.checkCircleFill, color: Colors.greenAccent, size: 18),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.white.withOpacity(0.1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _showUpdateKeyModal,
                      icon: const Icon(PhosphorIcons.key, color: Colors.white),
                      label: Text(_hasWallet ? 'Update Key' : 'Add Private Key', style: const TextStyle(color: Colors.white)),
                    ),
                  )
                ],
              ),
            ),
          ],
        );
  }
}
