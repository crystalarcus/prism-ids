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
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
          surface: const Color(0xFF1C1B1F),
        ),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          color: const Color(0xFF252429),
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const NidsScreen(),
    const HidsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.selected,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Icon(Icons.security, color: Theme.of(context).colorScheme.primary, size: 32),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.lan_outlined),
                selectedIcon: Icon(Icons.lan),
                label: Text('NIDS'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.terminal_outlined),
                selectedIcon: Icon(Icons.terminal),
                label: Text('HIDS'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
          ),
        ],
      ),
    );
  }
}

class NidsScreen extends StatelessWidget {
  const NidsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrismProvider>();
    return _ScreenLayout(
      title: 'Network IDS',
      metrics: _NidsMetrics(provider: provider),
      graph: _TrafficGraph(provider: provider, title: 'Network Traffic (PPS)'),
      alerts: _AlertFeed(
        alerts: provider.alerts.where((a) => a.source.toLowerCase() == 'network').toList(),
        title: 'Network Alerts',
      ),
    );
  }
}

class HidsScreen extends StatelessWidget {
  const HidsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrismProvider>();
    return _ScreenLayout(
      title: 'Host IDS',
      metrics: _HidsMetrics(provider: provider),
      graph: _HostGraph(provider: provider),
      alerts: _AlertFeed(
        alerts: provider.alerts.where((a) => a.source.toLowerCase() == 'host').toList(),
        title: 'Host Alerts',
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrismProvider>();
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 32),
          _SettingsCard(
            title: 'Engine Connection',
            child: Column(
              children: [
                _StatusIndicator(isConnected: provider.isConnected),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => provider.connect(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reconnect Engine'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SettingsCard(
            title: 'Display Preferences',
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Show Grid on Graphs'),
                  value: true,
                  onChanged: (v) {},
                ),
                SwitchListTile(
                  title: const Text('High Contrast Mode'),
                  value: false,
                  onChanged: (v) {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScreenLayout extends StatelessWidget {
  final String title;
  final Widget metrics;
  final Widget graph;
  final Widget alerts;

  const _ScreenLayout({
    required this.title,
    required this.metrics,
    required this.graph,
    required this.alerts,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const _StatusIndicatorSmall(),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 300, child: metrics),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(flex: 3, child: graph),
                      const SizedBox(height: 24),
                      Expanded(flex: 2, child: alerts),
                    ],
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

class _NidsMetrics extends StatelessWidget {
  final PrismProvider provider;
  const _NidsMetrics({required this.provider});

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
            _MetricRow(label: 'Throughput', value: '${net?.pps ?? 0}', unit: 'PPS'),
            _MetricRow(
              label: 'Bandwidth',
              value: '${((net?.bps ?? 0) / 1024).toStringAsFixed(1)}',
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

class _HidsMetrics extends StatelessWidget {
  final PrismProvider provider;
  const _HidsMetrics({required this.provider});

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
            _MetricRow(
              label: 'CPU Usage',
              value: '${host?.cpuUsage.toStringAsFixed(1) ?? 0}',
              unit: '%',
            ),
            _MetricRow(
              label: 'Memory',
              value: '${((host?.memoryUsage ?? 0) / (1024 * 1024)).toStringAsFixed(0)}',
              unit: 'MB',
            ),
            const SizedBox(height: 24),
            Text('Top Processes', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: host?.topProcesses.length ?? 0,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
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

class _TrafficGraph extends StatelessWidget {
  final PrismProvider provider;
  final String title;
  const _TrafficGraph({required this.provider, required this.title});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 24),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.white.withOpacity(0.05),
                      strokeWidth: 1,
                    ),
                    getDrawingVerticalLine: (value) => FlLine(
                      color: Colors.white.withOpacity(0.05),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 5,
                        getTitlesWidget: (value, meta) => Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            '${value.toInt()}s',
                            style: const TextStyle(color: Colors.grey, fontSize: 10),
                          ),
                        ),
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 500,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                        reservedSize: 42,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: provider.ppsHistory.asMap().entries.map((e) {
                        return FlSpot(e.key.toDouble(), e.value.toDouble());
                      }).toList(),
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      ),
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

class _HostGraph extends StatelessWidget {
  final PrismProvider provider;
  const _HostGraph({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CPU Usage History (%)', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 24),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.white.withOpacity(0.05),
                      strokeWidth: 1,
                    ),
                    getDrawingVerticalLine: (value) => FlLine(
                      color: Colors.white.withOpacity(0.05),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 10,
                        getTitlesWidget: (value, meta) => Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            '${value.toInt()}s',
                            style: const TextStyle(color: Colors.grey, fontSize: 10),
                          ),
                        ),
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 20,
                        getTitlesWidget: (value, meta) => Text(
                          '${value.toInt()}%',
                          style: const TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                        reservedSize: 42,
                      ),
                    ),
                  ),
                  minY: 0,
                  maxY: 100,
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: provider.cpuHistory.asMap().entries.map((e) {
                        return FlSpot(e.key.toDouble(), e.value);
                      }).toList(),
                      isCurved: true,
                      color: Colors.orangeAccent,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.orangeAccent.withOpacity(0.1),
                      ),
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
  final String title;
  const _AlertFeed({required this.alerts, required this.title});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(title, style: Theme.of(context).textTheme.titleSmall),
          ),
          const Divider(height: 1),
          Expanded(
            child: alerts.isEmpty
                ? const Center(
                    child: Text('No active incidents.', style: TextStyle(color: Colors.white24)),
                  )
                : ListView.builder(
                    itemCount: alerts.length,
                    itemBuilder: (context, index) {
                      final alert = alerts[index];
                      final isHigh = alert.severity == AlertSeverity.high;
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (isHigh ? Colors.red : Colors.orange).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isHigh ? Icons.gpp_maybe : Icons.warning_amber_rounded,
                            color: isHigh ? Colors.red : Colors.orange,
                            size: 16,
                          ),
                        ),
                        title: Text(alert.message, style: const TextStyle(fontSize: 14)),
                        subtitle: Text(
                          '${alert.timestamp} • ${alert.source.toUpperCase()}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        trailing: const Icon(Icons.chevron_right, size: 16, color: Colors.white10),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  const _MetricRow({required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final bool isConnected;
  const _StatusIndicator({required this.isConnected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isConnected ? Colors.green : Colors.red).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (isConnected ? Colors.green : Colors.red).withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isConnected ? Colors.green : Colors.red,
              boxShadow: [
                BoxShadow(
                  color: (isConnected ? Colors.green : Colors.red).withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                )
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            isConnected ? 'CORE ENGINE ONLINE' : 'CORE ENGINE DISCONNECTED',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isConnected ? Colors.green : Colors.red,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusIndicatorSmall extends StatelessWidget {
  const _StatusIndicatorSmall();

  @override
  Widget build(BuildContext context) {
    final isConnected = context.watch<PrismProvider>().isConnected;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isConnected ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isConnected ? 'ONLINE' : 'OFFLINE',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SettingsCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 24),
            child,
          ],
        ),
      ),
    );
  }
}
