---
name: flutter-bloc
description: Apply comprehensive BLoC and Cubit best practices for state management and forms in Flutter, tailored to a feature-first architecture. Use when implementing new BLoCs/Cubits, handling complex state flows, forms, or refactoring UI logic.
---

# Flutter BLoC Best Practices

## Quick start

To generate a new BLoC or Cubit following the mandatory directory structure and `part` directives, use the bundled utility script:
```bash
dart .gemini/config/skills/flutter-bloc/scripts/generate_bloc.dart <feature_name> <bloc_name> [--cubit]
```

## Workflows

### 1. Choosing Between BLoC and Cubit
- Use **Cubit** for simple, synchronous state changes (e.g., toggling a theme).
- Use **BLoC** for complex, asynchronous state changes, event buffering/transformers (e.g., `restartable()`, `droppable()`), or form handling.

### 2. Implementing State Management
- [ ] Use `part` and `part of` directives to keep State, Event, and Bloc in a single library scope.
- [ ] Create a dedicated sub-directory in `presentation/bloc/` for each BLoC (e.g., `bloc/auth/auth_bloc.dart`).
- [ ] Define **State** using `Equatable` and keep it immutable.
- [ ] Always emit a `Loading` state before async work.
- [ ] Implement **Zero-Logic UI**: Widgets MUST ONLY dispatch events and build UI based on state. Do not put business logic in widgets.

### 3. Form Handling Architecture
- [ ] Manage form state in a dedicated `FormBloc`—NOT in widget `setState`.
- [ ] Map each form field to a property in the BLoC state.
- [ ] Use pure validator functions from the domain layer (e.g., `String? validateEmail(String value)`).
- [ ] Emit `Submitting`, `Success`, and `Failure` form statuses explicitly.

## Advanced features

- For detailed architectural guidelines on FormBlocs and Directory Structure, see [REFERENCE.md](REFERENCE.md)
- For concrete implementation examples with `part` directives, see [EXAMPLES.md](EXAMPLES.md)
