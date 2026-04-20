import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/prism_provider.dart';
import '../widgets/settings_widgets.dart';
import '../widgets/status_widgets.dart';

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
          SettingsCard(
            title: 'Engine Connection',
            child: Column(
              children: [
                StatusIndicator(isConnected: provider.isConnected),
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
          SettingsCard(
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
