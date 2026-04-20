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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                if (alerts.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${alerts.length} NEW',
                      style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: alerts.isEmpty
                ? const Center(
                    child: Text('No active incidents.', style: TextStyle(color: Colors.white24)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: alerts.length,
                    itemBuilder: (context, index) {
                      return _AlertItem(alert: alerts[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _AlertItem extends StatelessWidget {
  final Alert alert;
  const _AlertItem({required this.alert});

  @override
  Widget build(BuildContext context) {
    final isHigh = alert.severity == AlertSeverity.high;
    final color = isHigh ? Colors.red : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(isHigh ? Icons.gpp_maybe : Icons.warning_amber_rounded, 
                           color: color, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        alert.severity.name.toUpperCase(),
                        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  alert.timestamp,
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                ),
                const Spacer(),
                Text(
                  alert.source.toUpperCase(),
                  style: const TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildMessageBody(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBody(BuildContext context) {
    final msg = alert.message;
    
    // Parse FIM: "File changed: Kind | Path: [path]"
    if (alert.source.toLowerCase() == 'fim' && msg.contains('|')) {
      final parts = msg.split('|');
      final kind = parts[0].replaceAll('File changed:', '').trim();
      final path = parts[1].replaceAll('Path:', '').trim();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('EVENT: ', style: TextStyle(color: Colors.grey, fontSize: 11)),
              _InfoChip(label: kind, color: Colors.blueAccent),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              path,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.greenAccent),
            ),
          ),
        ],
      );
    }

    // Default or HIDS/NIDS highlight
    return Text(
      msg,
      style: const TextStyle(fontSize: 14, height: 1.4),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;
  const _InfoChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
