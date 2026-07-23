import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package0/phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return DefaultTabController(
      length: 4,
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
                Tab(text: 'Manual Snipe'),
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
                AdminSnipeTab(),
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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usdController.addListener(_updateCalc);
    _tpController.addListener(_updateCalc);
  }

  void _updateCalc() {
    final tp = double.tryParse(_tpController.text) ?? 0;
    final size = double.tryParse(_usdController.text) ?? 0;
    setState(() {
      _expectedProfit = size * (tp / 100);
    });
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      _tokenController.text = data.text!.trim();
    }
  }

  String? _validateSolanaAddress(String? value) {
    if (value == null || value.trim().isEmpty) return 'Address required';
    final val = value.trim();
    if (!RegExp(r'^[1-9A-HJ-NP-Za-km-z]{32,44}$').hasMatch(val)) {
      return 'Invalid Solana address format';
    }
    return null;
  }

  Future<void> _executeSnipe() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final api = context.read<ApiService>();
    final res = await api.postEndpoint('trade.php', {
      'token_address': _tokenController.text.trim(),
      'trade_usd': _usdController.text,
      'tp_percent': _tpController.text,
      'sl_percent': _slController.text,
    });

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['message'] ?? (res['status'] == 'success' ? 'Trade deployed!' : 'Execution failed')),
        backgroundColor: res['status'] == 'success' ? Colors.green : Colors.red,
      ));
      if (res['status'] == 'success') _tokenController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(PhosphorIcons.crosshairFill, color: theme.primaryColor),
                      const SizedBox(width: 8),
                      const Text('Target Contract', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _tokenController,
                    style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Solana Token Address',
                      labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                      suffixIcon: IconButton(icon: Icon(PhosphorIcons.clipboard, color: theme.primaryColor), onPressed: _pasteFromClipboard),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.2),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    validator: _validateSolanaAddress,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('EXECUTION PARAMETERS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _usdController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Trade Size (\$)',
                            labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                            filled: true,
                            fillColor: Colors.black.withOpacity(0.2),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _tpController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.greenAccent),
                          decoration: InputDecoration(
                            labelText: 'Take Profit (%)',
                            labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                            filled: true,
                            fillColor: Colors.black.withOpacity(0.2),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Projected Target Profit:', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                        Text('+\$${_expectedProfit.toStringAsFixed(2)}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(colors: [theme.primaryColor, const Color(0xFFE024CE)]),
                  boxShadow: [BoxShadow(color: theme.primaryColor.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5))],
                ),
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _executeSnipe,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Icon(PhosphorIcons.rocketLaunchFill, color: Colors.white),
                  label: Text(_isLoading ? 'SNIPING...' : 'DEPLOY CONTRACT', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== TAB 2: TRACKED WALLETS ====================
class TrackedWalletsTab extends StatelessWidget {
  const TrackedWalletsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tracked Target Address', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Icon(PhosphorIcons.userPlusFill, color: Theme.of(context).primaryColor),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12),
                  decoration: InputDecoration(
                    labelText: 'Whale / Shark Wallet Address',
                    labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.2),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Target Wallet Added to Tracker')));
                    },
                    child: const Text('Add Target Wallet'),
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

// ==================== TAB 3: BOT ENGINE CONFIG ====================
class BotConfigTab extends StatefulWidget {
  const BotConfigTab({super.key});

  @override
  State<BotConfigTab> createState() => _BotConfigTabState();
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
                      Text(_paperMode ? 'Paper Simulation Mode' : 'LIVE Real Money Mode', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                      const Text('Telegram Live Broadcasts', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

// ==================== TAB 4: TEAM QUOTAS ====================
class TeamQuotasTab extends StatelessWidget {
  const TeamQuotasTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('OsamaAdmin (You)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('Role: Master Admin', style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 12)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Text('Unlimited Quotas', style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
