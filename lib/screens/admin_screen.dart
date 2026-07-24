import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/bot_engine_tab.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 48,
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.05))),
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: LinearGradient(colors: [theme.primaryColor, const Color(0xFFE024CE)])),
              labelColor: Colors.white,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5),
              tabs: const [Tab(text: 'Team Quotas'), Tab(text: 'Bot Engine'), Tab(text: 'Tracked Wallets')],
            ),
          ),
          const SizedBox(height: 12),
          const Expanded(child: TabBarView(children: [TeamQuotasTab(), BotEngineTab(), TrackedWalletsTab()])),
        ],
      ),
    );
  }
}

// ==================== TAB 1: TEAM QUOTAS ====================
class TeamQuotasTab extends StatefulWidget {
  const TeamQuotasTab({super.key});
  @override State<TeamQuotasTab> createState() => _TeamQuotasTabState();
}

class _TeamQuotasTabState extends State<TeamQuotasTab> {
  List<dynamic> _users = [];
  bool _isLoading = false;

  @override void initState() { super.initState(); _fetchUsers(); }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    final res = await context.read<ApiService>().getEndpoint('admin_users.php?action=fetch');
    if (mounted) setState(() { _users = res['data']?['users'] ?? []; _isLoading = false; });
  }

  Future<void> _toggleFlag(String action, int userId, bool allow) async {
    final res = await context.read<ApiService>().postEndpoint('admin_users.php?action=$action', {
      'user_id': userId, 
      action == 'toggle_manual' ? 'allow_manual_trade' : 'allow_telegram_alerts': allow ? 1 : 0
    });
    if (mounted) _fetchUsers();
  }

  Future<void> _showEditQuotasModal(dynamic u) async {
    final dailyCtrl = TextEditingController(text: u['quotas']?['daily']?.toString() ?? '');
    final monthlyCtrl = TextEditingController(text: u['quotas']?['monthly']?.toString() ?? '');
    final yearlyCtrl = TextEditingController(text: u['quotas']?['yearly']?.toString() ?? '');
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: const Color(0xFF13131A),
          title: Row(children: [Icon(PhosphorIcons.ticketFill, color: Theme.of(context).primaryColor), const SizedBox(width: 8), const Text('Copy Trade Quotas', style: TextStyle(color: Colors.white, fontSize: 16))]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Set maximum trade count limits (leave empty for unlimited):', style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 16),
              TextField(controller: dailyCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: 'Daily Max Trades', labelStyle: const TextStyle(color: Colors.white54), filled: true, fillColor: Colors.black26, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
              const SizedBox(height: 12),
              TextField(controller: monthlyCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: 'Monthly Max Trades', labelStyle: const TextStyle(color: Colors.white54), filled: true, fillColor: Colors.black26, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
              const SizedBox(height: 12),
              TextField(controller: yearlyCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: 'Yearly Max Trades', labelStyle: const TextStyle(color: Colors.white54), filled: true, fillColor: Colors.black26, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
              onPressed: isSaving ? null : () async {
                setStateDialog(() => isSaving = true);
                final res = await this.context.read<ApiService>().postEndpoint('admin_users.php?action=set_quota', {
                  'user_id': u['id'], 
                  'max_trades_daily': dailyCtrl.text.trim(), 
                  'max_trades_monthly': monthlyCtrl.text.trim(),
                  'max_trades_yearly': yearlyCtrl.text.trim()
                });
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Quotas saved'), backgroundColor: res['status'] == 'success' ? Colors.green : Colors.red));
                  _fetchUsers();
                }
              },
              child: isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white)) : const Text('Save Quotas', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: _fetchUsers,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_isLoading && _users.isEmpty) 
            const Center(child: CircularProgressIndicator())
          else 
            ..._users.map((u) {
              final dailyQuota = u['quotas']?['daily'] != null ? '${u['quotas']['daily']}/day' : '∞/day';
              final monthlyQuota = u['quotas']?['monthly'] != null ? '${u['quotas']['monthly']}/mo' : '∞/mo';
              final yearlyQuota = u['quotas']?['yearly'] != null ? '${u['quotas']['yearly']}/yr' : '∞/yr';

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(u['username'] ?? 'User', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)), 
                            Text('Role: ${u['role']}', style: TextStyle(color: theme.primaryColor, fontSize: 12))
                          ]),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.white10, foregroundColor: Colors.white),
                            onPressed: () => _showEditQuotasModal(u),
                            icon: const Icon(PhosphorIcons.ticket, size: 14),
                            label: const Text('Quotas', style: TextStyle(fontSize: 11)),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text('Limits: $dailyQuota | $monthlyQuota | $yearlyQuota', style: const TextStyle(color: Colors.white54, fontSize: 11, fontFamily: 'monospace')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(height: 1, color: Colors.white.withOpacity(0.05)),
                      const SizedBox(height: 12),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: [Icon(PhosphorIcons.rocketLaunch, size: 18, color: theme.primaryColor), const SizedBox(width: 8), const Text('Allow Manual Snipe', style: TextStyle(color: Colors.white, fontSize: 13))]), Switch(value: u['allow_manual_trade'] == 1, activeColor: theme.primaryColor, onChanged: (val) => _toggleFlag('toggle_manual', u['id'], val))]),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: const [Icon(PhosphorIcons.telegramLogo, size: 18, color: Colors.blueAccent), SizedBox(width: 8), Text('Allow Telegram Alerts', style: TextStyle(color: Colors.white, fontSize: 13))]), Switch(value: u['allow_telegram_alerts'] == 1, activeColor: Colors.blueAccent, onChanged: (val) => _toggleFlag('toggle_telegram', u['id'], val))]),
                    ],
                  ),
                ),
              );
            }).toList()
        ],
      ),
    );
  }
}

