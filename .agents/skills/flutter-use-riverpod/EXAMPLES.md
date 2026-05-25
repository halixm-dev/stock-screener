# Riverpod Examples

## Example 1: Migrate a manual Provider to codegen

### Before (manual)
```dart
final httpClientProvider = Provider<Client>((ref) {
  final client = Client();
  ref.onDispose(client.close);
  return client;
});
```

### After (codegen)
```dart
@Riverpod(keepAlive: true)
Client httpClient(Ref ref) {
  final client = Client();
  ref.onDispose(client.close);
  return client;
}
```

---

## Example 2: Migrate a manual AsyncNotifier to codegen

### Before (manual)
```dart
class HrPreferencesNotifier extends AsyncNotifier<HrPreferences> {
  @override
  FutureOr<HrPreferences> build() async {
    final storage = ref.watch(preferencesStorageProvider);
    return storage.loadHrPreferences();
  }

  Future<void> saveRestingHr(int hr) async {
    state = await AsyncValue.guard(() async {
      final storage = ref.read(preferencesStorageProvider);
      await storage.saveRestingHr(hr);
      return state.requireValue.copyWith(restingHr: hr);
    });
  }
}

final hrPreferencesProvider =
    AsyncNotifierProvider<HrPreferencesNotifier, HrPreferences>(
  HrPreferencesNotifier.new,
);
```

### After (codegen)
```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'hr_preferences_provider.g.dart';

@riverpod
class HrPreferences extends _$HrPreferences {
  @override
  FutureOr<HrPreferencesState> build() async {
    final storage = ref.watch(preferencesStorageProvider);
    return storage.loadHrPreferences();
  }

  Future<void> saveRestingHr(int hr) async {
    state = await AsyncValue.guard(() async {
      final storage = ref.read(preferencesStorageProvider);
      await storage.saveRestingHr(hr);
      return state.requireValue.copyWith(restingHr: hr);
    });
  }
}
```

---

## Example 3: Migrate a manual FutureProvider to codegen

### Before (manual)
```dart
final runningStatsProvider = FutureProvider<RunningStats>((ref) async {
  final activities = await ref.watch(activitiesProvider.future);
  final prefs = await ref.watch(hrPreferencesProvider.future);
  return _calculateStats(activities, prefs);
});
```

### After (codegen)
```dart
@riverpod
Future<RunningStats> runningStats(Ref ref) async {
  final activities = await ref.watch(activitiesProvider.future);
  final prefs = await ref.watch(hrPreferencesProvider.future);
  return _calculateStats(activities, prefs);
}
```

---

## Example 4: Auth notifier with async initialization

### Anti-pattern (sync Notifier with fire-and-forget async)
```dart
// ❌ BAD: Async side effect in synchronous build()
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _checkAuthStatus(); // Fire-and-forget — no loading state!
    return const AuthState.unknown();
  }
}
```

### Correct (AsyncNotifier)
```dart
// ✅ GOOD: Properly models loading/error/data
@riverpod
class Auth extends _$Auth {
  @override
  FutureOr<AuthStatus> build() async {
    final tokenStorage = ref.watch(tokenStorageProvider);
    final hasToken = await tokenStorage.hasValidToken();
    if (!hasToken) return AuthStatus.unauthenticated;

    // Optionally sync profile
    final profile = await ref.read(stravaApiClientProvider).getAthlete();
    return AuthStatus.authenticated(profile);
  }

  Future<void> login() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(stravaApiClientProvider).authenticate();
      return AuthStatus.authenticated(
        await ref.read(stravaApiClientProvider).getAthlete(),
      );
    });
  }

  Future<void> logout() async {
    await ref.read(tokenStorageProvider).clear();
    ref.invalidateSelf();
  }
}
```

---

## Example 5: Using @mutation for side effects

