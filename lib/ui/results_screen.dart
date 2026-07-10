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
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            title: Text(
                              result.symbol,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
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
                              children: [
                                _buildSignalBadge(result.signal),
                                const SizedBox(height: 4),
                                _buildFreshnessBadge(result.freshResult),
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

  Widget _buildSignalBadge(SignalTypeHive signal) {
    Color color;
    String text;
    switch (signal) {
      case SignalTypeHive.buy:
        color = Colors.green;
        text = 'BUY';
        break;
      case SignalTypeHive.sell:
        color = Colors.red;
        text = 'SELL';
        break;
      case SignalTypeHive.neutral:
        color = Colors.grey;
        text = 'NEUTRAL';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildFreshnessBadge(FreshCheckResultHive result) {
    Color color;
    String text;
    switch (result) {
      case FreshCheckResultHive.fresh:
        color = Colors.blue;
        text = 'FRESH';
        break;
      case FreshCheckResultHive.staleRepeat:
        color = Colors.orange;
        text = 'STALE';
        break;
      case FreshCheckResultHive.insufficientHistory:
        color = Colors.grey;
        text = 'NO HISTORY';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 10,
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
    // Skip connectivity checks on web
    if (!kIsWeb) {
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
