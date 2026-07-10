import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../data/models/screener_result.dart';
import '../state/screener_cubit.dart';
import '../state/config_cubit.dart';
import 'theme/design_tokens.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final resultsBox = Hive.box<ScreenResult>('results_box');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Screener'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: BlocBuilder<ScreenerCubit, ScreenerState>(
        builder: (context, state) {
          if (state is ScreenerError) {
            return Center(
              child: Text(
                'Error: ${state.message}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          return Column(
            children: [
              // Connectivity banner
              const _ConnectivityBanner(),

              // Scan progress
              if (state is ScreenerScanning)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      if (state.total > 0)
                        LinearProgressIndicator(
                          value: state.completed / state.total,
                        )
                      else
                        const LinearProgressIndicator(),
                      const SizedBox(height: 8),
                      Text(
                        'Scanning universe... (${state.completed}/${state.total})',
                      ),
                    ],
                  ),
                ),

              // Results list
              Expanded(
                child: ValueListenableBuilder(
                  valueListenable: resultsBox.listenable(),
                  builder: (context, Box<ScreenResult> box, _) {
                    if (box.isEmpty) {
                      return const Center(
                        child: Text('No results yet. Tap Scan to begin.'),
                      );
                    }

                    final results = box.values.toList();
                    // Sort by change percent descending
                    results.sort(
                      (a, b) => b.changePercent.compareTo(a.changePercent),
                    );

                    return ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final result = results[index];
                        final tokens = Theme.of(context).extension<DesignTokens>()!;
                        
                        return Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: tokens.surface30,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: tokens.cardShadow,
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            title: Text(
                              result.symbol,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: tokens.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              'Change: ${result.changePercent.toStringAsFixed(2)}%',
                              style: TextStyle(
                                color: result.changePercent >= 0
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildSignalBadge(context, result.signal),
                                const SizedBox(height: 2),
                                _buildFreshnessBadge(context, result.freshResult),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final config = context.read<ConfigCubit>().state.config;
          context.read<ScreenerCubit>().runScan(symbols: config.universe);
        },
        label: const Text('Scan Now'),
        icon: const Icon(Icons.search),
      ),
    );
  }

  Widget _buildSignalBadge(BuildContext context, SignalTypeHive signal) {
    Color color;
    String text;
    switch (signal) {
      case SignalTypeHive.buy:
        color = const Color(0xFF10B981); // Emerald Green
        text = 'BUY';
        break;
      case SignalTypeHive.sell:
        color = const Color(0xFFEF4444); // Red
        text = 'SELL';
        break;
      case SignalTypeHive.neutral:
        color = const Color(0xFF94A3B8); // Slate
        text = 'NEUTRAL';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildFreshnessBadge(BuildContext context, FreshCheckResultHive result) {
    Color color;
    String text;
    switch (result) {
      case FreshCheckResultHive.fresh:
        color = const Color(0xFF3B82F6); // Blue
        text = 'FRESH';
        break;
      case FreshCheckResultHive.staleRepeat:
        color = const Color(0xFFF59E0B); // Amber
        text = 'STALE';
        break;
      case FreshCheckResultHive.insufficientHistory:
        color = const Color(0xFF64748B); // Slate
        text = 'NO HISTORY';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

/// Shows a banner when the device is offline and cached results are displayed.
class _ConnectivityBanner extends StatefulWidget {
  const _ConnectivityBanner();

  @override
  State<_ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<_ConnectivityBanner> {
  bool _isOffline = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Skip connectivity checks on web and in test environment
    if (!kIsWeb && !Platform.environment.containsKey('FLUTTER_TEST')) {
      _checkConnectivity();
      _timer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => _checkConnectivity(),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (mounted) {
        setState(() => _isOffline = result.isEmpty);
      }
    } on SocketException {
      if (mounted) {
        setState(() => _isOffline = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isOffline) return const SizedBox.shrink();

    final resultsBox = Hive.box<ScreenResult>('results_box');
    if (resultsBox.isEmpty) return const SizedBox.shrink();

    // Find the most recent result timestamp
    DateTime? lastScan;
    for (final result in resultsBox.values) {
      if (lastScan == null || result.timestamp.isAfter(lastScan)) {
        lastScan = result.timestamp;
      }
    }

    final timeStr = lastScan != null
        ? '${lastScan.hour.toString().padLeft(2, '0')}:${lastScan.minute.toString().padLeft(2, '0')} ${lastScan.day}/${lastScan.month}/${lastScan.year}'
        : 'unknown';

    return MaterialBanner(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Icon(
        Icons.cloud_off,
        color: Theme.of(context).colorScheme.error,
      ),
      content: Text('Showing cached results from $timeStr'),
      actions: [
        TextButton(
          onPressed: _checkConnectivity,
          child: const Text('Retry'),
        ),
      ],
    );
  }
}
