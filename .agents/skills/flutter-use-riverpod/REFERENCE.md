# Riverpod Reference — Patterns & Rules

## Package setup

```yaml
# pubspec.yaml
dependencies:
  flutter_riverpod: ^3.3.1
  riverpod_annotation: ^4.0.2

dev_dependencies:
  riverpod_generator: ^4.0.3
  riverpod_lint: ^3.0.0    # required — enforces best practices
  build_runner: ^2.4.0
  custom_lint: ^0.7.0
```

Enable riverpod_lint in `analysis_options.yaml`:
```yaml
analyzer:
  plugins:
    - custom_lint
```

**App Setup**: Wrap your app with `ProviderScope` directly in `runApp` — never inside `MyApp`.
```dart
void main() {
  runApp(const ProviderScope(child: MyApp()));
}
```

## Provider types with @riverpod

### 1. Simple computed value (replaces `Provider<T>`)

```dart
@riverpod
String greeting(Ref ref) {
  final name = ref.watch(userNameProvider);
  return 'Hello, $name!';
}
```

### 2. Async data (replaces `FutureProvider`)

```dart
@riverpod
Future<List<Activity>> activities(Ref ref) async {
  return ref.watch(activityRepositoryProvider).getAll();
}
```

### 3. Sync Notifier (replaces `NotifierProvider`)

```dart
@riverpod
class Counter extends _$Counter {
  @override
  int build() => 0;

  void increment() => state++;
  void reset() => state = 0;
}
```

### 4. Async Notifier (replaces `AsyncNotifierProvider`)

```dart
@riverpod
class Activities extends _$Activities {
  @override
  FutureOr<List<Activity>> build() async {
    return ref.watch(activityRepositoryProvider).getAll();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return ref.read(activityRepositoryProvider).getAll();
    });
  }
}
```

### 5. StreamProvider (for real-time streams only)

```dart
@riverpod
Stream<User?> authState(Ref ref) {
  return FirebaseAuth.instance.authStateChanges();
}
```

## Combining Providers
Use `ref.watch` to combine requests. It enables reactive and declarative logic.
For async providers, use `.future` to await the value if you need the resolved result:
```dart
@riverpod
Future<String> userGreeting(Ref ref) async {
  final user = await ref.watch(userProvider.future);
  return 'Hello, ${user.name}!';
}
```

## Mutations (experimental, codegen-only)

Use `@mutation` for side effects that need UI tracking (loading, error, success):

```dart
@riverpod
class TodoList extends _$TodoList {
  @override
  FutureOr<List<Todo>> build() async {
    return ref.watch(todoRepositoryProvider).getAll();
  }

  @mutation
  Future<List<Todo>> addTodo(String title) async {
    final newTodo = await ref.read(todoRepositoryProvider).create(title);
    return [...state.requireValue, newTodo];
  }
}
```

## Ref rules

### ref.watch — reactive subscription
Use during the build phase of a widget or provider to subscribe to changes.
Never call `ref.watch` inside callbacks, listeners, or Notifier methods.

### ref.read — one-time snapshot
Use in callbacks/Notifier methods (e.g., `onPressed`), not in `build()`.
Do not use `ref.read` inside `build()` to "optimize" rebuilds; it will lead to stale UI.

### ref.listen — side effects
Use in `build()` for navigation, snackbars, logging, etc.
It is safe to use `ref.listen` during the build phase; listeners are automatically cleaned up.

### ref.select — performance optimization
Subscribe to specific properties to optimize rebuilds.
```dart
// Only rebuilds when `price` changes
final price = ref.watch(productProvider.select((p) => p.price));
```

### ref.mounted / context.mounted — async safety
```dart
Future<void> save() async {
  final result = await someAsyncOperation();
  if (!ref.mounted) return; // For provider methods
  // OR
  if (!context.mounted) return; // For widget callbacks
  state = AsyncData(result);
}
```

## Auto Dispose & State Disposal

By default, with code generation, provider state is destroyed when the provider stops being listened to for a full frame.

### Lifecycles
- `ref.onDispose`: Register cleanup logic when state is destroyed. Do not trigger side effects or modify providers here. Call multiple times if needed (once per disposable object).
- `ref.onCancel`: React when the last listener is removed.
- `ref.onResume`: React when a new listener is added after cancellation.
- `ref.keepAlive()`: Fine-tune state disposal dynamically. Returns a function to revert back to autoDispose.

```dart
final provider = StreamProvider<int>((ref) {
  final controller = StreamController<int>();
  ref.onDispose(controller.close);
  return controller.stream;
});
```

### Invalidation
- `ref.invalidate(provider)`: Manually force destruction of a provider's state.
- `ref.invalidateSelf()`: Force a provider's own destruction and immediate recreation.

### Keep Alive (persistent state)
Use `@Riverpod(keepAlive: true)` to opt out of autoDispose entirely. Only use for:
- App-scoped singletons, auth state, or cached dependencies.

## Eager Initialization

Providers are lazy by default. To eagerly initialize a provider, read or watch it at the root of your application in a `Consumer` immediately under `ProviderScope`.

```dart
void main() {
  runApp(
    ProviderScope(
      child: EagerInitialization(
        child: MyApp(),
      ),
    ),
  );
}

class EagerInitialization extends ConsumerWidget {
  final Widget child;
  const EagerInitialization({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Eagerly initialize
    ref.watch(sharedPreferencesProvider);
    return child;
  }
}
```

## DI providers (dependency injection)

For injecting repositories, data sources, and services — use simple function providers with keepAlive:

```dart
@Riverpod(keepAlive: true)
StravaApiClient stravaApiClient(Ref ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  final httpClient = ref.watch(httpClientProvider);
  return StravaApiClient(tokenStorage: tokenStorage, client: httpClient);
}
```

## Testing

```dart
final container = ProviderContainer.test(
  overrides: [
    activityRepositoryProvider.overrideWithValue(MockActivityRepository()),
    activitiesProvider.overrideWithBuild((ref) async => [Activity.fake()]),
  ],
);
addTearDown(container.dispose);
```

## riverpod_lint rules

Enforce these key lint rules:
- `riverpod_avoid_read_inside_build`
- `riverpod_avoid_watch_outside_build`
- `riverpod_missing_provider_scope`
- `riverpod_avoid_manual_providers_as_generated_provider_dependency`
