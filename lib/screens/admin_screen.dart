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

// ... Keep existing TrackedWalletsTab ...
class TrackedWalletsTab extends StatefulWidget {
  const TrackedWalletsTab({super.key});
  @override State<TrackedWalletsTab> createState() => _TrackedWalletsTabState();
}
class _TrackedWalletsTabState extends State<TrackedWalletsTab> {
  @override Widget build(BuildContext context) => const Center(child: Text('Wallet tracking here', style: TextStyle(color: Colors.white)));
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
    final res = await context.read<ApiService>().postEndpoint('admin_users.php?action=$action', {'user_id': userId, action == 'toggle_manual' ? 'allow_manual_trade' : 'allow_telegram_alerts': allow ? 1 : 0});
    if (mounted) _fetchUsers();
  }

  Future<void> _showEditLimitsModal(dynamic u) async {
    final maxTrCtrl = TextEditingController(text: u['quotas']['max_per_trade_usd']?.toString() ?? '');
    final dCapCtrl = TextEditingController(text: u['quotas']['daily_spend_cap']?.toString() ?? '');
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: const Color(0xFF13131A),
          title: Row(children: [Icon(PhosphorIcons.ticketFill, color: Theme.of(context).primaryColor), const SizedBox(width: 8), const Text('Trade Limits', style: TextStyle(color: Colors.white, fontSize: 16))]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: maxTrCtrl, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: 'Max Per Trade (\$)', filled: true, fillColor: Colors.black26, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
              const SizedBox(height: 12),
              TextField(controller: dCapCtrl, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: 'Daily Spend Cap (\$)', filled: true, fillColor: Colors.black26, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
              onPressed: isSaving ? null : () async {
                setStateDialog(() => isSaving = true);
                final res = await this.context.read<ApiService>().postEndpoint('admin_users.php?action=set_quota', {'user_id': u['id'], 'user_max_per_trade_usd': maxTrCtrl.text, 'user_daily_spend_cap': dCapCtrl.text});
                if (mounted) {
                  Navigator.pop(ctx);
                  _fetchUsers();
                }
              },
              child: isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white)) : const Text('Save', style: TextStyle(color: Colors.white)),
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
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(u['username'] ?? 'User', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)), Text('Role: ${u['role']}', style: TextStyle(color: theme.primaryColor, fontSize: 12))]),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.white10, foregroundColor: Colors.white),
                            onPressed: () => _showEditLimitsModal(u),
                            icon: const Icon(PhosphorIcons.ticket, size: 14),
                            label: const Text('Limits', style: TextStyle(fontSize: 11)),
                          )
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
