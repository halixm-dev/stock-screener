# Schema-Driven Indicator Configuration UI

The core engine supports over 40 technical indicators. To avoid writing and maintaining 40+ custom Flutter forms, we will use a schema-driven UI approach for the `ConfigScreen`.

Each configurable indicator will define its parameters via metadata (e.g., parameter type, min/max bounds, default values). The `ConfigScreen` will dynamically render the appropriate UI elements (sliders, toggles) based on this schema. The `ConfigCubit` will serialize the entire user configuration as a JSON map and persist it in `SharedPreferences`, making the system easily extensible when new indicators are added to the pure Dart logic.
