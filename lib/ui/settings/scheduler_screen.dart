import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:workmanager/workmanager.dart';

import '../../application/notification_service.dart';
import '../../state/config_cubit.dart';
import '../../state/config_state.dart';
import '../theme/design_tokens.dart';

class SchedulerScreen extends StatelessWidget {
  const SchedulerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Schedule')),
      body: BlocBuilder<ConfigCubit, ConfigState>(
        builder: (context, state) {
          final tokens = Theme.of(context).extension<DesignTokens>()!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Enable / Disable Card ──
              Container(
                decoration: BoxDecoration(
                  color: tokens.surface30,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: tokens.cardShadow,
                ),
                child: SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  title: Text('Enable Background Scans', style: TextStyle(fontWeight: FontWeight.bold, color: tokens.textPrimary)),
                  subtitle: Text(
                    'Automatically scan during IDX market hours',
                    style: TextStyle(color: tokens.textSecondary),
                  ),
                  activeColor: tokens.accent10,
                  value: state.isBackgroundScanEnabled,
                  onChanged: (enabled) => _toggleBackgroundScan(
                    context,
                    enabled,
                    state.config.scanIntervalMinutes,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Interval Card ──
              if (state.isBackgroundScanEnabled)
                Container(
                  decoration: BoxDecoration(
                    color: tokens.surface30,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: tokens.cardShadow,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scan Interval',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: tokens.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          initialValue: state.config.scanIntervalMinutes,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 15,
                              child: Text('Every 15 minutes'),
                            ),
                            DropdownMenuItem(
                              value: 30,
                              child: Text('Every 30 minutes'),
                            ),
                            DropdownMenuItem(
                              value: 60,
                              child: Text('Every 1 hour'),
                            ),
                            DropdownMenuItem(
                              value: 120,
                              child: Text('Every 2 hours'),
                            ),
                            DropdownMenuItem(
                              value: 240,
                              child: Text('Every 4 hours'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            context.read<ConfigCubit>().setScanInterval(value);
                            if (!kIsWeb) {
                              Workmanager().registerPeriodicTask(
                                '1',
                                'backgroundScreenerTask',
                                frequency: Duration(minutes: value),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Info Card ──
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: tokens.accent10.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: tokens.accent10.withValues(alpha: 0.3)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Background scans only run during IDX market hours '
                          '(09:00–15:00 WIB). Scans outside this window are '
                          'silently skipped.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _toggleBackgroundScan(
    BuildContext context,
    bool enabled,
    int intervalMinutes,
  ) {
    if (kIsWeb && enabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Background scans are not supported on the web.'),
        ),
      );
      return;
    }

    context.read<ConfigCubit>().setBackgroundScanEnabled(enabled);

    if (!kIsWeb) {
      if (enabled) {
        final notificationService = NotificationService();
        notificationService.initialize();
        notificationService.requestPermissions();
        Workmanager().registerPeriodicTask(
          '1',
          'backgroundScreenerTask',
          frequency: Duration(minutes: intervalMinutes),
        );
      } else {
        Workmanager().cancelAll();
      }
    }
  }
}
