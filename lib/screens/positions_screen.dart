import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';

class PositionsScreen extends StatefulWidget {
  const PositionsScreen({super.key});

  @override
  State<PositionsScreen> createState() => _PositionsScreenState();
}

class _PositionsScreenState extends State<PositionsScreen> {
  bool _isLoading = true;
  List<dynamic> _openPositions = [];
  List<dynamic> _closedPositions = [];

  @override
  void initState() {
    super.initState();
    _fetchPositions();
  }

  Future<void> _fetchPositions() async {
    setState(() => _isLoading = true);
    final res = await context.read<ApiService>().getEndpoint('positions.php?action=fetch');
    if (mounted) {
      setState(() {
        if (res['status'] == 'success') {
          _openPositions = res['open_positions'] ?? [];
          _closedPositions = res['closed_positions'] ?? [];
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _launchDexScreener(String address) async {
    final url = Uri.parse('https://dexscreener.com/solana/$address');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  // Format UTC MySQL string into Lagos Time (West Africa Time UTC+1) in 12-Hour AM/PM format
  String formatLagosTime(String? utcString) {
    if (utcString == null || utcString.isEmpty) return '-';
    try {
      String formattedStr = utcString.replaceAll(' ', 'T');
      if (!formattedStr.endsWith('Z')) formattedStr += 'Z';
      final utcDateTime = DateTime.parse(formattedStr);
      final lagosDateTime = utcDateTime.add(const Duration(hours: 1)); // WAT = UTC+1
      
      final hour24 = lagosDateTime.hour;
      final hour12 = (hour24 % 12 == 0) ? 12 : hour24 % 12;
      final period = hour24 >= 12 ? 'PM' : 'AM';
      final minute = lagosDateTime.minute.toString().padLeft(2, '0');
      
      const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final month = monthNames[lagosDateTime.month - 1];
      final day = lagosDateTime.day;

      return '$hour12:$minute $period, $month $day';
    } catch (e) {
      return utcString;
    }
  }

  // Calculates exact duration spent inside trade
  String calculateTimeInTrade(String? openedAtStr, [String? closedAtStr]) {
    if (openedAtStr == null || openedAtStr.isEmpty) return '-';
    try {
      String startStr = openedAtStr.replaceAll(' ', 'T');
      if (!startStr.endsWith('Z')) startStr += 'Z';
      final start = DateTime.parse(startStr);

      DateTime end;
      if (closedAtStr != null && closedAtStr.isNotEmpty) {
        String endStr = closedAtStr.replaceAll(' ', 'T');
        if (!endStr.endsWith('Z')) endStr += 'Z';
        end = DateTime.parse(endStr);
      } else {
        end = DateTime.now().toUtc();
      }

      final diff = end.difference(start);
      if (diff.inMinutes < 1) return '< 1m';

      final days = diff.inDays;
      final hours = diff.inHours % 24;
      final minutes = diff.inMinutes % 60;

      List<String> parts = [];
      if (days > 0) parts.add('${days}d');
      if (hours > 0) parts.add('${hours}h');
      if (minutes > 0) parts.add('${minutes}m');

      return parts.join(' ');
    } catch (e) {
      return '-';
    }
  }

  Future<void> _closePosition(int id) async {
    final res = await context.read<ApiService>().postEndpoint('trade.php?action=close_position', {'id': id});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['message'] ?? 'Action complete'),
        backgroundColor: res['status'] == 'success' ? Colors.green : Colors.red,
      ));
      _fetchPositions();
    }
  }

  String _formatAddress(String addr) {
    if (addr.length <= 12) return addr;
    return '${addr.substring(0, 6)}...${addr.substring(addr.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 48,
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.05))),
            child: TabBar(
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: LinearGradient(colors: [theme.primaryColor, const Color(0xFFE024CE)])),
              labelColor: Colors.white,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                Tab(text: 'Open Trades (${_openPositions.length})'),
                Tab(text: 'Closed History (${_closedPositions.length})'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : TabBarView(
                  children: [
                    // OPEN POSITIONS TAB
                    RefreshIndicator(
                      onRefresh: _fetchPositions,
                      child: _openPositions.isEmpty 
                        ? const Center(child: Text('No active open positions.', style: TextStyle(color: Colors.white54)))
                        : ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: _openPositions.length,
                            itemBuilder: (context, index) {
                              final p = _openPositions[index];
                              final pnl = double.tryParse(p['unrealized_pnl']?.toString() ?? '0') ?? 0.0;
                              final isProfit = pnl >= 0;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: GlassCard(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          InkWell(
                                            onTap: () => _launchDexScreener(p['token_address'] ?? ''),
                                            child: Row(
                                              children: [
                                                Text(_formatAddress(p['token_address'] ?? ''), style: const TextStyle(color: Colors.blueAccent, fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 13, decoration: TextDecoration.underline)),
                                                const SizedBox(width: 4),
                                                const Icon(PhosphorIcons.arrowUpRight, color: Colors.blueAccent, size: 14),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            '${isProfit ? '+' : ''}\$${pnl.toStringAsFixed(2)}',
                                            style: TextStyle(color: isProfit ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Opened: ${formatLagosTime(p['opened_at'])}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                          Row(
                                            children: [
                                              const Icon(PhosphorIcons.clock, color: Colors.purpleAccent, size: 12),
                                              const SizedBox(width: 4),
                                              Text(calculateTimeInTrade(p['opened_at']), style: const TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent), foregroundColor: Colors.redAccent),
                                          onPressed: () => _closePosition(p['id']),
                                          icon: const Icon(PhosphorIcons.handPalm, size: 16),
                                          label: const Text('Close Trade Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                    ),

                    // CLOSED POSITIONS TAB
                    RefreshIndicator(
                      onRefresh: _fetchPositions,
                      child: _closedPositions.isEmpty 
                        ? const Center(child: Text('No closed trade history.', style: TextStyle(color: Colors.white54)))
                        : ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: _closedPositions.length,
                            itemBuilder: (context, index) {
                              final p = _closedPositions[index];
                              final pnl = double.tryParse(p['pnl_usd']?.toString() ?? '0') ?? 0.0;
                              final isProfit = pnl >= 0;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: GlassCard(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          InkWell(
                                            onTap: () => _launchDexScreener(p['token_address'] ?? ''),
                                            child: Row(
                                              children: [
                                                Text(_formatAddress(p['token_address'] ?? ''), style: const TextStyle(color: Colors.blueAccent, fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 13, decoration: TextDecoration.underline)),
                                                const SizedBox(width: 4),
                                                const Icon(PhosphorIcons.arrowUpRight, color: Colors.blueAccent, size: 14),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            '${isProfit ? '+' : ''}\$${pnl.toStringAsFixed(2)}',
                                            style: TextStyle(color: isProfit ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Closed: ${formatLagosTime(p['closed_at'])}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                          Row(
                                            children: [
                                              const Icon(PhosphorIcons.hourglassHigh, color: Colors.amberAccent, size: 12),
                                              const SizedBox(width: 4),
                                              Text('In trade: ${calculateTimeInTrade(p['opened_at'], p['closed_at'])}', style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                    ),
                  ],
                ),
          ),
        ],
      ),
    );
  }
}
