import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/models/screener_result.dart';
import '../state/screener_cubit.dart';
import 'config/config_screen.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final resultsBox = Hive.box<ScreenResult>('results_box');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Screener Results'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ConfigScreen()),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<ScreenerCubit, ScreenerState>(
        builder: (context, state) {
          if (state is ScreenerScanning) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Scanning universe...'),
                ],
              ),
            );
          }

          if (state is ScreenerError) {
            return Center(
              child: Text(
                'Error: ${state.message}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          // Use ValueListenableBuilder to reactively update when Hive changes
          return ValueListenableBuilder(
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
                        style: const TextStyle(fontWeight: FontWeight.bold),
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
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Trigger a scan
          context.read<ScreenerCubit>().runScan(
            symbols: [
              'BBCA.JK',
              'GOTO.JK',
              'TLKM.JK',
              'BUMI.JK',
              'AMMN.JK',
            ], // Dummy universe for now
          );
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
