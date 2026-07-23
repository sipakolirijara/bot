import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  Timer? _pollingTimer;
  bool _isLoading = true;
  List<dynamic> _openPositions = [];
  List<dynamic> _closedPositions = [];

  @override
  void initState() {
    super.initState();
    _fetchPositions();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchPositions(silent: true));
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _openDexScreener(String address) async {
    final url = Uri.parse('https://dexscreener.com/solana/$address');
    try {
      await launchUrl(url, mode: LaunchMode.inAppWebView);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open DexScreener')));
      }
    }
  }

  void _copyAddress(String address) {
    Clipboard.setData(ClipboardData(text: address));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Contract address copied!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // --- SAFE PARSERS ---
  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  String _formatAddress(dynamic addr) {
    if (addr == null) return 'Unknown Token';
    String str = addr.toString();
    if (str.length <= 10) return str;
    return '${str.substring(0, 8)}...${str.substring(str.length - 6)}';
  }

  String _formatMcap(dynamic v) {
    final val = _parseDouble(v);
    if (val == null) return '-';
    if (val >= 1000000) return '\$${(val / 1000000).toStringAsFixed(2)}M';
    if (val >= 1000) return '\$${(val / 1000).toStringAsFixed(1)}K';
    return '\$${val.round()}';
  }

  Future<void> _fetchPositions({bool silent = false}) async {
    if (!silent && mounted) setState(() => _isLoading = true);
    final api = context.read<ApiService>();
    final res = await api.getEndpoint('positions.php?action=fetch');
    
    if (mounted) {
      if (res['status'] == 'success') {
        setState(() {
          _openPositions = res['open_positions'] ?? [];
          _closedPositions = res['closed_positions'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Premium Pill Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            height: 50,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: TabBar(
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                gradient: LinearGradient(colors: [theme.primaryColor, const Color(0xFFE024CE)]),
                boxShadow: [BoxShadow(color: theme.primaryColor.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
              tabs: const [Tab(text: 'LIVE TRADES'), Tab(text: 'HISTORY')],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    children: [
                      _buildOpenList(theme),
                      _buildClosedList(theme),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpenList(ThemeData theme) {
    if (_openPositions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(PhosphorIcons.scan, size: 64, color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 16),
            Text('No active positions', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchPositions(),
      color: theme.primaryColor,
      backgroundColor: theme.colorScheme.surface,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        itemCount: _openPositions.length,
        itemBuilder: (context, index) {
          final p = _openPositions[index];
          final pnl = _parseDouble(p['unrealized_pnl']);
          final isProfit = pnl != null && pnl >= 0;
          final String rawAddress = p['token_address']?.toString() ?? '';

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () => _copyAddress(rawAddress),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: theme.primaryColor.withOpacity(0.3))),
                          child: Row(
                            children: [
                              Text(_formatAddress(rawAddress), style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 13, color: theme.primaryColor)),
                              const SizedBox(width: 6),
                              Icon(PhosphorIcons.copy, size: 14, color: theme.primaryColor),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(PhosphorIcons.chartLineUp, color: Colors.white),
                        tooltip: 'View on DexScreener',
                        onPressed: () => _openDexScreener(rawAddress),
                        style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.05)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('ENTRY MCAP', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 10, letterSpacing: 1)), const SizedBox(height: 4), Text(_formatMcap(p['entry_mcap']), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16))]),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('LIVE MCAP', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 10, letterSpacing: 1)), const SizedBox(height: 4), Text(_formatMcap(p['current_mcap']), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16))]),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('UNREALIZED', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 10, letterSpacing: 1)), const SizedBox(height: 4), Text(pnl != null ? '${isProfit ? '+' : ''}\$${pnl.toStringAsFixed(2)}' : '-', style: TextStyle(fontWeight: FontWeight.bold, color: isProfit ? Colors.greenAccent : Colors.redAccent, fontSize: 16))]),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildClosedList(ThemeData theme) {
    if (_closedPositions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(PhosphorIcons.receipt, size: 64, color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 16),
            Text('Ledger is empty', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchPositions(),
      color: theme.primaryColor,
      backgroundColor: theme.colorScheme.surface,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        itemCount: _closedPositions.length,
        itemBuilder: (context, index) {
          final p = _closedPositions[index];
          final pnl = _parseDouble(p['pnl_usd']) ?? 0.0;
          final isProfit = pnl >= 0;
          final String rawAddress = p['token_address']?.toString() ?? '';

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () => _copyAddress(rawAddress),
                        child: Row(
                          children: [
                            Text(_formatAddress(rawAddress), style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                            const SizedBox(width: 4),
                            Icon(PhosphorIcons.copy, size: 12, color: theme.colorScheme.onSurfaceVariant),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Text('${isProfit ? '+' : ''}\$${pnl.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isProfit ? Colors.greenAccent : Colors.redAccent)),
                          const SizedBox(width: 12),
                          InkWell(
                            onTap: () => _openDexScreener(rawAddress),
                            child: Icon(PhosphorIcons.arrowSquareOut, size: 18, color: theme.primaryColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(6)),
                    child: Text(p['close_reason']?.toString() ?? 'MANUAL CLOSE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant, letterSpacing: 1)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
