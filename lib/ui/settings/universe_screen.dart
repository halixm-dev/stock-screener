import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../state/config_cubit.dart';
import '../../state/config_state.dart';
import '../theme/design_tokens.dart';

/// Screen for choosing which stock universe the screener should scan.
class UniverseScreen extends StatelessWidget {
  const UniverseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Stock Universe')),
      body: BlocBuilder<ConfigCubit, ConfigState>(
        builder: (context, state) {
          final config = state.config;
          final preset = config.universePreset;
          final tokens = Theme.of(context).extension<DesignTokens>()!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Preset Selector Card ──
              Container(
                decoration: BoxDecoration(
                  color: tokens.surface30,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: tokens.cardShadow,
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Universe Preset', 
                      style: textTheme.titleMedium?.copyWith(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                              value: 'lq45',
                              label: Text('LQ45'),
                              icon: Icon(Icons.trending_up),
                            ),
                            ButtonSegment(
                              value: 'idx80',
                              label: Text('IDX80'),
                              icon: Icon(Icons.show_chart),
                            ),
                            ButtonSegment(
                              value: 'custom',
                              label: Text('Custom'),
                              icon: Icon(Icons.edit),
                            ),
                          ],
                          selected: {preset},
                          onSelectionChanged: (newSelection) {
                            final selected = newSelection.first;
                            context.read<ConfigCubit>().updateConfig(
                              config.copyWith(
                                universePreset: selected,
                                universe: selected == 'custom'
                                    ? config.universe
                                    : const [],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // ── Preset Info Card (LQ45 / IDX80) ──
              if (preset == 'lq45' || preset == 'idx80')
                Container(
                  decoration: BoxDecoration(
                    color: tokens.accent10.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: tokens.accent10.withValues(alpha: 0.3)),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: tokens.accent10,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(
                            preset == 'lq45'
                                ? 'Top 45 most liquid IDX stocks. '
                                    'Universe is fetched automatically.'
                                : 'Top 80 IDX stocks by market cap and '
                                    'liquidity. Universe is fetched '
                                    'automatically.',
                            style: textTheme.bodyMedium?.copyWith(
                              color: tokens.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

              // ── Custom Tickers Card ──
              if (preset == 'custom') ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Custom Tickers', style: textTheme.titleMedium),
                        const SizedBox(height: 12),
                        TextFormField(
                          initialValue: config.universe.join(', '),
                          decoration: const InputDecoration(
                            labelText: 'Tickers (comma separated)',
                            hintText: 'e.g. BBCA, BMRI, TLKM',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 4,
                          onChanged: (value) {
                            final tickers = value
                                .split(',')
                                .map((t) => t.trim().toUpperCase())
                                .where((t) => t.isNotEmpty)
                                .toList();
                            context.read<ConfigCubit>().updateConfig(
                              config.copyWith(universe: tickers),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${config.universe.length} tickers configured',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
