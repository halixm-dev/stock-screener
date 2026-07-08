import 'package:workmanager/workmanager.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../data/models/screener_result.dart';
import '../data/screener_service.dart';
import '../data/ticker_repository.dart';
import '../data/config_repository.dart';
import '../domain/ticker_filter.dart';
import 'notification_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // 1. Check Market Hours
    final now = DateTime.now().toUtc().add(
      const Duration(hours: 7),
    ); // WIB is UTC+7
    if (now.hour < 9 || now.hour >= 15) {
      return Future.value(true); // Silently abort outside 09:00 - 15:00 WIB
    }

    // 2. Initialize Dependencies
    await Hive.initFlutter();

    // Only register adapters if they haven't been registered yet
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(SignalTypeHiveAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ScreenResultAdapter());
    }

    final resultsBox = await Hive.openBox<ScreenResult>('results_box');
    final dedupBox = await Hive.openBox<bool>('dedup_box');
    final prefs = await SharedPreferences.getInstance();

    final configRepository = ConfigRepository(prefs);
    final repository = YahooFinanceTickerRepository();
    final filter = TickerFilter();

    final screenerService = ScreenerService(
      repository: repository,
      filter: filter,
      configRepository: configRepository,
      resultsBox: resultsBox,
    );

    // 3. Fetch Universe and Run Scan
    final tickers = await repository.fetchUniverse();
    final results = await screenerService.runScan(symbols: tickers);

    // 4. Filter Fresh and Deduplicate
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final freshSignals = <ScreenResult>[];

    for (final result in results) {
      if (!result.isFresh) continue;

      final dedupKey = '${result.symbol}_${result.signal.name}_$todayStr';
      if (!dedupBox.containsKey(dedupKey)) {
        freshSignals.add(result);
        await dedupBox.put(dedupKey, true);
      }
    }

    // 5. Notify if any fresh signals
    if (freshSignals.isNotEmpty) {
      final notificationService = NotificationService();
      await notificationService.initialize();
      await notificationService.showGroupedNotification(freshSignals);
    }

    return Future.value(true);
  });
}
