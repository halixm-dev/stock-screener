import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../state/config_cubit.dart';
import '../../state/config_state.dart';

/// Settings hub that links to Indicator Config, Scan Schedule,
/// and Stock Universe sub-screens.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: BlocBuilder<ConfigCubit, ConfigState>(
        builder: (context, state) {
          final config = state.config;

          return ListView(
            children: [
              // ── Indicator Config ──────────────────────────────
              ListTile(
                leading: const Icon(Icons.tune),
                title: const Text('Indicator Config'),
                subtitle: Text(
                  'Leading: ${config.leadingIndicator} · '
                  '${config.confirmations.length} confirmations',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings/indicators'),
              ),
              const Divider(),

              // ── Scan Schedule ─────────────────────────────────
              ListTile(
                leading: const Icon(Icons.schedule),
                title: const Text('Scan Schedule'),
                subtitle: Text(_scanScheduleSubtitle(state)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings/schedule'),
              ),
              const Divider(),

              // ── Stock Universe ────────────────────────────────
              ListTile(
                leading: const Icon(Icons.public),
                title: const Text('Stock Universe'),
                subtitle: Text(_universeSubtitle(state)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings/universe'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Formats the scan schedule subtitle based on enabled state and interval.
  String _scanScheduleSubtitle(ConfigState state) {
    if (!state.isBackgroundScanEnabled) return 'Disabled';

    final minutes = state.config.scanIntervalMinutes;
    final label = minutes >= 60 ? '${minutes ~/ 60}h' : '${minutes}m';
    return 'Every $label · Active';
  }

  /// Formats the stock universe subtitle from the preset or custom ticker list.
  String _universeSubtitle(ConfigState state) {
    final preset = state.config.universePreset;
    final tickers = state.config.universe.length;

    if (preset == 'custom') return 'Custom ($tickers tickers)';
    return '${preset.toUpperCase()} preset';
  }
}

