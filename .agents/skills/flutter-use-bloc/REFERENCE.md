# BLoC Architecture Reference

## Feature-First Architecture & Mandatory Directory Structure
BLoCs should be scoped to their specific feature module.
Every BLoC feature set MUST reside in its own sub-directory within the `bloc/` folder. Flat `bloc/` directories are STRICTLY prohibited.
```
lib/src/features/<feature_name>/
└── presentation/
    ├── bloc/
    │   └── <bloc_name>/
    │       ├── <bloc_name>_bloc.dart
    │       ├── <bloc_name>_event.dart
    │       └── <bloc_name>_state.dart
```

## Official BLoC Part-Part Of Pattern
Every `_bloc.dart` file MUST include its corresponding `_event.dart` and `_state.dart` files using `part` directives. Each event/state file MUST have a `part of` directive pointing back to the bloc file.

## State Design Principles
1. **Immutability:** States must be immutable. Use `Equatable` to ensure UI rebuilds only when data changes.
2. **Loading State Mandate:** ALWAYS emit `Loading` before async work, then `Success` or `Error`. Never skip the loading state.
3. **Zero-Logic UI:** Widgets MUST NOT contain business logic, orchestration logic, or direct calls to external services. They should ONLY dispatch events and build UI.

## Event Design Principles (BLoC)
1. **Naming:** Name events based on the *action* that occurred (e.g., `SignInButtonPressed`).
2. **Concurrency:** Use `transformers` (e.g., `restartable()`, `droppable()`) for events requiring debouncing (search) or throttling.

## Form Architecture with BLoC
- Manage form state in a dedicated `FormBloc`.
- Each form field maps to a property in the BLoC state.
- Emit `FormSubmitting`, `FormSuccess`, `FormError` states for submission flow.

**Form State:**
- Use a single state class with all field values, field-level errors, and form status:
  ```dart
  enum FormStatus { initial, submitting, success, failure }
  ```
- Field errors: `Map<String, String?>` keyed by field name (null means valid).

**Validation Patterns:**
- Validate in the domain layer, NOT in widgets or BLoCs.
- Create pure validator functions that return `String?` (null = valid, string = error message).

## Dependency Injection (DI)
Use a service locator like `get_it` combined with `BlocProvider`. BLoCs should generally be registered as a `Factory`.
