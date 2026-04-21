import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart'; // Import file_picker
import 'package:path_provider/path_provider.dart' as path_provider; // Import path_provider
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
        alerts: provider.alerts
            .where((a) => a.source.toLowerCase() == 'nids')
            .toList(),
        title: 'Network Alerts',
      ),
    );
  }
}

// Make NidsMetrics a StatefulWidget to manage the selected directory
class NidsMetrics extends StatefulWidget {
  final PrismProvider provider;
  const NidsMetrics({super.key, required this.provider});

  @override
  State<NidsMetrics> createState() => _NidsMetricsState();
}

class _NidsMetricsState extends State<NidsMetrics> {
  String? _selectedDirectory; // State variable to hold the selected directory

  // Method to pick a directory
  Future<void> _pickDirectory() async {
    // Request storage permissions if necessary (platform-dependent)
    // For simplicity, we are directly calling getDirectoryPath here.
    // On Android, you might need to request specific storage permissions.

    final directoryPath = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Folder to Monitor',
      // Use initialDirectory from state if available, otherwise a default path.
      // '/home' might not be a valid initial directory on all platforms.
      // Consider using path_provider to get a more appropriate default.
      initialDirectory: _selectedDirectory ?? '/', 
    );

    if (directoryPath != null) {
      setState(() {
        _selectedDirectory = directoryPath;
      });
      
      // TODO: Implement communication to send _selectedDirectory to the Rust engine.
      // This might involve:
      // 1. Relaunching the Rust engine process with the new path as a command-line argument.
      // 2. Sending a message to a running engine process via IPC (e.g., stdin, a dedicated channel).
      // For now, we are just storing the path in the UI state.
      print('Selected directory for monitoring: $directoryPath');
      
      // Example placeholder for engine communication:
      // await restartEngineWithNewPath(directoryPath); 
    } else {
      // User canceled the picker
      print('Directory selection canceled.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final net = widget.provider.latestNetwork;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Network Metrics',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Divider(height: 32),
            MetricRow(
              label: 'Throughput',
              value: (net?.pps ?? 0).toString(),
              unit: 'PPS',
            ),
            MetricRow(
              label: 'Bandwidth',
              value: ((net?.bps ?? 0) / 1024).toStringAsFixed(1),
              unit: 'Kbps',
            ),
            const Spacer(),
            if (net != null) ...[
              Text(
                'Protocols (1s Window)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...net.protocols.entries.map((e) {
                final double percentage = net.pps > 0
                    ? (e.value / net.pps) * 100
                    : 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            e.key,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${percentage.toStringAsFixed(1)}% (${e.value})',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: net.pps > 0 ? e.value / net.pps : 0,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainer,
                          minHeight: 6,
                          color: _getProtocolColor(context, e.key),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            // Button to select directory
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _pickDirectory,
              icon: const Icon(Icons.folder_open),
              label: Text(_selectedDirectory == null ? 'Select Watch Folder' : 'Change Folder'),
            ),
            const SizedBox(height: 10),
            // Display the selected directory
            if (_selectedDirectory != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Currently monitoring: $_selectedDirectory',
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getProtocolColor(BuildContext context, String proto) {
    final colors = Theme.of(context).colorScheme;
    switch (proto.toUpperCase()) {
      case 'TCP':
        return colors.primary;
      case 'UDP':
        return colors.secondary;
      case 'ICMP':
        return colors.tertiary;
      case 'OTHER IP':
        return colors.outline;
      default:
        return colors.surfaceContainerHighest;
    }
  }
}
