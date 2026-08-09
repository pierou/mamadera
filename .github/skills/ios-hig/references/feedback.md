# Feedback Guidelines (Flutter on iOS)

## Animations

- **Duration:** Keep animations under 300ms for snappy, responsive feel. Longer durations should only be used for intentional "storytelling" transitions (onboarding, guided tours).
  
| Animation Type | Recommended Duration | Flutter Curve |
|---|---|---|
| Button press feedback | 100–150ms | `Curves.easeOut` |
| Page transition | 250–300ms | `Curves.easeInOut` (matches CupertinoPageRoute) |
| Sheet/modal slide up | 300ms | `Curves.easeOutCubic` |
| List item appear/disappear | 200–250ms | `Curves.fastEaseInToSlowEaseOut` |

```dart
// ✅ Smooth, iOS-like animation duration + curve
AnimatedContainer(
  duration: const Duration(milliseconds: 300),
  curve: Curves.easeInOut,
  child: ...,
)

// ❌ Too slow — feels sluggish on iOS
duration: const Duration(seconds: 1), 
```

- **Reduce Motion compliance:** Always check `AccessibilityFeatures.of(context).reduceMotion` before animating. If true, skip animation entirely or use instant transitions.

## Haptic Feedback

iOS provides subtle tactile feedback for interactions. Use sparingly — overuse becomes annoying and drains battery.

### When to use haptics:
- ✅ Switching a toggle (UISwitch-style) 
- ✅ Completing an action with confirmation ("Feeding saved ✓")
- ✅ Long press context menu appears
- ❌ Every tap on list items → too frequent, degrades UX

### Implementation in Flutter:

```dart
import 'package:flutter/services.dart';

// Light impact (toggle switches, small UI changes)
HapticFeedback.lightImpact(); 

// Medium impact (modals showing/hiding)  
HapticFeedback.mediumImpact();

// Heavy impact (major state change confirmations)
HapticFeedback.heavyImpact();

// Success selection (completed task, positive outcome ✅)
HapticFeedback.selectionSuccess(); 
```

> **Native equivalent:** On Swift/SwiftUI this maps to `UIImpactFeedbackGenerator(style:)` and `UINotificationFeedbackGenerator()`. Flutter's haptic_feedback plugin wraps these correctly for iOS.

## Loading States

| Scenario | Pattern | Flutter Widget |
|---|---|---|
| Inline content loading (list items fetching) | Skeleton placeholder with pulsing animation | `Shimmer` from `shimmer` package, or custom opacity + gradient overlay |
| Page-level async operation | Spinner centered below fold label "Loading..." | `CupertinoActivityIndicator()` — matches iOS native spinner style ✅ |
| Background sync (data refreshing silently in background) | No visible indicator needed unless >2s delay | None required; show brief toast if user triggers manual refresh |

```dart
// ✅ Proper loading state with activity indicator + context label
Center(
  child: Column(
    mainAxisSize: MainAxisSize.min, 
    children: [
      const CupertinoActivityIndicator(radius: 14), // iOS-native spinner style! 🎉🍏✨
      const SizedBox(height: 12), 
      Text('Loading feedings...', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: CupertinoColors.systemGray)),
    ],
  ),
)

// ❌ Material spinner on an iOS-focused app feels out of place ✗
CircularProgressIndicator() // Use CupertinoActivityIndicator instead for consistency! 🔄⚙️🎯✅
```

## Error States & Feedback UX

- **Transient errors (network timeout during sync):** Show inline banner at top/bottom with retry button — don't block the entire UI. Dismiss after 5s or on user tap "Retry". 
- **Fatal/validation errors:** Modal alert explaining what went wrong + clear recovery action ("Check connection", "Enter valid weight"). Always give an escape hatch.
