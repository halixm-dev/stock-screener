import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../state/config_cubit.dart';
import '../../state/config_state.dart';
import '../theme/design_tokens.dart';

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
          final tokens = Theme.of(context).extension<DesignTokens>()!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                decoration: BoxDecoration(
                  color: tokens.surface30,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: tokens.cardShadow,
                ),
                child: Column(
                  children: [
                    // ── Indicator Config ──────────────────────────────
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: Icon(Icons.tune, color: tokens.accent10),
                      title: Text('Indicator Config', style: TextStyle(fontWeight: FontWeight.bold, color: tokens.textPrimary)),
                      subtitle: Text(
                        'Leading: ${config.leadingIndicator} · '
                        '${config.confirmations.length} confirmations',
                        style: TextStyle(color: tokens.textSecondary),
                      ),
                      trailing: Icon(Icons.chevron_right, color: tokens.textSecondary),
                      onTap: () => context.push('/settings/indicators'),
                    ),
                    Divider(height: 1, indent: 20, endIndent: 20, color: tokens.textSecondary.withValues(alpha: 0.2)),

                    // ── Scan Schedule ─────────────────────────────────
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: Icon(Icons.schedule, color: tokens.accent10),
                      title: Text('Scan Schedule', style: TextStyle(fontWeight: FontWeight.bold, color: tokens.textPrimary)),
                      subtitle: Text(_scanScheduleSubtitle(state), style: TextStyle(color: tokens.textSecondary)),
                      trailing: Icon(Icons.chevron_right, color: tokens.textSecondary),
                      onTap: () => context.push('/settings/schedule'),
                    ),
                    Divider(height: 1, indent: 20, endIndent: 20, color: tokens.textSecondary.withValues(alpha: 0.2)),

                    // ── Stock Universe ────────────────────────────────
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: Icon(Icons.public, color: tokens.accent10),
                      title: Text('Stock Universe', style: TextStyle(fontWeight: FontWeight.bold, color: tokens.textPrimary)),
                      subtitle: Text(_universeSubtitle(state), style: TextStyle(color: tokens.textSecondary)),
                      trailing: Icon(Icons.chevron_right, color: tokens.textSecondary),
                      onTap: () => context.push('/settings/universe'),
                    ),
                  ],
                ),
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

