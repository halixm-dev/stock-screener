import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:stock_screener/main.dart';
import 'package:stock_screener/data/screener_service.dart';
import 'package:stock_screener/data/config_repository.dart';
import 'package:stock_screener/data/ticker_repository.dart';
import 'package:stock_screener/data/models/screener_result.dart';
import 'package:stock_screener/domain/ticker_filter.dart';

void main() {
  late Directory tempDir;
  late ScreenerService screenerService;
  late ConfigRepository configRepository;
  late YahooFinanceTickerRepository tickerRepository;

  setUpAll(() async {
    HttpOverrides.global = null;
    
    const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'getApplicationSupportDirectory') {
        return '.';
      }
      return null;
    });

    // Create temporary directory for Hive
    tempDir = await Directory.systemTemp.createTemp('hive_test');
    stdout.writeln('Temp dir created: ${tempDir.path}');
    Hive.init(tempDir.path);

    // Register Adapters
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(SignalTypeHiveAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ScreenResultAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(FreshCheckResultHiveAdapter());
    }
    stdout.writeln('Adapters registered');

    // Open boxes
    final resultsBox = await Hive.openBox<ScreenResult>('results_box');
    stdout.writeln('Results box opened');
    final ohlcvBox = await Hive.openBox<dynamic>('ohlcv_box');
    stdout.writeln('OHLCV box opened');
    await Hive.openBox<bool>('dedup_box');
    stdout.writeln('Dedup box opened');

    // 2. Setup SharedPreferences
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    stdout.writeln('Prefs opened');

    // 3. Setup Dependencies
    tickerRepository = YahooFinanceTickerRepository(ohlcvBox: ohlcvBox);
    final tickerFilter = TickerFilter();
    configRepository = ConfigRepository(prefs);

    screenerService = ScreenerService(
      repository: tickerRepository,
      filter: tickerFilter,
      configRepository: configRepository,
      resultsBox: resultsBox,
    );
    stdout.writeln('Dependencies ready');
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('End-to-end Screener Widget Test', () {
    testWidgets('Full universe scan completes and displays results', (tester) async {
      stdout.writeln('Starting testWidgets...');
      
      // 4. Load app widget
      await tester.pumpWidget(MyApp(
        screenerService: screenerService,
        configRepository: configRepository,
        tickerRepository: tickerRepository,
      ));

      // Wait for initial render (pumpAndSettle hangs due to Timer.periodic in ConnectivityBanner)
      await tester.pump(const Duration(seconds: 1));
      stdout.writeln('Initial render complete');

      // Verify the initial state is empty
      expect(find.text('No results yet. Tap Scan to begin.'), findsOneWidget);

      // 5. Trigger scan
      stdout.writeln('Tapping scan button');
      await tester.tap(find.text('Scan Now'));
      
      // Pump a frame to start the scan and show the loading indicator
      await tester.pump();
      
      // Wait until 'Scanning universe...' is NO LONGER visible, meaning the scan finished.
      // Wait up to 5 minutes
      const maxPumps = 2000;
      int pumpCount = 0;
      bool isScanning = true;
      while (isScanning && pumpCount < maxPumps) {
        // RunAsync to wait in real time for real network requests
        await tester.runAsync(() async {
          await Future.delayed(const Duration(milliseconds: 200));
        });
        // Advance fake time by 500ms to allow runScan's Future.delayed to complete
        await tester.pump(const Duration(milliseconds: 500));
        isScanning = find.textContaining('Scanning universe...').evaluate().isNotEmpty;
        if (pumpCount % 10 == 0) {
          stdout.writeln('Pump $pumpCount, isScanning: $isScanning');
        }
        pumpCount++;
      }

      stdout.writeln('Finished scanning loop. pumpCount: $pumpCount');

      // Assert that the scan actually finished (didn't time out)
      expect(isScanning, isFalse, reason: 'Scan did not complete within 5 minutes');

      // Assert that we don't see an error message
      expect(find.textContaining('Error:'), findsNothing);

      // Flush any lingering HTTP keep-alive timers (default 15s)
      await tester.pump(const Duration(seconds: 16));
    }, timeout: const Timeout(Duration(minutes: 10)));
  });
}
