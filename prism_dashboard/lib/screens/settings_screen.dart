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
            title: 'Appearance',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Theme Mode', style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 12),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.brightness_auto)),
                    ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode)),
                    ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode)),
                  ],
                  selected: {provider.themeMode},
                  onSelectionChanged: (Set<ThemeMode> newSelection) {
                    provider.setThemeMode(newSelection.first);
                  },
                ),
                const SizedBox(height: 24),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Show Grid on Graphs'),
                  value: provider.showGrid,
                  onChanged: (v) => provider.setShowGrid(v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