// ==================== TAB 3: TRACKED WALLETS ====================
class TrackedWalletsTab extends StatefulWidget {
  const TrackedWalletsTab({super.key});
  @override State<TrackedWalletsTab> createState() => _TrackedWalletsTabState();
}

class _TrackedWalletsTabState extends State<TrackedWalletsTab> {
  final _walletController = TextEditingController();
  List<dynamic> _wallets = [];
  bool _isLoading = false;

  @override void initState() { super.initState(); _fetchWallets(); }

  Future<void> _fetchWallets() async {
    setState(() => _isLoading = true);
    final res = await context.read<ApiService>().getEndpoint('admin_wallets.php?action=fetch');
    if (mounted) setState(() { _wallets = res['data']?['wallets'] ?? []; _isLoading = false; });
  }

  Future<void> _addWallet() async {
    if (_walletController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    final res = await context.read<ApiService>().postEndpoint('admin_wallets.php?action=add', {
      'address': _walletController.text.trim(),
      'label': 'Whale Tracker'
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? ''), backgroundColor: res['status'] == 'success' ? Colors.green : Colors.red));
      _walletController.clear();
      _fetchWallets();
    }
  }

  Future<void> _syncWebhook() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Syncing Helius Webhook...'), backgroundColor: Colors.amber));
    final res = await context.read<ApiService>().getEndpoint('admin_wallets.php?action=sync_webhook');
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? ''), backgroundColor: res['status'] == 'success' ? Colors.green : Colors.red));
  }

  Future<void> _toggleCopy(int id, bool currentEnabled) async {
    final res = await context.read<ApiService>().postEndpoint('admin_wallets.php?action=toggle_copy', {'id': id, 'enabled': currentEnabled ? 0 : 1});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? ''), backgroundColor: res['status'] == 'success' ? Colors.green : Colors.red));
      _fetchWallets();
    }
  }

  Future<void> _showEditModal(dynamic w) async {
    final lblCtrl = TextEditingController(text: w['label']);
    final addrCtrl = TextEditingController(text: w['address']);
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: const Color(0xFF13131A),
          title: Row(children: [Icon(PhosphorIcons.pencilSimpleFill, color: Theme.of(context).primaryColor), const SizedBox(width: 8), const Text('Edit Tracker', style: TextStyle(color: Colors.white, fontSize: 16))]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: lblCtrl, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: 'Label', filled: true, fillColor: Colors.black26, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
              const SizedBox(height: 12),
              TextField(controller: addrCtrl, style: const TextStyle(color: Colors.white, fontSize: 12), decoration: InputDecoration(labelText: 'Address', filled: true, fillColor: Colors.black26, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
              onPressed: isSaving ? null : () async {
                setStateDialog(() => isSaving = true);
                final res = await this.context.read<ApiService>().postEndpoint('admin_wallets.php?action=edit', {'id': w['id'], 'label': lblCtrl.text.trim(), 'address': addrCtrl.text.trim()});
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text(res['message'] ?? ''), backgroundColor: res['status'] == 'success' ? Colors.green : Colors.red));
                  _fetchWallets();
                }
              },
              child: isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white)) : const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteModal(int id) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF13131A),
        title: const Row(children: [Icon(PhosphorIcons.warningCircleFill, color: Colors.redAccent), SizedBox(width: 8), Text('Remove Tracker?', style: TextStyle(color: Colors.white, fontSize: 16))]),
        content: const Text('Are you sure you want to stop tracking this wallet? You must sync the webhook afterward.', style: TextStyle(color: Colors.white70, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove', style: TextStyle(color: Colors.white))),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final res = await context.read<ApiService>().postEndpoint('admin_wallets.php?action=delete', {'id': id});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? ''), backgroundColor: res['status'] == 'success' ? Colors.green : Colors.red));
      _fetchWallets();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: _fetchWallets,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Track Target Address', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Icon(PhosphorIcons.userPlusFill, color: theme.primaryColor),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _walletController,
                  style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12),
                  decoration: InputDecoration(labelText: 'Whale / Shark Wallet Address', labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant), filled: true, fillColor: Colors.black.withOpacity(0.2), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                ),
                const SizedBox(height: 16),
                SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)), onPressed: _isLoading ? null : _addWallet, child: const Text('Deploy Tracker', style: TextStyle(fontWeight: FontWeight.bold)))),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ACTIVE TRACKERS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
              OutlinedButton.icon(
                onPressed: _syncWebhook,
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.amber), foregroundColor: Colors.amber, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                icon: const Icon(PhosphorIcons.arrowsClockwiseBold, size: 16),
                label: const Text('Sync Webhook', style: TextStyle(fontSize: 11)),
              )
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoading && _wallets.isEmpty) 
            const Center(child: CircularProgressIndicator())
          else if (_wallets.isEmpty) 
            Text('No wallets tracked yet.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant))
          else 
            ..._wallets.map((w) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(w['label'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                        Row(
                          children: [
                            IconButton(icon: const Icon(PhosphorIcons.pencilSimple, color: Colors.white54, size: 18), onPressed: () => _showEditModal(w), constraints: const BoxConstraints(), padding: const EdgeInsets.symmetric(horizontal: 4)),
                            IconButton(icon: const Icon(PhosphorIcons.trash, color: Colors.redAccent, size: 18), onPressed: () => _showDeleteModal(w['id']), constraints: const BoxConstraints(), padding: const EdgeInsets.symmetric(horizontal: 4)),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(w['address'] ?? '', style: const TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 11)),
                    const SizedBox(height: 12),
                    Container(height: 1, color: Colors.white10),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Copy Trading', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                        Switch(
                          value: w['copy_enabled'] == true,
                          activeColor: Colors.greenAccent,
                          onChanged: (_) => _toggleCopy(w['id'], w['copy_enabled']),
                        )
                      ],
                    )
                  ],
                ),
              ),
            )).toList()
        ],
      ),
    );
  }
}
