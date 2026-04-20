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
              const Text('Protocols (1s Window)', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...net.protocols.entries.map((e) {
                final double percentage = net.pps > 0 ? (e.value / net.pps) * 100 : 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(e.key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                          Text(
                            '${percentage.toStringAsFixed(1)}% (${e.value})',
                            style: const TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: net.pps > 0 ? e.value / net.pps : 0,
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          minHeight: 6,
                          color: _getProtocolColor(context, e.key),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Color _getProtocolColor(BuildContext context, String proto) {
    final colors = Theme.of(context).colorScheme;
    switch (proto.toUpperCase()) {
      case 'TCP': return colors.primary;
      case 'UDP': return colors.secondary;
      case 'ICMP': return colors.tertiary;
      case 'OTHER IP': return colors.outline;
      default: return colors.surfaceContainerHighest;
    }
  }
}
