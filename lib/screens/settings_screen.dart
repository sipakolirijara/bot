import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../services/api_service.dart';

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
        
        final walletRes = responses[0];
        if (walletRes['status'] == 'success') {
          _hasWallet = walletRes['data']['has_wallet'];
          _publicAddress = walletRes['data']['public_address'];
        }

        final stratRes = responses[1];
        if (stratRes['status'] == 'success') {
          _strategies = stratRes['data']['strategies'] ?? [];
        }
      });
    }
  }

  void _showPrivateKeyModal() {
    final keyController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(PhosphorIcons.keyFill, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text('Secure Wallet Link', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Your private key is AES-256 encrypted instantly on the backend and never exposed.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: keyController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Solana Private Key',
                prefixIcon: Icon(PhosphorIcons.wallet),
                hintText: 'Base58 string or array format',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  if (keyController.text.trim().isEmpty) return;
                  
                  setState(() => _isLoading = true);
                  final api = context.read<ApiService>();
                  final res = await api.postEndpoint('wallet.php?action=set_key', {
                    'private_key': keyController.text.trim()
                  });
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(res['message'] ?? ''),
                      backgroundColor: res['status'] == 'success' ? Colors.green : Colors.red,
                    ));
                    _fetchData();
                  }
                },
                child: const Text('Encrypt & Save', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showStrategyModal(Map<String, dynamic> strat) {
    final assign = strat['assignment'] ?? {};
    final usdController = TextEditingController(text: assign['trade_usd_amount']?.toString() ?? '');
    final tpController = TextEditingController(text: assign['tp_percent']?.toString() ?? '');
    final slController = TextEditingController(text: assign['sl_percent']?.toString() ?? '');
    final maxController = TextEditingController(text: assign['max_concurrent_trades']?.toString() ?? '');
    bool isEnabled = assign['enabled'] == true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('Setup: ${strat['label']}', 
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Switch(
                      value: isEnabled,
                      activeColor: Colors.green,
                      onChanged: (val) => setModalState(() => isEnabled = val),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: usdController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Trade USD', prefixIcon: Icon(PhosphorIcons.currencyDollar)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: maxController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Max Open', prefixIcon: Icon(PhosphorIcons.hash)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: tpController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'TP %', prefixIcon: Icon(PhosphorIcons.trendUp, color: Colors.green)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: slController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'SL %', prefixIcon: Icon(PhosphorIcons.trendDown, color: Colors.red)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      setState(() => _isLoading = true);
                      final api = context.read<ApiService>();
                      final res = await api.postEndpoint('strategies.php?action=assign_wallet', {
                        'tracked_wallet_id': strat['tracked_wallet_id'],
                        'trade_usd_amount': usdController.text,
                        'tp_percent': tpController.text,
                        'sl_percent': slController.text,
                        'max_concurrent_trades': maxController.text,
                        'enabled': isEnabled ? 1 : 0,
                      });
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(res['message'] ?? ''),
                          backgroundColor: res['status'] == 'success' ? Colors.green : Colors.red,
                        ));
                        _fetchData();
                      }
                    },
                    child: const Text('Save Configuration', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
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
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Wallet Card
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
                      Icon(PhosphorIcons.walletFill, color: theme.primaryColor, size: 24),
                      const SizedBox(width: 8),
                      Text('Execution Wallet', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_hasWallet) ...[
                    Text('Public Address', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _publicAddress ?? '',
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                            ),
                          ),
                          Icon(PhosphorIcons.checkCircleFill, color: Colors.green, size: 18),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          Icon(PhosphorIcons.warningCircleFill, color: Colors.amber, size: 20),
                          const SizedBox(width: 8),
                          const Expanded(child: Text('No wallet connected. Real trading is disabled.', style: TextStyle(color: Colors.amber, fontSize: 13))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showPrivateKeyModal,
                      icon: Icon(PhosphorIcons.key),
                      label: Text(_hasWallet ? 'Update Private Key' : 'Connect Wallet'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Strategies Header
            Text('Copy Trading Configurations', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Assign specific risk rules to tracked shark wallets.', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),

            // Strategy List
            if (_strategies.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                decoration: BoxDecoration(border: Border.all(color: theme.dividerColor.withOpacity(0.2)), borderRadius: BorderRadius.circular(16)),
                child: const Text('No tracked wallets found.'),
              )
            else
              ..._strategies.map((strat) {
                final assign = strat['assignment'] ?? {};
                final isEnabled = assign['enabled'] == true;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isEnabled ? Colors.green.withOpacity(0.3) : theme.dividerColor.withOpacity(0.1)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: CircleAvatar(
                      backgroundColor: isEnabled ? Colors.green.withOpacity(0.1) : theme.colorScheme.surfaceVariant,
                      child: Icon(PhosphorIcons.robotFill, color: isEnabled ? Colors.green : theme.colorScheme.onSurfaceVariant),
                    ),
                    title: Text(strat['label'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      isEnabled 
                          ? '\$${assign['trade_usd_amount']} | +${assign['tp_percent']}% / -${assign['sl_percent']}%'
                          : 'Currently unassigned or paused',
                      style: TextStyle(fontSize: 12, color: isEnabled ? Colors.green : theme.colorScheme.onSurfaceVariant),
                    ),
                    trailing: Icon(PhosphorIcons.caretRight, size: 16),
                    onTap: () => _showStrategyModal(strat),
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }
}