```dart
@riverpod
class Activities extends _$Activities {
  @override
  FutureOr<List<Activity>> build() async {
    return ref.watch(activityRepositoryProvider).getAll();
  }

  /// Syncs activities from Strava API.
  /// UI can track this independently via ref.watch(activitiesProvider.sync)
  @mutation
  Future<List<Activity>> sync() async {
    final repo = ref.read(activityRepositoryProvider);
    await repo.syncFromStrava();
    return repo.getAll();
  }
}

// In widget:
class ActivityListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activities = ref.watch(activitiesProvider);
    final syncStatus = ref.watch(activitiesProvider.sync);

    return Scaffold(
      body: activities.when(
        data: (list) => ListView.builder(
          itemCount: list.length,
          itemBuilder: (_, i) => ActivityTile(list[i]),
        ),
        loading: () => const CircularProgressIndicator(),
        error: (e, st) => ErrorWidget(e),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: syncStatus.isPending
            ? null
            : () => ref.read(activitiesProvider.notifier).sync(),
        child: syncStatus.isPending
            ? const CircularProgressIndicator()
            : const Icon(Icons.sync),
      ),
    );
  }
}
```

---

## Example 6: Widget consumption patterns

```dart
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ ref.watch — reactive, rebuilds on change
    final stats = ref.watch(runningStatsProvider);
    final athleteName = ref.watch(athleteNameProvider);

    // ✅ ref.listen — side effect on state change
    ref.listen(authProvider, (prev, next) {
      next.whenOrNull(
        error: (e, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Auth error: $e')),
        ),
      );
    });

    // ✅ .select — only rebuild when name changes
    final name = ref.watch(
      userProfileProvider.select((profile) => profile.displayName),
    );

    return Scaffold(
      appBar: AppBar(title: Text('Welcome, $name')),
      body: stats.when(
        data: (data) => StatsGrid(data),
        loading: () => const ShimmerLoading(),
        error: (e, st) => RetryWidget(
          error: e,
          // ✅ ref.read — one-time action in callback
          onRetry: () => ref.read(activitiesProvider.notifier).refresh(),
        ),
      ),
    );
  }
}
```

---

## Example 7: Testing an AsyncNotifier

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:riverpod/riverpod.dart';

@GenerateMocks([ActivityRepository])
import 'activities_test.mocks.dart';

void main() {
  late MockActivityRepository mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockActivityRepository();
    container = ProviderContainer.test(
      overrides: [
        activityRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
    addTearDown(container.dispose);
  });

  test('build loads activities', () async {
    when(mockRepo.getAll()).thenAnswer((_) async => [Activity.fake()]);

    // Wait for the async provider to resolve
    await container.read(activitiesProvider.future);

    final state = container.read(activitiesProvider);
    expect(state.requireValue, hasLength(1));
  });

  test('refresh reloads activities', () async {
    when(mockRepo.getAll()).thenAnswer((_) async => []);

    await container.read(activitiesProvider.future);
    expect(container.read(activitiesProvider).requireValue, isEmpty);

    when(mockRepo.getAll()).thenAnswer((_) async => [Activity.fake()]);
    await container.read(activitiesProvider.notifier).refresh();

    expect(container.read(activitiesProvider).requireValue, hasLength(1));
  });
}
```

---

## Example 8: Debouncing a search provider

```dart
@riverpod
Future<List<Activity>> searchActivities(
  Ref ref,
  String query,
) async {
  // Cancel if params change within 300ms
  await Future.delayed(const Duration(milliseconds: 300));
  if (!ref.mounted) return [];

  if (query.isEmpty) return [];

  final repo = ref.watch(activityRepositoryProvider);
  return repo.search(query);
}
```

---

## Example 9: Pull-to-refresh

```dart
class ActivityListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activities = ref.watch(activitiesProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(activitiesProvider.future),
      child: activities.when(
        data: (list) => ListView.builder(
          itemCount: list.length,
          itemBuilder: (_, i) => ActivityTile(list[i]),
        ),
        loading: () => const CircularProgressIndicator(),
        error: (e, _) => Text('Error: $e'),
      ),
    );
  }
}
```
