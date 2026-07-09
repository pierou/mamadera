# Accessibility Guidelines (Flutter on iOS)

## VoiceOver Support

VoiceOver is the screen reader built into iOS. Every interactive element must be accessible to it.

### Semantics Widget — Flutter's accessibility bridge

```dart
// ✅ Custom control with proper VoiceOver label + hint
Semantics(
  label: 'Baby weight',           // Read aloud by VoiceOver
  hint: 'Double tap to edit your baby current weight in kilograms.', // What happens on interaction
  child: Container(...),
)

// ❌ Naked widget — VoiceOver sees "Container" or nothing useful
Container(...)
```

### Built-in widgets are already accessible ✅

- `Text`, `CupertinoButton`, `ElevatedButton`, `CheckboxListTile` have default semantics. Override only when the auto-generated label is insufficient:

```dart
// Button text IS the accessibility label — no extra Semantics needed ✅
CupertinoButton(child: Text('Save')) 

// But if using an icon-only button, add a label explicitly ✅
Semantics(
  label: 'Delete feeding entry',
  child: IconButton(icon: Icon(CupertinoIcons.delete), onPressed: ...),
)
```

### Grouping related content

```dart
// ✅ Groups "date" + "time" as one VoiceOver item (not two separate taps to read both together)
Semantics(
  container: true, // Merges children into single accessible element
  child: Row(
    children: [Text('2024-01-15'), Text('•'), Text('03:45 AM')],
  ),
)
```

## Dynamic Type (Font Scaling)

iOS allows users to increase font size in Settings > Accessibility > Display & Text Size. Your app must support it.

### Implementation with TextScaler (Flutter ≥ 3.16)

```dart
// ✅ Respects user's dynamic type setting via MediaQuery.textScalerOf(context).scale(size); 
Text('Feeding Log', style: Theme.of(context).textTheme.titleLarge // Auto-scales!
)

// ❌ Fixed-size text — ignores Dynamic Type completely
Text('Feeding Log', style: TextStyle(fontSize: 20)) 

```

### Testing Dynamic Type in Flutter

1. On device/simulator: Settings > Accessibility > Display & Text Size > Larger Text (enable up to "Extra Extra Large")
2. Verify no text truncation or overflow occurs at maximum scale factor (~3x normal)
3. Use `FittedText` for titles that might not fit in available space

## Reduce Motion

Some users prefer reduced animations due to vestibular disorders. iOS provides a system-wide toggle: Settings > Accessibility > Motion > Reduce Motion.

```dart
// ✅ Check for reduce motion preference before animating
final bool reduceMotion = MediaQuery.of(context).accessibleNavigation || 
    (Platform.isIOS && _getReduceMotionStatus()); // Requires platform channel or use built-in detection

if (!reduceMotion) {
  AnimatedContainer(duration: Duration(milliseconds: 300), curve: Curves.easeInOut, child: ...);
} else {
  Container(child: ...) // Instant transition — no animation for users who prefer it
}
```

> **Note:** Flutter's `AccessibilityFeatures.of(context).reduceMotion` is the canonical way to detect this on iOS. Use it instead of manual platform channels.

## Other Accessibility Features

| Feature | What It Is | How To Support in Flutter |
|---|---|---|
| **Bold Text** | Thicker font weights for readability | Use `Theme.of(context).textTheme` — auto-respects system weight settings |
| **Increase Contrast** | Boosts contrast ratios beyond minimum WCAG AA | Test with Xcode accessibility inspector; ensure all text/icons meet ≥4.5:1 even at "increased" level |
| **Color Filters (Grayscale, Invert)** | Alters color perception for visual impairments | Don't rely on color alone to convey meaning — use icons + labels together |
