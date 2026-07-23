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
                AdminWalletsTab(),
                AdminSettingsTab(),
                AdminUsersTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== TAB 1: MANUAL SNIPE ====================
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

// ==================== TAB 2: TRACKED WALLETS ====================
class AdminWalletsTab extends StatefulWidget {
  const AdminWalletsTab({super.key});

  @override
  State<AdminWalletsTab> createState() => _AdminWalletsTabState();
}

class _AdminWalletsTabState extends State<AdminWalletsTab> {
  bool _isLoading = true;
  List<dynamic> _wallets = [];

  @override
  void initState() {
    super.initState();
    _fetchWallets();
  }

  Future<void> _fetchWallets() async {
    setState(() => _isLoading = true);
    final api = context.read<ApiService>();
    final res = await api.getEndpoint('admin_wallets.php?action=fetch');
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res['status'] == 'success') {
          _wallets = res['data']['wallets'] ?? [];
        }
      });
    }
  }

  Future<void> _syncWebhook() async {
    final api = context.read<ApiService>();
    final res = await api.getEndpoint('admin_wallets.php?action=sync_webhook');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['message'] ?? 'Synced'),
        backgroundColor: res['status'] == 'success' ? Colors.green : Colors.red,
      ));
    }
  }

  void _showAddWalletModal() {
    final labelController = TextEditingController();
    final addressController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(PhosphorIcons.userPlusFill, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text('Add Shark Wallet', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: labelController,
              decoration: InputDecoration(
                labelText: 'Wallet Label',
                hintText: 'e.g. Whale #1 / Ansem',
                prefixIcon: Icon(PhosphorIcons.tag),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressController,
              decoration: InputDecoration(
                labelText: 'Solana Address',
                hintText: 'Full public key',
                prefixIcon: Icon(PhosphorIcons.qrCode),
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
                  final api = context.read<ApiService>();
                  final res = await api.postEndpoint('admin_wallets.php?action=add', {
                    'label': labelController.text.trim(),
                    'address': addressController.text.trim(),
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(res['message'] ?? ''),
                      backgroundColor: res['status'] == 'success' ? Colors.green : Colors.red,
                    ));
                    _fetchWallets();
                  }
                },
                child: const Text('Track Wallet', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _fetchWallets,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: _syncWebhook,
                icon: Icon(PhosphorIcons.arrowsClockwiseBold, size: 16),
                label: const Text('Sync Webhook'),
              ),
              ElevatedButton.icon(
                onPressed: _showAddWalletModal,
                style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor, foregroundColor: Colors.white),
                icon: Icon(PhosphorIcons.plusBold, size: 16),
                label: const Text('Add Wallet'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_wallets.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: Text('No tracked wallets found.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
            )
          else
            ..._wallets.map((w) {
              final isCopyEnabled = w['copy_enabled'] == true;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.primaryColor.withOpacity(0.1),
                      child: Icon(PhosphorIcons.userCircleFill, color: theme.primaryColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(w['label'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 2),
                          Text(
                            '${(w['address'] as String).substring(0, 10)}...${(w['address'] as String).substring((w['address'] as String).length - 6)}',
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isCopyEnabled,
                      activeColor: Colors.green,
                      onChanged: (val) async {
                        final api = context.read<ApiService>();
                        await api.postEndpoint('admin_wallets.php?action=toggle_copy', {
                          'id': w['id'],
                          'enabled': val ? 1 : 0
                        });
                        _fetchWallets();
                      },
                    ),
                    IconButton(
                      icon: Icon(PhosphorIcons.trash, color: Colors.red.shade400, size: 20),
                      onPressed: () async {
                        final api = context.read<ApiService>();
                        await api.postEndpoint('admin_wallets.php?action=delete', {'id': w['id']});
                        _fetchWallets();
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}

// ==================== TAB 3: GLOBAL BOT CONFIG ====================
class AdminSettingsTab extends StatefulWidget {
  const AdminSettingsTab({super.key});

  @override
  State<AdminSettingsTab> createState() => _AdminSettingsTabState();
}

class _AdminSettingsTabState extends State<AdminSettingsTab> {
  bool _isLoading = true;
  final _pollController = TextEditingController();
  final _liquidityController = TextEditingController();
  final _alertsController = TextEditingController();
  final _virtualUsdController = TextEditingController();
  final _tpController = TextEditingController();
  final _slController = TextEditingController();
  final _stablecoinsController = TextEditingController();

  bool _telegramEnabled = true;
  bool _paperEnabled = true;
  bool _liveEnabled = false;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    setState(() => _isLoading = true);
    final api = context.read<ApiService>();
    final res = await api.getEndpoint('admin_settings.php?action=fetch');

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res['status'] == 'success') {
          final d = res['data'];
          _pollController.text = d['poll_interval_minutes'].toString();
          _liquidityController.text = d['liquidity_floor'].toString();
          _alertsController.text = d['max_alerts_per_cycle'].toString();
          _virtualUsdController.text = d['copy_trade_virtual_usd'].toString();
          _tpController.text = d['default_tp_percent'].toString();
          _slController.text = d['default_sl_percent'].toString();
          _stablecoinsController.text = d['stablecoin_mints'] ?? '';
          
          _telegramEnabled = d['telegram_enabled'];
          _paperEnabled = d['paper_trading_enabled'];
          _liveEnabled = d['live_trading_enabled'];
        }
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    final api = context.read<ApiService>();
    final res = await api.postEndpoint('admin_settings.php?action=update', {
      'poll_interval_minutes': _pollController.text,
      'liquidity_floor': _liquidityController.text,
      'max_alerts_per_cycle': _alertsController.text,
      'telegram_enabled': _telegramEnabled ? 1 : 0,
      'paper_trading_enabled': _paperEnabled ? 1 : 0,
      'live_trading_enabled': _liveEnabled ? 1 : 0,
      'copy_trade_virtual_usd': _virtualUsdController.text,
      'default_tp_percent': _tpController.text,
      'default_sl_percent': _slController.text,
      'stablecoin_mints': _stablecoinsController.text,
    });

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['message'] ?? 'Settings saved'),
        backgroundColor: res['status'] == 'success' ? Colors.green : Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Engine & Scanning Settings', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _pollController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Poll Interval (Minutes)', prefixIcon: Icon(PhosphorIcons.timer)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _liquidityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Liquidity Floor (\$)', prefixIcon: Icon(PhosphorIcons.currencyDollar)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _alertsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Max Alerts/Cycle', prefixIcon: Icon(PhosphorIcons.bellRinging)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Text('Trading Engines', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Telegram Alerts'),
            value: _telegramEnabled,
            activeColor: theme.primaryColor,
            onChanged: (v) => setState(() => _telegramEnabled = v),
          ),
          SwitchListTile(
            title: const Text('Simulated Paper Trading'),
            value: _paperEnabled,
            activeColor: Colors.amber,
            onChanged: (v) => setState(() => _paperEnabled = v),
          ),
          SwitchListTile(
            title: const Text('REAL Live Trading'),
            subtitle: const Text('Uses actual Solana funds', style: TextStyle(color: Colors.red, fontSize: 11)),
            value: _liveEnabled,
            activeColor: Colors.red,
            onChanged: (v) => setState(() => _liveEnabled = v),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tpController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Default TP %', prefixIcon: Icon(PhosphorIcons.trendUp, color: Colors.green)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _slController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Default SL %', prefixIcon: Icon(PhosphorIcons.trendDown, color: Colors.red)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Text('Stablecoin Whitelist', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _stablecoinsController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Comma-separated mint addresses'),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: Icon(PhosphorIcons.floppyDiskFill),
              label: const Text('Save Configuration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ==================== TAB 4: TEAM QUOTAS ====================
class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  bool _isLoading = true;
  List<dynamic> _users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    final api = context.read<ApiService>();
    final res = await api.getEndpoint('admin_users.php?action=fetch');

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res['status'] == 'success') {
          _users = res['data']['users'] ?? [];
        }
      });
    }
  }

  void _showCreateUserModal() {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(PhosphorIcons.userPlusFill, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text('Create Team Member', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(PhosphorIcons.user)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Temp Password', prefixIcon: Icon(PhosphorIcons.lockKey)),
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
                  final api = context.read<ApiService>();
                  final res = await api.postEndpoint('admin_users.php?action=create', {
                    'username': usernameController.text.trim(),
                    'password': passwordController.text,
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(res['message'] ?? ''),
                      backgroundColor: res['status'] == 'success' ? Colors.green : Colors.red,
                    ));
                    _fetchUsers();
                  }
                },
                child: const Text('Create User', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showQuotaModal(Map<String, dynamic> user) {
    final q = user['quotas'] ?? {};
    final dailyController = TextEditingController(text: q['daily']?.toString() ?? '');
    final monthlyController = TextEditingController(text: q['monthly']?.toString() ?? '');
    final yearlyController = TextEditingController(text: q['yearly']?.toString() ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Trade Quotas: ${user['username']}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: dailyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Daily Max Trades', prefixIcon: Icon(PhosphorIcons.calendarBlank)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: monthlyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Monthly Max Trades', prefixIcon: Icon(PhosphorIcons.calendar)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: yearlyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Yearly Max Trades', prefixIcon: Icon(PhosphorIcons.calendarCheck)),
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
                  final api = context.read<ApiService>();
                  final res = await api.postEndpoint('admin_users.php?action=set_quota', {
                    'user_id': user['id'],
                    'max_trades_daily': dailyController.text,
                    'max_trades_monthly': monthlyController.text,
                    'max_trades_yearly': yearlyController.text,
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(res['message'] ?? ''),
                      backgroundColor: res['status'] == 'success' ? Colors.green : Colors.red,
                    ));
                    _fetchUsers();
                  }
                },
                child: const Text('Save Quotas', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _fetchUsers,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _showCreateUserModal,
              style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor, foregroundColor: Colors.white),
              icon: Icon(PhosphorIcons.userPlusBold, size: 16),
              label: const Text('Create Member'),
            ),
          ),
          const SizedBox(height: 16),
          ..._users.map((u) {
            final isActive = u['is_active'] == true;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: theme.primaryColor.withOpacity(0.1),
                        child: Icon(PhosphorIcons.userFill, color: theme.primaryColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(u['username'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('PnL: \$${(u['total_pnl'] as num).toStringAsFixed(2)} | Open: ${u['open_trades']}', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      Switch(
                        value: isActive,
                        activeColor: Colors.green,
                        onChanged: (val) async {
                          final api = context.read<ApiService>();
                          await api.postEndpoint('admin_users.php?action=toggle_active', {
                            'id': u['id'],
                            'active': val ? 1 : 0
                          });
                          _fetchUsers();
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Quotas: ${u['quotas']['daily'] ?? '∞'}D / ${u['quotas']['monthly'] ?? '∞'}M / ${u['quotas']['yearly'] ?? '∞'}Y',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        onPressed: () => _showQuotaModal(u),
                        icon: Icon(PhosphorIcons.pencilSimple, size: 14),
                        label: const Text('Edit Limits', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
