import 'package:flutter/material.dart';

class SettingsCard extends StatelessWidget {
  final String title;
  final Widget child;
  const SettingsCard({super.key, required this.title, required this.child});

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
