import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/prism_provider.dart';
import '../widgets/screen_layout.dart';
import '../widgets/metrics_widgets.dart';
import '../widgets/graph_widgets.dart';
import '../widgets/alert_widgets.dart';

class NidsScreen extends StatelessWidget {
  const NidsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrismProvider>();
    return ScreenLayout(
      title: 'Network IDS',
      metrics: NidsMetrics(provider: provider),
      graph: TrafficGraph(provider: provider, title: 'Network Traffic (PPS)'),
      alerts: AlertFeed(
        alerts: provider.alerts.where((a) => a.source.toLowerCase() == 'nids').toList(),
        title: 'Network Alerts',
      ),
    );
  }
}

class NidsMetrics extends StatelessWidget {
  final PrismProvider provider;
  const NidsMetrics({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final net = provider.latestNetwork;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Network Metrics', style: Theme.of(context).textTheme.titleMedium),
            const Divider(height: 32),
            MetricRow(label: 'Throughput', value: (net?.pps ?? 0).toString(), unit: 'PPS'),
            MetricRow(
              label: 'Bandwidth',
              value: ((net?.bps ?? 0) / 1024).toStringAsFixed(1),
              unit: 'Kbps',
            ),
            const Spacer(),
            if (net != null) ...[
              const Text('Protocols', style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 8),
              ...net.protocols.entries.map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: LinearProgressIndicator(
                      value: e.value / (net.pps > 0 ? net.pps : 1),
                      backgroundColor: Colors.white10,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
