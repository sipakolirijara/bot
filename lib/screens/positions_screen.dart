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
  String _historyFilter = 'All';

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
          _openPositions = res['open_positions'] ?? [];
          _closedPositions = res['closed_positions'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openDexScreener(String address) async {
    final url = Uri.parse('https://dexscreener.com/solana/$address');
    try {
      await launchUrl(url, mode: LaunchMode.inAppWebView);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open DexScreener')));
    }
  }

  void _copyAddress(String address) {
    Clipboard.setData(ClipboardData(text: address));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contract copied!'), backgroundColor: Colors.green, duration: Duration(seconds: 2)));
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  String _formatAddress(dynamic addr) {
    if (addr == null) return 'Unknown Token';
    String str = addr.toString();
    if (str.length <= 12) return str;
    return '${str.substring(0, 6)}...${str.substring(str.length - 4)}';
  }

  String _formatMcap(dynamic v) {
    final val = _parseDouble(v);
    if (val == null) return '-';
    if (val >= 1000000) return '\$${(val / 1000000).toStringAsFixed(2)}M';
    if (val >= 1000) return '\$${(val / 1000).toStringAsFixed(1)}K';
    return '\$${val.round()}';
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return '-';
    try {
      String dStr = dateStr.toString().replaceAll(' ', 'T');
      DateTime dt = DateTime.parse('${dStr}Z').toLocal();
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr.toString();
    }
  }

  void _showEditTargetsModal(Map<String, dynamic> position) {
    final tpController = TextEditingController(text: position['tp_percent']?.toString() ?? '0');
    final slController = TextEditingController(text: position['sl_percent']?.toString() ?? '0');
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(PhosphorIcons.slidersFill, color: theme.primaryColor),
                  const SizedBox(width: 8),
                  Text('Edit Targets', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
              const SizedBox(height: 8),
              Text('Contract: ${_formatAddress(position['token_address'])}', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12, fontFamily: 'monospace')),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: tpController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.greenAccent),
                      decoration: InputDecoration(labelText: 'Take Profit (%)', labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant), prefixIcon: Icon(PhosphorIcons.trendUp, color: Colors.greenAccent), filled: true, fillColor: Colors.black.withOpacity(0.2), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: slController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.redAccent),
                      decoration: InputDecoration(labelText: 'Stop Loss (%)', labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant), prefixIcon: Icon(PhosphorIcons.trendDown, color: Colors.redAccent), filled: true, fillColor: Colors.black.withOpacity(0.2), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: LinearGradient(colors: [theme.primaryColor, const Color(0xFFE024CE)])),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 16)),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final api = context.read<ApiService>();
                      final res = await api.postEndpoint('trade.php?action=update_tpsl', {
                        'id': position['id'],
                        'tp_percent': tpController.text,
                        'sl_percent': slController.text,
                      });
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Targets updated'), backgroundColor: res['status'] == 'success' ? Colors.green : Colors.red));
                        _fetchPositions();
                      }
                    },
                    child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  void _showCloseConfirmModal(Map<String, dynamic> position) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Confirm Manual Exit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to close position ${_formatAddress(position['token_address'])} at the current market cap?', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Closing position...'), backgroundColor: Colors.amber));
              final res = await context.read<ApiService>().postEndpoint('trade.php?action=close_position', {'id': position['id']});
              if (mounted) {
                if (res['status'] == 'closed' || res['status'] == 'success' || res['real'] == true) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Position successfully closed.'), backgroundColor: Colors.green));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['error'] ?? res['message'] ?? 'Failed to close'), backgroundColor: Colors.red));
                }
                _fetchPositions();
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
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            height: 50,
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.white.withOpacity(0.05))),
            child: TabBar(
              indicatorSize: TabBarIndicatorSize.tab, dividerColor: Colors.transparent,
              indicator: BoxDecoration(borderRadius: BorderRadius.circular(25), gradient: LinearGradient(colors: [theme.primaryColor, const Color(0xFFE024CE)]), boxShadow: [BoxShadow(color: theme.primaryColor.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))]),
              labelColor: Colors.white, unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
              tabs: const [Tab(text: 'LIVE TRADES'), Tab(text: 'HISTORY')],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading && _openPositions.isEmpty && _closedPositions.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(children: [_buildOpenList(theme), _buildClosedList(theme)]),
          ),
        ],
      ),
    );
  }

  Widget _buildOpenList(ThemeData theme) {
    if (_openPositions.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(PhosphorIcons.folderDashed, size: 64, color: Colors.white.withOpacity(0.1)), const SizedBox(height: 16), Text('No active positions', style: TextStyle(color: theme.colorScheme.onSurfaceVariant))]));
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
          final double tradeSize = _parseDouble(p['virtual_usd_amount']) ?? 0.0;

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
                      Text(p['wallet_label'] ?? 'Manual', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('ENTRY MCAP', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 10, letterSpacing: 1)), const SizedBox(height: 4), Text(_formatMcap(p['entry_mcap']), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14))]),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('LIVE MCAP', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 10, letterSpacing: 1)), const SizedBox(height: 4), Text(_formatMcap(p['current_mcap']), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14))]),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('UNREALIZED', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 10, letterSpacing: 1)), const SizedBox(height: 4), Text(pnl != null ? '${isProfit ? '+' : ''}\$${pnl.toStringAsFixed(2)}' : '-', style: TextStyle(fontWeight: FontWeight.bold, color: isProfit ? Colors.greenAccent : Colors.redAccent, fontSize: 16))]),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(height: 1, color: Colors.white.withOpacity(0.05)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('TRADE SIZE', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 10, letterSpacing: 1)), const SizedBox(height: 4), Text('\$${tradeSize.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14))]),
                      InkWell(
                        onTap: () => _showEditTargetsModal(p),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white.withOpacity(0.1))),
                          child: Row(
                            children: [
                              Icon(PhosphorIcons.pencilSimple, size: 14, color: theme.colorScheme.onSurfaceVariant),
                              const SizedBox(width: 6),
                              Text('+${p['tp_percent']}%', style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                              Text(' / ', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                              Text('-${p['sl_percent']}%', style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(_formatDate(p['opened_at']), style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _showCloseConfirmModal(p),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                          backgroundColor: Colors.redAccent.withOpacity(0.1),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(PhosphorIcons.handPalmFill, size: 16, color: Colors.redAccent),
                        label: const Text('Close Now', style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
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
    final filteredPositions = _closedPositions.where((p) {
      final pnl = _parseDouble(p['pnl_usd']) ?? 0.0;
      if (_historyFilter == 'Profit') return pnl > 0;
      if (_historyFilter == 'Loss') return pnl <= 0;
      if (_historyFilter == 'Manual') return p['close_reason']?.toString().toUpperCase() == 'MANUAL';
      return true;
    }).toList();

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: ['All', 'Profit', 'Loss', 'Manual'].map((filter) {
              final isSelected = _historyFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(filter, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant)),
                  selected: isSelected,
                  selectedColor: theme.primaryColor.withOpacity(0.8),
                  backgroundColor: Colors.white.withOpacity(0.05),
                  side: BorderSide(color: isSelected ? theme.primaryColor : Colors.transparent),
                  onSelected: (selected) { if (selected) setState(() => _historyFilter = filter); },
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: filteredPositions.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(PhosphorIcons.receipt, size: 64, color: Colors.white.withOpacity(0.1)), const SizedBox(height: 16), Text('No trades match this filter', style: TextStyle(color: theme.colorScheme.onSurfaceVariant))]))
              : RefreshIndicator(
                  onRefresh: () => _fetchPositions(),
                  color: theme.primaryColor,
                  backgroundColor: theme.colorScheme.surface,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    itemCount: filteredPositions.length,
                    itemBuilder: (context, index) {
                      final p = filteredPositions[index];
                      final pnl = _parseDouble(p['pnl_usd']) ?? 0.0;
                      final isProfit = pnl >= 0;
                      final String rawAddress = p['token_address']?.toString() ?? '';
                      final String sizeUsd = _parseDouble(p['virtual_usd_amount'] ?? p['trade_usd'])?.toStringAsFixed(2) ?? '0.00';

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
                                    child: Row(
                                      children: [
                                        Text(_formatAddress(rawAddress), style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                                        const SizedBox(width: 6),
                                        Icon(PhosphorIcons.copy, size: 14, color: theme.colorScheme.onSurfaceVariant),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text('${isProfit ? '+' : ''}\$${pnl.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isProfit ? Colors.greenAccent : Colors.redAccent)),
                                      const SizedBox(width: 12),
                                      InkWell(onTap: () => _openDexScreener(rawAddress), child: Icon(PhosphorIcons.chartLineUp, size: 20, color: theme.primaryColor)),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(height: 1, color: Colors.white.withOpacity(0.05)),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('ENTRY MCAP', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 10, letterSpacing: 1)), const SizedBox(height: 4), Text(_formatMcap(p['entry_mcap']), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14))]),
                                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('EXIT MCAP', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 10, letterSpacing: 1)), const SizedBox(height: 4), Text(_formatMcap(p['close_mcap'] ?? p['current_mcap']), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14))]),
                                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('TRADE SIZE', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 10, letterSpacing: 1)), const SizedBox(height: 4), Text('\$$sizeUsd', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14))]),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_formatDate(p['opened_at']), style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(6)),
                                    child: Text(p['close_reason']?.toString() ?? 'MANUAL', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant, letterSpacing: 1)),
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
    );
  }
}
