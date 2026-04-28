import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/prism_provider.dart';
import '../widgets/screen_layout.dart';
import '../widgets/metrics_widgets.dart';
import '../widgets/graph_widgets.dart';
import '../widgets/alert_widgets.dart';

class HidsScreen extends StatefulWidget {
  const HidsScreen({super.key});

  @override
  State<HidsScreen> createState() => _HidsScreenState();
}

class _HidsScreenState extends State<HidsScreen> {
  bool _isAlertsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrismProvider>();
    return ScreenLayout(
      title: 'Host IDS',
      isExpanded: _isAlertsExpanded,
      metrics: HidsMetrics(provider: provider),
      graph: HostGraph(provider: provider),
      alerts: AlertFeed(
        alerts: provider.alerts.where((a) {
          final s = a.source.toLowerCase();
          return s == 'hids' || s == 'fim';
        }).toList(),
        title: 'Host & FIM Alerts',
        isExpanded: _isAlertsExpanded,
        onExpandToggle: () {
          setState(() {
            _isAlertsExpanded = !_isAlertsExpanded;
          });
        },
      ),
    );
  }
}

class HidsMetrics extends StatelessWidget {
  final PrismProvider provider;
  const HidsMetrics({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final host = provider.latestHost;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('System Resources', style: Theme.of(context).textTheme.titleMedium),
            const Divider(height: 32),
            MetricRow(
              label: 'CPU Usage',
              value: (host?.cpuUsage ?? 0).toStringAsFixed(1),
              unit: '%',
            ),
            MetricRow(
              label: 'Memory',
              value: ((host?.memoryUsage ?? 0) / (1024 * 1024)).toStringAsFixed(0),
              unit: 'MB',
            ),
            const SizedBox(height: 24),
            Text('Top Processes', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: host?.topProcesses.length ?? 0,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final p = host!.topProcesses[i];
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(p.name,
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis),
                      ),
                      Text('${p.cpuUsage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          )),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
