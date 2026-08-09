---
name: ios-hig
description: Use when designing iOS interfaces, implementing accessibility (VoiceOver, Dynamic Type), handling dark mode, ensuring adequate touch targets, providing animation/haptic feedback, or requesting user permissions. Apple Human Interface Guidelines for iOS compliance — adapted for Flutter/Cupertino widgets.
argument-hint: '--platform=ios'
---

# iOS Human Interface Guidelines (Flutter)

Apple's Human Interface Guidelines define the visual language, interaction patterns, and accessibility standards that make iOS apps feel native and intuitive. The core principle: **clarity and consistency through thoughtful design**.

This skill adapts HIG principles for Flutter apps targeting iOS — using `Cupertino*` widgets where appropriate, respecting system settings (Dynamic Type, Dark Mode, Reduce Motion), and ensuring App Store review compliance.

## Overview

- **[Interaction](references/interaction.md)** - Touch targets, navigation, layout, hierarchy
- **[Content](references/content.md)** - Empty states, writing copy, typography
- **[Visual Design](references/visual-design.md)** - Colors, materials, contrast, dark mode
- **[Accessibility](references/accessibility.md)** - VoiceOver, Dynamic Type, Reduce Motion
- **[Feedback](references/feedback.md)** - Animations, haptics, loading states, errors
- **[Performance](references/performance-platform.md)** - Responsiveness, system components
- **[Privacy](references/privacy-permissions.md)** - Permission requests, data handling

## Common Mistakes

1. **Touch targets smaller than 44×44 points** — Buttons and interactive elements must be at least 44×44 logical pixels to accommodate thumbs. Smaller targets cause frustrated users and accessibility failures.

2. **Ignoring Dynamic Type constraints** - Text with fixed sizes doesn't respect user accessibility settings. Use `TextScaler` (Flutter 3.16+) or `MediaQuery.textScaleFactor`, test with Large/Extra Large settings, avoid hardcoded font sizes.

3. **Insufficient color contrast in dark mode** — Colors that work in light mode may fail WCAG AA in dark mode. Test both modes; aim for ≥4.5:1 ratio for body text.

4. **Over-animating transitions** — Animations smooth at 60 fps can trigger motion sickness for users with vestibular issues. Respect `MediaQuery.disableAnimations` (Reduce Motion) and keep animations under 300 ms.

5. **Missing Semantics labels on custom controls** — Custom buttons, toggles, or interactive views need `Semantics(label: ..., hint: ...)` or they're unusable to VoiceOver users.

6. **Haptic overuse** — Every action does NOT need haptic feedback. Reserve for confirmations (purchase, critical action) and errors. Excessive haptics are annoying and drain battery.
