import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../services/api_service.dart';
import '../widgets/balance_card.dart';
import '../widgets/master_strategy_switch.dart';
import 'positions_screen.dart';
import 'admin_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final apiService = context.watch<ApiService>();
    final isAdmin = apiService.role == 'admin';
    final theme = Theme.of(context);

    final List<Widget> pages = [
      _buildHomeTab(theme, apiService.role),
      const PositionsScreen(),
      if (isAdmin) const AdminScreen(),
      const Center(child: Text('Settings')),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'Admin Portal' : 'User Dashboard', style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.signOut()),
            onPressed: () => apiService.logout(),
          ),
        ],
      ),
      body: SafeArea(child: pages[_currentIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        indicatorColor: theme.primaryColor.withOpacity(0.2),
        destinations: [
          NavigationDestination(
            icon: Icon(PhosphorIcons.squaresFour()),
            selectedIcon: Icon(PhosphorIcons.squaresFour(PhosphorIconsStyle.fill), color: theme.primaryColor),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(PhosphorIcons.chartLineUp()),
            selectedIcon: Icon(PhosphorIcons.chartLineUp(PhosphorIconsStyle.fill), color: theme.primaryColor),
            label: 'Positions',
          ),
          if (isAdmin)
            NavigationDestination(
              icon: Icon(PhosphorIcons.shieldCheck()),
              selectedIcon: Icon(PhosphorIcons.shieldCheck(PhosphorIconsStyle.fill), color: theme.primaryColor),
              label: 'Admin',
            ),
          NavigationDestination(
            icon: Icon(PhosphorIcons.gear()),
            selectedIcon: Icon(PhosphorIcons.gear(PhosphorIconsStyle.fill), color: theme.primaryColor),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab(ThemeData theme, String? role) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {}); 
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(PhosphorIcons.handWaving(PhosphorIconsStyle.fill), color: theme.primaryColor),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome back,', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    Text(
                      role == 'admin' ? 'System Administrator' : 'Team Member',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            const BalanceCard(),
            const SizedBox(height: 24),
            const MasterStrategySwitch(),
          ],
        ),
      ),
    );
  }
}
