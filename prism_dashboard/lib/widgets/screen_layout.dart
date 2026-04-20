import 'package:flutter/material.dart';
import 'status_widgets.dart';

class ScreenLayout extends StatelessWidget {
  final String title;
  final Widget metrics;
  final Widget graph;
  final Widget alerts;

  const ScreenLayout({
    super.key,
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
              const StatusIndicatorSmall(),
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
