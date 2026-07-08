---
trigger: always_on
---

# AI Rules for Flutter

## Persona & Tools
* **Role:** Expert Flutter Developer. Focus: Beautiful, performant, maintainable code.
* **Explanation:** Explain Dart features (null safety, streams, futures) for new users.
* **Tools:** ALWAYS run `dart_format`. Use `dart_fix` for cleanups. Use `analyze_files` with `flutter_lints` and `riverpod_lint` to catch errors early.
* **Dependencies:** Add with `flutter pub add`. Use `pub_dev_search` for discovery. Explain why a package is needed.

## Architecture & Structure
* **Entry:** Standard `lib/main.dart`.
* **Layers:** Presentation (Widgets), Domain (Logic/Notifiers), Data (Repo/API).
* **Features:** Group by feature (e.g., `lib/features/login/`) for scalable apps.
* **SOLID:** Strictly enforced.
* **State Management (Riverpod 3.x):**
  * **App State:** Use `Riverpod` with code generation (`@riverpod`, `Notifier`, `AsyncNotifier`) for ALL dependency injection and app state.
  * **Local State:** Use built-in `ValueNotifier` ONLY for simple, local ephemeral UI state.
  * **Providers:** Place Riverpod providers in `lib/presentation/providers/`.

## Code Style & Quality
* **Naming:** `PascalCase` (Types), `camelCase` (Members), `snake_case` (Files).
* **Conciseness:** Functions <50 lines. Avoid verbosity.
* **Null Safety:** NO `!` operator. Use `?` and flow analysis (e.g. `if (x != null)`).
* **Async:** Use `async/await` for Futures. Catch all errors with `try-catch`.
* **Logging:** Use `dart:developer` `log()` locally for structured logging (include name, error, stackTrace). NEVER use `print`.
* **Comments:** Use concise `///` doc comments for all public APIs explaining the "why". Avoid useless repetition.

## Flutter Best Practices
* **Build Methods:** Keep pure and fast. Break complex builds into private `class MyWidget extends StatelessWidget`.
* **Isolates:** Use `compute()` for heavy tasks like JSON parsing.
* **Lists:** `ListView.builder` or `SliverList` for lazy-loaded performance.
* **Immutability:** `const` constructors everywhere. `StatelessWidget` preference.

## Routing (GoRouter)
Use `go_router` exclusively for declarative deep linking and web support.

```dart
final _router = GoRouter(routes: [
  GoRoute(path: '/', builder: (_, __) => const Home()),
  GoRoute(path: 'details/:id', builder: (_, s) => Detail(id: s.pathParameters['id']!)),
]);
MaterialApp.router(routerConfig: _router);
```

## Data (Freezed & JSON)
Use `freezed` for immutable models/state and `json_serializable` for JSON parsing. Apply `fieldRename: FieldRename.snake`.

```dart
@freezed
class User with _$User {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory User({
    required String name,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

## Visual Design (Material 3 & Premium Aesthetics)
* **Aesthetics:** Premium, custom look. Avoid default blue. Use the 60-30-10 color rule.
* **Texture & Depth:** Apply subtle noise textures to backgrounds. Use multi-layered soft, deep drop shadows for cards. Add color glow effects to interactive elements.
* **Theme:** Use `ThemeData` with `ColorScheme.fromSeed`. Support Light & Dark modes (`ThemeMode.system`).
* **Typography:** `google_fonts`. Prioritize legibility. Establish a clear type scale and line-height (1.4x-1.6x).
* **Layout:** `LayoutBuilder` for responsiveness. `OverlayPortal` for popups.
* **Components:** Use `ThemeExtension` for custom design tokens (colors/sizes).

## Testing
* **Tools:** `flutter test` (Unit), `flutter_test` (Widget), `integration_test` (E2E).
* **Mocks:** Prefer Fakes/Stubs. Use `mockito` sparingly. Avoid generating mocks for state management.
* **Pattern:** Arrange-Act-Assert.
* **Assertions:** Use `package:checks` for expressive assertions.

## Accessibility (A11Y)
* **Contrast:** 4.5:1 minimum for text.
* **Touch Targets:** Minimum 44×44pt (iOS) / 48×48dp (Android). Use `constraints: BoxConstraints(minWidth: 44, minHeight: 44)` on icon buttons.
* **Tooltips & Semantics:** All icon buttons must have `tooltip` and/or `semanticLabel`. Label all interactive elements specifically.
* **Empty States:** Provide helpful messaging and a clear action. Never just "No data" text.
* **Scale:** Test dynamic font sizes (up to 200%).
* **Screen Readers:** Verify with TalkBack/VoiceOver.

## Commands Reference
* **Build Runner:** `dart run build_runner build --delete-conflicting-outputs`
* **Test:** `flutter test .`
* **Analyze:** `flutter analyze .`