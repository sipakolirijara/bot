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
  List<dynamic> _strategies = [];
  bool _quickLockEnabled = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final api = context.read<ApiService>();
    
    final responses = await Future.wait([
      api.getEndpoint('wallet.php?action=get'),
      api.getEndpoint('strategies.php?action=fetch'),
    ]);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (responses[0]['status'] == 'success') {
          _hasWallet = responses[0]['data']['has_wallet'] ?? false;
          _publicAddress = responses[0]['data']['public_address'];
        }
        if (responses[1]['status'] == 'success') {
          _strategies = responses[1]['data']['strategies'] ?? [];
        }
      });
    }
  }

  // --- PASSWORD UPDATE MODAL ---
  void _showPasswordModal() {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();
    bool obscureOld = true;
    bool obscureNew = true;
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
          child: GlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(PhosphorIcons.lockKeyFill, color: Colors.white),
                    const SizedBox(width: 8),
                    Text('Update Password', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Verification required to update account security.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                const SizedBox(height: 20),
                TextField(
                  controller: oldPassController, obscureText: obscureOld, style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(labelText: 'Current Password', labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant), prefixIcon: Icon(PhosphorIcons.lockKey, color: theme.colorScheme.onSurfaceVariant), suffixIcon: IconButton(icon: Icon(obscureOld ? PhosphorIcons.eyeClosed : PhosphorIcons.eye, color: theme.colorScheme.onSurfaceVariant), onPressed: () => setModalState(() => obscureOld = !obscureOld)), filled: true, fillColor: Colors.black.withOpacity(0.2), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPassController, obscureText: obscureNew, style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(labelText: 'New Password', labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant), prefixIcon: Icon(PhosphorIcons.key, color: theme.colorScheme.onSurfaceVariant), suffixIcon: IconButton(icon: Icon(obscureNew ? PhosphorIcons.eyeClosed : PhosphorIcons.eye, color: theme.colorScheme.onSurfaceVariant), onPressed: () => setModalState(() => obscureNew = !obscureNew)), filled: true, fillColor: Colors.black.withOpacity(0.2), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: LinearGradient(colors: [theme.primaryColor, const Color(0xFFE024CE)])),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 16)),
                      onPressed: () async {
                        if (oldPassController.text.isEmpty || newPassController.text.isEmpty) return;
                        Navigator.pop(ctx);
                        final api = context.read<ApiService>();
                        final res = await api.postEndpoint('auth.php?action=change_password', {'old_password': oldPassController.text, 'new_password': newPassController.text});
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Password update processed'), backgroundColor: res['status'] == 'success' ? Colors.green : Colors.red));
                      },
                      child: const Text('Confirm Security Update', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- PRIVATE KEY MODAL ---
  void _showPrivateKeyModal() {
    final keyController = TextEditingController();
    bool obscureKey = true;
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
          child: GlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [Icon(PhosphorIcons.walletFill, color: theme.primaryColor), const SizedBox(width: 8), Text('Secure Wallet Link', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white))]),
                const SizedBox(height: 8),
                Text('AES-256 encrypted instantly on the backend server.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                const SizedBox(height: 20),
                TextField(
                  controller: keyController, obscureText: obscureKey, style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(labelText: 'Solana Private Key', labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant), prefixIcon: Icon(PhosphorIcons.key, color: theme.colorScheme.onSurfaceVariant), suffixIcon: IconButton(icon: Icon(obscureKey ? PhosphorIcons.eyeClosed : PhosphorIcons.eye, color: theme.colorScheme.onSurfaceVariant), onPressed: () => setModalState(() => obscureKey = !obscureKey)), filled: true, fillColor: Colors.black.withOpacity(0.2), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: LinearGradient(colors: [theme.primaryColor, const Color(0xFFE024CE)])),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 16)),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        if (keyController.text.trim().isEmpty) return;
                        setState(() => _isLoading = true);
                        final api = context.read<ApiService>();
                        final res = await api.postEndpoint('wallet.php?action=set_key', {'private_key': keyController.text.trim()});
                        if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? ''), backgroundColor: res['status'] == 'success' ? Colors.green : Colors.red)); _fetchData(); }
                      },
                      child: const Text('Encrypt & Save', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- COPY TRADING STRATEGY MODAL ---
  void _showStrategyModal(Map<String, dynamic> strat) {
    final assign = strat['assignment'] ?? {};
    bool isEnabled = assign['enabled'] == true;
    final usdController = TextEditingController(text: assign['trade_usd_amount'].toString());
    final tpController = TextEditingController(text: assign['tp_percent'].toString());
    final slController = TextEditingController(text: assign['sl_percent'].toString());
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
          child: GlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(PhosphorIcons.robotFill, color: isEnabled ? Colors.greenAccent : theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Text(strat['label'] ?? 'Strategy', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                    Switch(
                      value: isEnabled,
                      activeColor: Colors.greenAccent,
                      onChanged: (val) => setModalState(() => isEnabled = val),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Address: ${strat['address']}', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 10, fontFamily: 'monospace')),
                const SizedBox(height: 20),
                TextField(
                  controller: usdController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(labelText: 'Trade Size (\$ USD)', labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant), prefixIcon: Icon(PhosphorIcons.currencyDollar, color: theme.colorScheme.onSurfaceVariant), filled: true, fillColor: Colors.black.withOpacity(0.2), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: tpController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.greenAccent),
                        decoration: InputDecoration(labelText: 'Take Profit (%)', labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant), prefixIcon: Icon(PhosphorIcons.trendUp, color: Colors.greenAccent), filled: true, fillColor: Colors.black.withOpacity(0.2), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: slController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.redAccent),
                        decoration: InputDecoration(labelText: 'Stop Loss (%)', labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant), prefixIcon: Icon(PhosphorIcons.trendDown, color: Colors.redAccent), filled: true, fillColor: Colors.black.withOpacity(0.2), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: LinearGradient(colors: [theme.primaryColor, const Color(0xFFE024CE)])),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 16)),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        setState(() => _isLoading = true);
                        final api = context.read<ApiService>();
                        final res = await api.postEndpoint('strategies.php?action=assign', {
                          'wallet_id': strat['wallet_id'],
                          'trade_usd_amount': usdController.text,
                          'tp_percent': tpController.text,
                          'sl_percent': slController.text,
                          'enabled': isEnabled,
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Strategy updated'), backgroundColor: res['status'] == 'success' ? Colors.green : Colors.red));
                          _fetchData();
                        }
                      },
                      child: const Text('Save Execution Strategy', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading && _strategies.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      color: theme.primaryColor,
      backgroundColor: theme.colorScheme.surface,
      child: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          // Security Profile Card
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.05)), child: Icon(PhosphorIcons.shieldCheckFill, size: 28, color: theme.primaryColor)),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Account Credentials', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)), Text('Manage security & password', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12))])),
                    IconButton(icon: Icon(PhosphorIcons.pencilSimple, color: Colors.white), onPressed: _showPasswordModal)
                  ],
                ),
                const SizedBox(height: 16),
                Container(height: 1, color: Colors.white.withOpacity(0.05)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [Icon(PhosphorIcons.fingerprint, color: theme.colorScheme.onSurfaceVariant, size: 20), const SizedBox(width: 8), Text('Biometric Quick-Lock', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13))]),
                    Switch(value: _quickLockEnabled, activeColor: theme.primaryColor, onChanged: (val) => setState(() => _quickLockEnabled = val)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Execution Wallet Card
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [Icon(PhosphorIcons.walletFill, color: theme.primaryColor, size: 22), const SizedBox(width: 8), const Text('Execution Wallet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))]),
                const SizedBox(height: 20),
                if (_hasWallet) ...[
                  Text('PUBLIC ADDRESS', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: Row(children: [Expanded(child: Text(_publicAddress ?? '', style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.white))), Icon(PhosphorIcons.checkCircleFill, color: Colors.greenAccent, size: 18)])),
                ] else ...[
                  Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.amber.withOpacity(0.3))), child: Row(children: [Icon(PhosphorIcons.warningCircleFill, color: Colors.amber, size: 20), const SizedBox(width: 8), const Expanded(child: Text('No wallet connected. Live trading disabled.', style: TextStyle(color: Colors.amber, fontSize: 12)))])),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(onPressed: _showPrivateKeyModal, icon: Icon(PhosphorIcons.key, color: Colors.white), label: Text(_hasWallet ? 'Update Key' : 'Connect Wallet', style: const TextStyle(color: Colors.white)), style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.white.withOpacity(0.2)), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Copy Trading Strategies Section
          Text('COPY TRADING CONFIG', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          if (_strategies.isEmpty)
            GlassCard(child: Center(child: Text('No tracked wallets found.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant))))
          else
            ..._strategies.map((strat) {
              final assign = strat['assignment'] ?? {};
              final isEnabled = assign['enabled'] == true;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassCard(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: isEnabled ? Colors.greenAccent.withOpacity(0.1) : Colors.white.withOpacity(0.05), shape: BoxShape.circle),
                      child: Icon(PhosphorIcons.robotFill, color: isEnabled ? Colors.greenAccent : theme.colorScheme.onSurfaceVariant),
                    ),
                    title: Text(strat['label'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    subtitle: Text(
                      isEnabled ? '\$${assign['trade_usd_amount']} | +${assign['tp_percent']}% / -${assign['sl_percent']}%' : 'Unassigned or paused',
                      style: TextStyle(fontSize: 12, color: isEnabled ? Colors.greenAccent : theme.colorScheme.onSurfaceVariant),
                    ),
                    trailing: Icon(PhosphorIcons.caretRight, color: Colors.white.withOpacity(0.5)),
                    onTap: () => _showStrategyModal(strat), // <--- WIRED HERE
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}
