import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/prism_data.dart';
import '../providers/prism_provider.dart';

class AlertFeed extends StatelessWidget {
  final List<Alert> alerts;
  final String title;
  final VoidCallback? onExpandToggle;
  final bool isExpanded;

  const AlertFeed({
    super.key,
    required this.alerts,
    required this.title,
    this.onExpandToggle,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                Row(
                  children: [
                    if (alerts.any((a) => a.status == AlertStatus.unresolved))
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${alerts.where((a) => a.status == AlertStatus.unresolved).length} NEW',
                          style: TextStyle(
                            color: colorScheme.error,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (onExpandToggle != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          isExpanded ? Icons.fullscreen_exit : Icons.fullscreen,
                          size: 20,
                        ),
                        onPressed: onExpandToggle,
                        tooltip: isExpanded ? 'Collapse' : 'Expand',
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: alerts.isEmpty
                ? Center(
                    child: Text(
                      'No active incidents.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
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
    final colorScheme = Theme.of(context).colorScheme;
    final isHigh = alert.severity == AlertSeverity.high;
    final isResolved = alert.status == AlertStatus.resolved;
    final color = isHigh ? colorScheme.error : colorScheme.tertiary;

    return Opacity(
      opacity: isResolved ? 0.6 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isResolved
              ? colorScheme.surfaceContainer
              : colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isResolved
                ? colorScheme.outlineVariant.withValues(alpha: 0.5)
                : colorScheme.outlineVariant,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isHigh
                              ? Icons.gpp_maybe
                              : Icons.warning_amber_rounded,
                          color: color,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          alert.severity.name.toUpperCase(),
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    alert.timestamp,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    alert.source.toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildMessageBody(context),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    height: 32,
                    child: SegmentedButton<AlertStatus>(
                      segments: const [
                        ButtonSegment(
                          value: AlertStatus.unresolved,
                          label: Text(
                            'Unresolved',
                            style: TextStyle(fontSize: 11),
                          ),
                          icon: Icon(Icons.error_outline, size: 16),
                        ),
                        ButtonSegment(
                          value: AlertStatus.resolved,
                          label: Text(
                            'Resolved',
                            style: TextStyle(fontSize: 11),
                          ),
                          icon: Icon(Icons.check_circle_outline, size: 16),
                        ),
                      ],
                      selected: {alert.status},
                      onSelectionChanged: (Set<AlertStatus> newSelection) {
                        context.read<PrismProvider>().updateAlertStatus(
                          alert,
                          newSelection.first,
                        );
                      },
                      style: SegmentedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
              Text(
                'EVENT: ',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              _InfoChip(
                label: kind,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              path,
              style: TextStyle(
                fontFamily: 'maple mono',
                fontSize: 14,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      );
    }

    // Default or HIDS/NIDS highlight
    return Text(msg, style: const TextStyle(fontSize: 14, height: 1.4));
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
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
