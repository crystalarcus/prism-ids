import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/prism_provider.dart';

class StatusIndicator extends StatelessWidget {
  final bool isConnected;
  const StatusIndicator({super.key, required this.isConnected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isConnected ? Colors.green : Colors.red).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (isConnected ? Colors.green : Colors.red).withValues(alpha: 0.1)),
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
                  color: (isConnected ? Colors.green : Colors.red).withValues(alpha: 0.5),
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

class StatusIndicatorSmall extends StatelessWidget {
  const StatusIndicatorSmall({super.key});

  @override
  Widget build(BuildContext context) {
    final isConnected = context.watch<PrismProvider>().isConnected;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
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
