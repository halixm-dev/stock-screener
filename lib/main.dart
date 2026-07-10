import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:workmanager/workmanager.dart';

import 'application/background_task.dart';
import 'data/models/screener_result.dart';
import 'data/screener_service.dart';
import 'data/ticker_repository.dart';
import 'data/config_repository.dart';
import 'domain/ticker_filter.dart';
import 'state/screener_cubit.dart';
import 'state/config_cubit.dart';
import 'ui/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    Workmanager().initialize(callbackDispatcher);
  }

  // Initialize Hive
  await Hive.initFlutter();

  // Register Adapters
  Hive.registerAdapter(SignalTypeHiveAdapter());
  Hive.registerAdapter(ScreenResultAdapter());

  // Open boxes
  final resultsBox = await Hive.openBox<ScreenResult>('results_box');
  final ohlcvBox = await Hive.openBox<dynamic>('ohlcv_box');
  await Hive.openBox<bool>('dedup_box');

  // Setup SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Setup Dependencies
  final tickerRepository = YahooFinanceTickerRepository(ohlcvBox: ohlcvBox);
  final tickerFilter = TickerFilter();
  final configRepository = ConfigRepository(prefs);

  final screenerService = ScreenerService(
    repository: tickerRepository,
    filter: tickerFilter,
    configRepository: configRepository,
    resultsBox: resultsBox,
  );

  runApp(
    MyApp(
      screenerService: screenerService,
      configRepository: configRepository,
      tickerRepository: tickerRepository,
    ),
  );
}

class MyApp extends StatelessWidget {
  final ScreenerService screenerService;
  final ConfigRepository configRepository;
  final TickerRepository tickerRepository;

  const MyApp({
    super.key,
    required this.screenerService,
    required this.configRepository,
    required this.tickerRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<TickerRepository>.value(value: tickerRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                ScreenerCubit(screenerService: screenerService),
          ),
          BlocProvider(
            create: (context) => ConfigCubit(configRepository)..loadConfig(),
          ),
        ],
        child: MaterialApp.router(
          title: 'Stock Screener',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          routerConfig: router,
        ),
      ),
    );
  }
}
