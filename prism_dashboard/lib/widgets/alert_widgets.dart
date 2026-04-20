import 'package:flutter/material.dart';
import '../models/prism_data.dart';

class AlertFeed extends StatelessWidget {
  final List<Alert> alerts;
  final String title;
  const AlertFeed({super.key, required this.alerts, required this.title});

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
                            color: (isHigh ? Colors.red : Colors.orange).withValues(alpha: 0.1),
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
