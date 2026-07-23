import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';

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
          // Custom Pill Navigation for Admin Sub-Sections
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 48,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(colors: [theme.primaryColor, const Color(0xFFE024CE)]),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5),
              tabs: const [
                Tab(text: 'Tracked Wallets'),
                Tab(text: 'Bot Engine'),
                Tab(text: 'Team Quotas'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Expanded(
            child: TabBarView(
              children: [
                TrackedWalletsTab(),
                BotConfigTab(),
                TeamQuotasTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== TAB 1: TRACKED WALLETS ====================
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? '')));
      _walletController.clear();
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
                  decoration: InputDecoration(
                    labelText: 'Whale / Shark Wallet Address',
                    labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.2),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor, foregroundColor: Colors.white),
                    onPressed: _isLoading ? null : _addWallet,
                    child: const Text('Deploy Tracker', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('ACTIVE TRACKERS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
          const SizedBox(height: 12),
          if (_isLoading && _wallets.isEmpty) 
            const Center(child: CircularProgressIndicator())
          else if (_wallets.isEmpty) 
            Text('No wallets tracked yet.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant))
          else 
            ..._wallets.map((w) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Text(w['address'] ?? '', style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12)),
              ),
            )).toList()
        ],
      ),
    );
  }
}

// ==================== TAB 2: BOT ENGINE CONFIG ====================
class BotConfigTab extends StatefulWidget {
  const BotConfigTab({super.key});
  @override State<BotConfigTab> createState() => _BotConfigTabState();
}

class _BotConfigTabState extends State<BotConfigTab> {
  bool _paperMode = false;
  bool _telegramAlerts = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(PhosphorIcons.flaskFill, color: _paperMode ? Colors.amber : Colors.greenAccent),
                      const SizedBox(width: 8),
                      Text(_paperMode ? 'Paper Simulation' : 'LIVE Mode', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Switch(
                    value: _paperMode,
                    activeColor: Colors.amber,
                    onChanged: (v) => setState(() => _paperMode = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(PhosphorIcons.telegramLogoFill, color: theme.primaryColor),
                      const SizedBox(width: 8),
                      const Text('Telegram Alerts', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Switch(
                    value: _telegramAlerts,
                    activeColor: theme.primaryColor,
                    onChanged: (v) => setState(() => _telegramAlerts = v),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ==================== TAB 3: TEAM QUOTAS & PERMISSIONS ====================
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
    if (mounted) {
      setState(() {
        _users = res['data']?['users'] ?? [];
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleManualTrade(int userId, bool allow) async {
    final res = await context.read<ApiService>().postEndpoint('admin_users.php?action=toggle_manual', {
      'user_id': userId,
      'allow_manual_trade': allow ? 1 : 0
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['message'] ?? 'Permission updated'),
        backgroundColor: res['status'] == 'success' ? Colors.green : Colors.red,
      ));
      _fetchUsers();
    }
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
          else if (_users.isEmpty) 
            Center(child: Text('No team members found.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)))
          else 
            ..._users.map((u) {
              final bool canManual = u['allow_manual_trade'] == 1 || u['allow_manual_trade'] == true;
              final bool isActive = u['is_active'] == 1 || u['is_active'] == true;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(u['username'] ?? 'User', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              Text('Role: ${u['role']}', style: TextStyle(color: theme.primaryColor, fontSize: 12)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: (isActive ? Colors.greenAccent : Colors.redAccent).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: Text(isActive ? 'ACTIVE' : 'PAUSED', style: TextStyle(color: isActive ? Colors.greenAccent : Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(height: 1, color: Colors.white.withOpacity(0.05)),
                      const SizedBox(height: 12),
                      
                      // Manual Snipe Permission Toggle Switch
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(PhosphorIcons.rocketLaunch, size: 18, color: canManual ? theme.primaryColor : theme.colorScheme.onSurfaceVariant),
                              const SizedBox(width: 8),
                              Text('Allow Manual Snipe', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13)),
                            ],
                          ),
                          Switch(
                            value: canManual,
                            activeColor: theme.primaryColor,
                            onChanged: (val) => _toggleManualTrade(u['id'], val),
                          ),
                        ],
                      ),
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
