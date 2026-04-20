import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'providers/prism_provider.dart';
import 'models/prism_data.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => PrismProvider()..connect(),
      child: const PrismApp(),
    ),
  );
}

class PrismApp extends StatelessWidget {
  const PrismApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prism IDS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.cyan,
          brightness: Brightness.dark,
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrismProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('PRISM HYBRID IDS'),
        actions: [
          _StatusIndicator(isConnected: provider.isConnected),
          const SizedBox(width: 20),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Expanded(child: _MetricsCard(provider: provider)),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: _TrafficGraph(provider: provider)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _AlertFeed(alerts: provider.alerts),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final bool isConnected;
  const _StatusIndicator({required this.isConnected});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isConnected ? Colors.green : Colors.red,
          ),
        ),
        const SizedBox(width: 8),
        Text(isConnected ? 'ENGINE ONLINE' : 'ENGINE OFFLINE'),
      ],
    );
  }
}

class _MetricsCard extends StatelessWidget {
  final PrismProvider provider;
  const _MetricsCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final net = provider.latestNetwork;
    final host = provider.latestHost;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Live Metrics', style: Theme.of(context).textTheme.titleLarge),
            const Divider(),
            _MetricRow(label: 'Network PPS', value: '${net?.pps ?? 0}'),
            _MetricRow(label: 'Bandwidth', value: '${((net?.bps ?? 0) / 1024).toStringAsFixed(2)} Kbps'),
            _MetricRow(label: 'CPU Usage', value: '${host?.cpuUsage.toStringAsFixed(1) ?? 0}%'),
            _MetricRow(label: 'RAM Usage', value: '${((host?.memoryUsage ?? 0) / (1024 * 1024)).toStringAsFixed(0)} MB'),
            const Spacer(),
            if (host != null) ...[
              const Text('Top Processes:'),
              ...host.topProcesses.map((p) => Text(
                '${p.name}: ${p.cpuUsage.toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              )),
            ]
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  const _MetricRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.cyan)),
        ],
      ),
    );
  }
}

class _TrafficGraph extends StatelessWidget {
  final PrismProvider provider;
  const _TrafficGraph({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Network Traffic (Packets/Sec)'),
            const SizedBox(height: 10),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: provider.ppsHistory.asMap().entries.map((e) {
                        return FlSpot(e.key.toDouble(), e.value.toDouble());
                      }).toList(),
                      isCurved: true,
                      color: Colors.cyan,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertFeed extends StatelessWidget {
  final List<Alert> alerts;
  const _AlertFeed({required this.alerts});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text('Security Incident Feed', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 1),
          Expanded(
            child: alerts.isEmpty
                ? const Center(child: Text('No incidents detected.', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: alerts.length,
                    itemBuilder: (context, index) {
                      final alert = alerts[index];
                      return ListTile(
                        leading: Icon(
                          Icons.warning,
                          color: alert.severity == AlertSeverity.high ? Colors.red : Colors.orange,
                        ),
                        title: Text(alert.message),
                        subtitle: Text('${alert.timestamp} | Source: ${alert.source}'),
                        dense: true,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
