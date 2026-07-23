import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../services/api_service.dart';

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
  Map<String, dynamic> _stats = {'open_count': 0, 'total_pnl': 0.0};

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

  Future<void> _fetchPositions({bool silent = false}) async {
    if (!silent && mounted) setState(() => _isLoading = true);
    
    final api = context.read<ApiService>();
    final res = await api.getEndpoint('positions.php?action=fetch');
    
    if (mounted) {
      if (res['status'] == 'success') {
        setState(() {
          _stats = res['stats'] ?? _stats;
          _openPositions = res['open_positions'] ?? [];
          _closedPositions = res['closed_positions'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatMcap(dynamic v) {
    if (v == null) return '-';
    double val = v is String ? double.parse(v) : (v as num).toDouble();
    if (val >= 1000000) return '\$${(val / 1000000).toStringAsFixed(2)}M';
    if (val >= 1000) return '\$${(val / 1000).toStringAsFixed(1)}K';
    return '\$${val.round()}';
  }

  String _calculateDuration(String? openedAtStr, [String? closedAtStr]) {
    if (openedAtStr == null) return '-';
    try {
      DateTime start = DateTime.parse('${openedAtStr.replaceAll(' ', 'T')}Z').toLocal();
      DateTime end = closedAtStr != null 
          ? DateTime.parse('${closedAtStr.replaceAll(' ', 'T')}Z').toLocal() 
          : DateTime.now();
          
      int diffMins = end.difference(start).inMinutes;
      if (diffMins < 1) return '< 1m';
      
      int d = diffMins ~/ 1440;
      int h = (diffMins % 1440) ~/ 60;
      int m = diffMins % 60;
      
      List<String> res = [];
      if (d > 0) res.add('${d}d');
      if (h > 0) res.add('${h}h');
      if (m > 0) res.add('${m}m');
      return res.join(' ');
    } catch (e) {
      return '-';
    }
  }

  void _showEditModal(Map<String, dynamic> pos) {
    final tpController = TextEditingController(text: pos['tp_percent']?.toString() ?? '50');
    final slController = TextEditingController(text: pos['sl_percent']?.toString() ?? '20');

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
                Icon(PhosphorIcons.sliders(PhosphorIconsStyle.fill), color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text('Edit Targets', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: tpController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Take Profit (%)',
                prefixIcon: Icon(PhosphorIcons.trendUp(PhosphorIconsStyle.bold), color: Colors.green),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: slController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Stop Loss (%)',
                prefixIcon: Icon(PhosphorIcons.trendDown(PhosphorIconsStyle.bold), color: Colors.red),
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
                  final res = await api.postEndpoint('positions.php?action=update_tpsl', {
                    'id': pos['id'],
                    'tp_percent': double.tryParse(tpController.text) ?? 50,
                    'sl_percent': double.tryParse(slController.text) ?? 20,
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? '')));
                    _fetchPositions(silent: true);
                  }
                },
                child: const Text('Save Targets', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showCloseConfirm(Map<String, dynamic> pos) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(PhosphorIcons.warningCircle(PhosphorIconsStyle.fill), color: Colors.red),
            const SizedBox(width: 8),
            const Text('Confirm Exit', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('Are you sure you want to exit position ${(pos['token_address'] as String).substring(0, 8)}... at current market cap?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final api = context.read<ApiService>();
              final res = await api.postEndpoint('positions.php?action=close_position', {'id': pos['id']});
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? '')));
                _fetchPositions(silent: true);
              }
            },
            child: const Text('Exit Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: theme.colorScheme.surface,
            child: TabBar(
              labelColor: theme.primaryColor,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              indicatorColor: theme.primaryColor,
              tabs: const [
                Tab(text: 'Open Trades'),
                Tab(text: 'History'),
              ],
            ),
          ),
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
            Icon(PhosphorIcons.folderDashed(PhosphorIconsStyle.duotone), size: 64, color: theme.dividerColor),
            const SizedBox(height: 16),
            Text('No open positions', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchPositions(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _openPositions.length,
        itemBuilder: (context, index) {
          final p = _openPositions[index];
          final pnl = p['unrealized_pnl'] != null ? (p['unrealized_pnl'] as num).toDouble() : null;
          final pct = p['change_percent'] != null ? (p['change_percent'] as num).toDouble() : null;
          final isProfit = pnl != null && pnl >= 0;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${(p['token_address'] as String).substring(0, 10)}...',
                        style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12, color: theme.primaryColor),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(PhosphorIcons.clock(PhosphorIconsStyle.bold), size: 14, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          _calculateDuration(p['opened_at']),
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Entry MCAP', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        Text(_formatMcap(p['entry_mcap']), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Live MCAP', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        Text(_formatMcap(p['current_mcap']), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Unrealized P&L', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        Text(
                          pnl != null ? '${isProfit ? '+' : ''}\$${pnl.toStringAsFixed(2)}' : '-',
                          style: TextStyle(fontWeight: FontWeight.bold, color: isProfit ? Colors.green : Colors.red),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: () => _showEditModal(p),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: theme.dividerColor),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Icon(PhosphorIcons.pencilSimple(), size: 14),
                                const SizedBox(width: 4),
                                Text('+${p['tp_percent']}%', style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                                const Text(' / ', style: TextStyle(fontSize: 12)),
                                Text('-${p['sl_percent']}%', style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showCloseConfirm(p),
                      icon: Icon(PhosphorIcons.handPalm(PhosphorIconsStyle.bold), size: 16),
                      label: const Text('Close Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.1),
                        foregroundColor: Colors.red,
                        elevation: 0,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ],
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
            Icon(PhosphorIcons.receipt(PhosphorIconsStyle.duotone), size: 64, color: theme.dividerColor),
            const SizedBox(height: 16),
            Text('No closed positions', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchPositions(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _closedPositions.length,
        itemBuilder: (context, index) {
          final p = _closedPositions[index];
          final pnl = p['pnl_usd'] != null ? (p['pnl_usd'] as num).toDouble() : 0.0;
          final isProfit = pnl >= 0;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(p['token_address'] as String).substring(0, 10)}...',
                      style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    Text(
                      '${isProfit ? '+' : ''}\$${pnl.toStringAsFixed(2)}',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isProfit ? Colors.green : Colors.red),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(PhosphorIcons.hourglassHigh(PhosphorIconsStyle.bold), size: 12, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          _calculateDuration(p['opened_at'], p['closed_at']),
                          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.dividerColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        p['close_reason'] ?? 'MANUAL',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
