import 'package:go_router/go_router.dart';

import 'results_screen.dart';
import 'config/indicator_config_screen.dart';
import 'settings/settings_screen.dart';
import 'settings/scheduler_screen.dart';
import 'settings/universe_screen.dart';

/// Application route configuration using GoRouter.
final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const ResultsScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/settings/indicators',
      builder: (context, state) => const IndicatorConfigScreen(),
    ),
    GoRoute(
      path: '/settings/schedule',
      builder: (context, state) => const SchedulerScreen(),
    ),
    GoRoute(
      path: '/settings/universe',
      builder: (context, state) => const UniverseScreen(),
    ),
  ],
);
