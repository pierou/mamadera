# Visual Design Guidelines (Flutter on iOS)

## Colors

- **Use system colors** — they adapt to light/dark mode automatically and ensure consistency with the OS. In Flutter, prefer `CupertinoColors` for iOS builds:

```dart
// ✅ System-aware colors that shift in dark mode
CupertinoColors.systemBlue        // Primary actions
CupertinoColors.systemGreen       // Success states
CupertinoColors.systemRed         // Destructive / error
CupertinoColors.systemOrange      // Warnings
CupertinoColors.systemYellow      // Highlights (badges, stars)
CupertinoColors.systemPurple      // Accent color option
CupertinoColors.systemGray        // Secondary text/icons
CupertinoColors.separator         // Dividers between list items
```

- **Brand colors:** If you need a custom brand palette, define light AND dark variants:

```dart
// ✅ Dark-mode-aware custom theme
class MamaderaTheme {
  static const Color primaryLight = Color(0xFF4A90D9);
  static const Color primaryDark = Color(0xFF6AAAF0); // Lighter for dark bg
  
  static Color getPrimary(BuildContext context) => 
    Theme.of(context).brightness == Brightness.dark ? primaryDark : primaryLight;
}
```

## Materials & Elevation

- iOS uses subtle translucency and blur rather than heavy shadows. Use `CupertinoSliverNavigationBar.large` for large-title navigation with system blur effect.
- For cards, prefer flat backgrounds (`CupertinoColors.systemBackground`) over elevated surfaces — iOS design is moving toward flatter hierarchies.

## Contrast & Accessibility

| Element | Minimum WCAG AA Ratio | How to check in Flutter |
|---|---|---|
| Body text (≤18pt or ≤24pt bold) | 4.5:1 | `flutter test` with contrast checker, or Xcode accessibility inspector on device |
| Large text (>18pt or >14pt bold) | 3:0:1 | Same as above |
| UI components (buttons, inputs) | 3:0:1 against adjacent colors | Visual inspection + automated tools |

- **Test with "Reduce Transparency"** — if your app relies on translucent backgrounds, ensure content remains legible when the system disables transparency. Use `MediaQuery.platformBrightnessOf(context)` and test both modes in dev.

## Dark Mode Implementation

```dart
// ✅ Proper dark mode: use ThemeMode.system to follow OS setting
MaterialApp(
  theme: MamaderaTheme.light(),    // Light theme with CupertinoColors
  darkTheme: MamaderaTheme.dark(), // Dark variant — all colors inverted properly 
  themeMode: ThemeMode.system,     // Follows iOS Settings > Display & Brightness
)

// ❌ Hardcoded light mode ignores user preference
themeMode: ThemeMode.light,
```

- **Dark mode checklist:**
  - [ ] All text and icons visible against dark background (not pure white on pure black — use `CupertinoColors.label` for subtle anti-aliasing)
  - [ ] Images with transparency don't have light-only backgrounds showing through
  - [ ] Custom colors defined for both modes; no hardcoded hex values in widgets
