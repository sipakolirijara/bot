import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../services/api_service.dart';
import '../widgets/animated_background.dart';
import '../widgets/glass_card.dart';
import 'positions_screen.dart';
import 'admin_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  bool _isLoading = true;
  String _solBalance = "0.00000";
  String _usdValue = "0.00";
  Map<String, dynamic> _stats = {'open_count': 0, 'total_pnl': 0.0, 'total_trades': 0};
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchDashboardData(silent: true));
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchDashboardData({bool silent = false}) async {
    if (!silent && mounted) setState(() => _isLoading = true);
    final api = context.read<ApiService>();
    
    final responses = await Future.wait([
      api.getEndpoint('balance.php'),
      api.getEndpoint('positions.php?action=fetch')
    ]);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (responses[0]['status'] == 'success') {
          _solBalance = responses[0]['data']['sol_balance'];
          _usdValue = responses[0]['data']['usd_value'];
        }
        if (responses[1]['status'] == 'success') {
          _stats = responses[1]['stats'] ?? _stats;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final apiService = context.watch<ApiService>();
    final isAdmin = apiService.role == 'admin';
    final theme = Theme.of(context);

    final List<Widget> pages = [
      _buildPremiumHome(theme),
      const PositionsScreen(),
      if (isAdmin) const AdminScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedCryptoBackground(
        child: SafeArea(child: pages[_currentIndex]),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.8),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
        ),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) => setState(() => _currentIndex = index),
          indicatorColor: theme.primaryColor.withOpacity(0.3),
          destinations: [
            NavigationDestination(icon: Icon(PhosphorIcons.squaresFour), selectedIcon: Icon(PhosphorIcons.squaresFourFill, color: theme.primaryColor), label: 'Terminal'),
            NavigationDestination(icon: Icon(PhosphorIcons.chartLineUp), selectedIcon: Icon(PhosphorIcons.chartLineUpFill, color: theme.primaryColor), label: 'Ledger'),
            if (isAdmin) NavigationDestination(icon: Icon(PhosphorIcons.shieldCheck), selectedIcon: Icon(PhosphorIcons.shieldCheckFill, color: theme.primaryColor), label: 'Admin'),
            NavigationDestination(icon: Icon(PhosphorIcons.userCircle), selectedIcon: Icon(PhosphorIcons.userCircleFill, color: theme.primaryColor), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumHome(ThemeData theme) {
    final double pnl = _stats['total_pnl'] != null ? (_stats['total_pnl'] as num).toDouble() : 0.0;
    final bool isProfit = pnl >= 0;

    return RefreshIndicator(
      onRefresh: () => _fetchDashboardData(),
      color: theme.primaryColor,
      backgroundColor: theme.colorScheme.surface,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [theme.primaryColor, const Color(0xFFE024CE)]),
                      ),
                      child: const CircleAvatar(
                        radius: 22,
                        backgroundColor: Color(0xFF13131A),
                        child: Icon(PhosphorIcons.userFill, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome back,', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                        Text('Osama Elguduwis', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(PhosphorIcons.signOut, color: theme.colorScheme.onSurfaceVariant),
                  onPressed: () => context.read<ApiService>().logout(),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Main Portfolio Card
            GlassCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('TOTAL PORTFOLIO VALUE', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
                      if (_isLoading) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('\$$_usdValue', style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 40)),
                  const SizedBox(height: 4),
                  Text('$_solBalance SOL', style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 24),
                  Container(height: 1, color: Colors.white.withOpacity(0.1)),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('NET PNL', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11, letterSpacing: 1)),
                            const SizedBox(height: 4),
                            Text(
                              '${isProfit ? '+' : ''}\$${pnl.toStringAsFixed(2)}',
                              style: TextStyle(color: isProfit ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 40, color: Colors.white.withOpacity(0.1)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('OPEN TRADES', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11, letterSpacing: 1)),
                            const SizedBox(height: 4),
                            Text('${_stats['open_count'] ?? 0}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Activity Grid
            Row(
              children: [
                Expanded(
                  child: GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(PhosphorIcons.crosshair, color: theme.primaryColor),
                        const SizedBox(height: 16),
                        Text('Total Snipes', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text('${_stats['total_trades'] ?? 0}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(PhosphorIcons.chartPolar, color: const Color(0xFFE024CE)),
                        const SizedBox(height: 16),
                        Text('Win Rate', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                        const SizedBox(height: 4),
                        const Text('Calculating', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
