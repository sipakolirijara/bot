import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../services/api_service.dart';

class MasterStrategySwitch extends StatefulWidget {
  const MasterStrategySwitch({super.key});

  @override
  State<MasterStrategySwitch> createState() => _MasterStrategySwitchState();
}

class _MasterStrategySwitchState extends State<MasterStrategySwitch> {
  bool _isLoading = true;
  bool _isAllPaused = false;

  @override
  void initState() {
    super.initState();
    _fetchStrategyStatus();
  }

  Future<void> _fetchStrategyStatus() async {
    final api = context.read<ApiService>();
    final res = await api.getEndpoint('strategies.php?action=fetch');
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res['status'] == 'success') {
          _isAllPaused = res['data']['all_paused'];
        }
      });
    }
  }

  Future<void> _toggleAll(bool value) async {
    setState(() => _isLoading = true);
    final api = context.read<ApiService>();
    final res = await api.postEndpoint('strategies.php?action=toggle_all', {
      'enable_state': value ? 1 : 0
    });

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res['status'] == 'success') {
          _isAllPaused = res['all_paused'];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = !_isAllPaused;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive 
            ? Colors.green.withOpacity(0.05) 
            : Colors.amber.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive 
              ? Colors.green.withOpacity(0.3) 
              : Colors.amber.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isActive ? Colors.green.withOpacity(0.1) : Colors.amber.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isActive ? PhosphorIcons.rocketLaunchFill : PhosphorIcons.pauseCircleFill,
              color: isActive ? Colors.green : Colors.amber,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Global Copy Trading',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  isActive ? 'Strategies are actively monitoring.' : 'All strategies currently paused.',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Switch(
              value: isActive,
              activeColor: Colors.green,
              onChanged: _toggleAll,
            ),
        ],
      ),
    );
  }
}
