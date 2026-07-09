# Interaction Guidelines (Flutter on iOS)

## Touch Targets

- **Minimum size:** 44×44 logical pixels for all tappable elements
- **Spacing:** At least 8 points between interactive controls to prevent accidental taps
- **Implementation in Flutter:**

```dart
// ✅ Good — explicit minimum size with IntrinsicWidth/Height or ConstrainedBox
ConstrainedBox(
  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
  child: CupertinoButton(...),
)

// ❌ Bad — small icon button without padding
Icon(Icons.delete, size: 20) // Too small to tap reliably
```

- For `IconButton`, use `minSize` and `padding`: `IconButton(minSize: const Size(44, 44), ...)`

## Navigation Patterns

| iOS Pattern | Flutter Equivalent | Notes |
|---|---|---|
| Navigation Bar (UINavigationBar) | `CupertinoNavigationBar` or `AppBar(forceMaterialTransparency: true)` | Back button should say "Back" + parent title, not just "<" |
| Tab Bar (UITabBarController) | `CupertinoTabScaffold` / `BottomNavigationBar(type: fixed, ...)` | 3–5 tabs max; icons with labels |
| Modal Sheet (UISheetPresentationStyle) | `showCupertinoModalPopup` or `Navigator.push` with custom transition | Dismissible by swipe-down on iPad |
| Page Sheets | `PageRouteBuilder` with slide-up animation | Use for secondary contexts that complement the main flow |

### Navigation Hierarchy Rules

- **No more than 3 levels deep** — if navigation goes deeper, reconsider your information architecture or use a master-detail layout
- **Back button behavior:** Always pops to previous screen; never dismisses multiple routes at once unless explicitly requested by user (e.g., "Done" in editing mode)
- **Swipe-back gesture:** Enable on iOS using `CupertinoPageTransitionsBuilder` — this is expected native behavior

```dart
// ✅ Swipe-back enabled automatically with CupertinoPageRoute
Navigator.push(
  context,
  CupertinoPageRoute(builder: (_) => DetailScreen()),
);
```

## Layout & Hierarchy

- **Safe areas:** Always wrap content in `SafeArea` to respect notch, home indicator, and status bar zones. On iOS 14+, the status bar is part of the safe area inset.
- **Content insets:** Use `AutomaticKeepAliveClientMixin` for scrollable lists that preserve position during navigation

```dart
// ✅ Safe area wrapper — critical on iPhone X+ devices
SafeArea(
  child: CupertinoPageScaffold(child: ...),
)
```

## Gestures

| Gesture | iOS Meaning | Flutter Implementation |
|---|---|---|
| Tap (single finger, short press) | Activate/select | `GestureDetector(onTap:)` or built-in widgets like `CupertinoButton` |
| Long Press | Contextual menu / reveal more options | `LongPressDetectable`, show popover with actions |
| Swipe Left on list item | Delete (destructive action) | `Dismissible` widget with red background confirmation |
| Pull-to-Refresh | Refresh data from server or reload state | `CupertinoSliverRefreshControl` inside scroll view |
