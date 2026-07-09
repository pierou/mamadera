# Flutter State Management Rules

## Guidelines
* **Native-First:** Prefer `ValueNotifier`, `ChangeNotifier`, `ListenableBuilder`.
* **Restrictions:** Do NOT use Bloc or GetX unless explicitly requested. Riverpod is allowed if the project already uses it (see [AGENTS.md](../../README.md) for project-specific overrides).
* **ChangeNotifier:** For state that is more complex or shared across multiple widgets, use `ChangeNotifier`.
* **MVVM:** When a more robust solution is needed, structure the app using the Model-View-ViewModel pattern.
* **Dependency Injection:** Use simple manual constructor dependency injection to make dependencies explicit in APIs and manage layers.

## Example: Simple Local State
```dart
final ValueNotifier<int> _counter = ValueNotifier<int>(0);
ValueListenableBuilder<int>(
  valueListenable: _counter,
  builder: (context, value, child) => Text('Count: $value'),
);
```
