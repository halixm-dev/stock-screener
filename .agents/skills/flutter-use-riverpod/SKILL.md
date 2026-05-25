---
name: flutter-use-riverpod
description: Riverpod 3.x best practices with code generation (@riverpod), Notifier/AsyncNotifier patterns, mutations, testing, and provider organization. Use when creating providers, managing state with Riverpod, adding @riverpod annotations, migrating from manual providers, reviewing Riverpod usage, or fixing provider anti-patterns.
---

# Riverpod Best Practices (v3.x + riverpod_generator v4.x)

## Quick start

All new providers MUST use code generation:

```dart
// file: lib/presentation/providers/counter_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'counter_provider.g.dart';

@riverpod
class Counter extends _$Counter {
  @override
  int build() => 0;

  void increment() => state++;
}
```

Run codegen: `dart run build_runner build --delete-conflicting-outputs`

## Workflows

### Creating a new provider

- [ ] Choose provider type (see decision tree below)
- [ ] Create file in feature-appropriate directory under `lib/presentation/providers/`
- [ ] Add `part '<filename>.g.dart';` directive
- [ ] Annotate with `@riverpod` (autoDispose) or `@Riverpod(keepAlive: true)`
- [ ] Define provider as a top-level function or class extending `_$Name`
- [ ] Run `dart run build_runner build --delete-conflicting-outputs`
- [ ] Verify generated `.g.dart` file exists

### Provider Selection Decision Tree

| Need | Pattern |
|------|---------|
| Immutable/Computed Values | `@riverpod` function (e.g. `String apiKey(Ref ref)`) |
| Simple Synchronous State | `@riverpod class Name extends _$Name` with `build()` |
| Async Data + Mutations (PREFERRED) | `@riverpod class Name extends _$Name` with `FutureOr<T> build()` |
| Real-time Streams Only | `@riverpod Stream<T> name(Ref ref)` |
| Parameterized (family) | Add parameters to `build()` method |
| Global/persistent state | `@Riverpod(keepAlive: true)` |

### Consuming providers in widgets

- [ ] Use `ConsumerWidget` or `ConsumerStatefulWidget`
- [ ] `ref.watch(provider)` — in `build()` for reactive UI
- [ ] `ref.read(provider.notifier)` — in callbacks (`onPressed`, etc.)
- [ ] `ref.listen(provider, ...)` — in `build()` for side effects (navigation, snackbars)
- [ ] `.select()` — to watch a single property and optimize rebuilds (e.g. `ref.watch(userProvider.select((u) => u.name))`)
- [ ] After `await` in async callbacks, always check `context.mounted` before using `ref`

### Migrating a manual provider to codegen

- [ ] Replace `Provider<T>((ref) => ...)` with `@riverpod T name(Ref ref) => ...`
- [ ] Replace `NotifierProvider` class with `@riverpod class Name extends _$Name`
- [ ] Replace `AsyncNotifierProvider` class with `@riverpod class Name extends _$Name` + `FutureOr<T> build()`
- [ ] Replace `FutureProvider` with `@riverpod Future<T> name(Ref ref) async => ...`
- [ ] Add `part` directive, run build_runner
- [ ] Update all import sites

## Anti-patterns checklist

Before committing, verify:

- [ ] `ProviderScope` is directly in `runApp()`, not inside the `MyApp` widget
- [ ] No `ref.read()` in `build()` — use `ref.watch()` instead
- [ ] No side effects in provider `build()` — use `@mutation` or separate methods
- [ ] No god files (>15 providers per file) — split by domain
- [ ] No duplicate provider instances — share via DI chain
- [ ] No manual `isLoading` booleans — use `AsyncValue` or `@mutation`
- [ ] No stored `Ref` objects — always use `ref.mounted` after async gaps

## Advanced features

See [REFERENCE.md](REFERENCE.md) for:
- Eager initialization strategies
- Auto Dispose deep-dive & lifecycles (`onDispose`, `onCancel`)
- `@mutation` API for side effects
- Testing with `ProviderContainer.test()`
- Provider organization by feature

See [EXAMPLES.md](EXAMPLES.md) for complete code patterns.
