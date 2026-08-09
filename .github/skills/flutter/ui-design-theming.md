# Flutter UI Design & Theming Rules (Material 3)

## Visual Design Principles
* Build beautiful and intuitive user interfaces following modern design guidelines.
* **Typography:** Stress and emphasize font sizes to ease understanding (hero text, section headlines).
* **Background:** Apply subtle noise texture to the main background for a premium, tactile feel.
* **Shadows:** Multi-layered drop shadows create depth; cards have soft, deep shadow to look "lifted."
* **Icons:** Incorporate icons to enhance understanding and logical navigation.
* **Interactive Elements:** Buttons, checkboxes, sliders, lists, charts — use color + shadow for a subtle "glow" effect.

## Theming
* Define a centralized `ThemeData` for consistent application-wide style.
* Implement support for both light and dark themes using `theme` and `darkTheme`.
* Generate harmonious palettes from a single color using `ColorScheme.fromSeed`.

```dart
final ThemeData lightTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.deepPurple,
    brightness: Brightness.light,
  ),
);
```
