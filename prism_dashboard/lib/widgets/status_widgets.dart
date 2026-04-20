import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Correct import for Provider
import '../providers/prism_provider.dart';

class StatusIndicator extends StatelessWidget {
  final bool isConnected;
  const StatusIndicator({super.key, required this.isConnected});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final statusColor = isConnected ? colors.primary : colors.error;
    final statusColorWithOpacity = isConnected ? colors.primary.withValues(alpha: 0.05) : colors.error.withValues(alpha: 0.05);
    final borderColor = isConnected ? colors.primary.withValues(alpha: 0.1) : colors.error.withValues(alpha: 0.1);
    final shadowColor = statusColor.withValues(alpha: 0.5);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColorWithOpacity,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor,
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
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
              color: statusColor,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class StatusIndicatorSmall extends StatelessWidget {
  const StatusIndicatorSmall({super.key});

  @override
  Widget build(BuildContext context) {
    final isConnected = Provider.of<PrismProvider>(context).isConnected; // Use Provider.of
    final colors = Theme.of(context).colorScheme;
    final statusColor = isConnected ? colors.primary : colors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.05), // Replaced deprecated surfaceVariant
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
              color: statusColor,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isConnected ? 'ONLINE' : 'OFFLINE',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
          ),
        ],
      ),
    );
  }
}
