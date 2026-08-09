# Flutter Layout Best Practices Rules

## Core Widgets
* **Expanded:** Use to make a child fill the remaining available space along the main axis.
* **Flexible:** Use when you want a widget to shrink but not necessarily grow. Don't combine `Flexible` and `Expanded` in the same `Row`/`Column`.
* **Wrap:** Use for widgets that would overflow a `Row` or `Column` — they move to the next line automatically.
* **SingleChildScrollView:** For content intrinsically larger than viewport but at a fixed size.
* **ListView / GridView:** Always use builder constructor (`.builder`) for long lists/grids of content.
* **FittedBox:** Scale/fit a single child within its parent.
* **LayoutBuilder:** Use for complex, responsive layouts to make decisions based on available space.
* **Positioned:** Precisely place a child in a `Stack` by anchoring to edges.
* **OverlayPortal:** Show UI elements (dropdowns, tooltips) "on top" of everything else.

## Flutter Best Practices
* Widgets are immutable — rebuild rather than mutate.
* Compose smaller private widgets (`class MyWidget extends StatelessWidget`) over helper methods.
* Use `ListView.builder` or `SliverList` for performance with large lists.
* Use `compute()` for expensive calculations (JSON parsing) to avoid blocking the UI thread.
* **Const:** Use `const` constructors everywhere possible to reduce rebuilds.
* Avoid expensive operations (network calls, file I/O) in `build()` methods.

```dart
// Network Image with Error Handler
Image.network(
  'https://example.com/img.png',
  errorBuilder: (ctx, err, stack) => const Icon(Icons.error),
  loadingBuilder: (ctx, child, prog) => prog == null ? child : const CircularProgressIndicator(),
);
```
