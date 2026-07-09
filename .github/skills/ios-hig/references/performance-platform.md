# Performance & Platform Guidelines (Flutter on iOS)

## App Launch Time

- **Target:** Visible UI within 500ms of app launch. Users perceive delays >1s as "slow".
- **Optimize by:**
  - Deferring non-critical init (encryption service warmup, DB migrations) — show splash screen while these run.
  - Measuring time-to-first-frame:

```dart
// Measure launch performance during development
class _SplashScreenState extends State<SplashScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final duration = DateTime.now().difference(appStartTime);
      logger.debug('First frame rendered in ${duration.inMilliseconds}ms');
    });
  }
}
```

## Frame Rate & Smoothness

- **Target:** Consistent 60fps (120fps on ProMotion displays).
- Avoid jank in Flutter's rendering pipeline:

| Common Cause of Jank | Fix Strategy |
|---|---|
| Heavy computation in `build()` | Pre-compute values; cache results outside the widget tree |
| Deep widget trees with redundant rebuilds | Use `const` constructors; flatten hierarchy where possible |
| Excessive state updates | Scope Riverpod `Consumer`/`Selector` narrowly to specific state changes |

```dart
// ✅ const widgets skip rebuilds entirely
const SizedBox(height: 16);
const Text('Feeding Log', style: TextStyle(fontSize: 20));

// ❌ Rebuilt every time parent rebuilds — wastes CPU cycles
SizedBox(height: 16);
Text('Feeding Log', style: TextStyle(fontSize: 20));
```

## Rendering Best Practices

- **Prefer `RepaintBoundary`** around expensive widgets (charts, complex drawings) to isolate repaints.
- **Use `ListView.builder`** for long lists — never wrap many children in a Column without lazily loading.
- **Avoid `setState()` on root-level widgets** — scope state changes to the smallest subtree possible. Riverpod's `Selector` already handles this pattern.

```dart
// ✅ Lazy list — only builds visible items
ListView.builder(
  itemCount: feedings.length,
  itemBuilder: (context, index) => FeedingCard(feeding: feedings[index]),
)

// ❌ Builds ALL items at once — causes jank on large datasets
Column(
  children: feedings.map((f) => FeedingCard(feeding: f)).toList(),
)
```

## Memory & Battery

- mamadera is offline-first but still processes data (feedings, sleep logs). Keep background work minimal.
- **Never run location tracking, periodic sync, or background fetch** — mamadera doesn't need them.
- Dispose controllers and close streams in `dispose()` to prevent leaks:

```dart
@override
void dispose() {
  streamSubscription?.cancel();
  animationController.dispose();
  super.dispose();
}
```
