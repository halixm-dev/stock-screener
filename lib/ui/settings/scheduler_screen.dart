import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:workmanager/workmanager.dart';

import '../../application/notification_service.dart';
import '../../state/config_cubit.dart';
import '../../state/config_state.dart';

class SchedulerScreen extends StatelessWidget {
  const SchedulerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Schedule')),
      body: BlocBuilder<ConfigCubit, ConfigState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Enable / Disable Card ──
              Card(
                child: SwitchListTile(
                  title: const Text('Enable Background Scans'),
                  subtitle: const Text(
                    'Automatically scan during IDX market hours',
                  ),
                  value: state.isBackgroundScanEnabled,
                  onChanged: (enabled) => _toggleBackgroundScan(
                    context,
                    enabled,
                    state.config.scanIntervalMinutes,
                  ),
                ),
              ),

              // ── Interval Card ──
              if (state.isBackgroundScanEnabled)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scan Interval',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
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
              const SizedBox(height: 8),
              Card(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
