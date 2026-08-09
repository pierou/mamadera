# Content Guidelines (Flutter on iOS)

## Empty States

- **Purpose:** Explain what's missing and guide the user to take action — never leave a blank screen that feels broken.
- **Components of a good empty state:**
  - Illustration or icon related to the content type
  - Clear title: "No feedings recorded yet" (not just "Empty")
  - Action button with label matching the primary task: "Record First Feeding"

```dart
// ✅ Good empty state — informative + actionable
Center(
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(CupertinoIcons.feedbag, size: 64, color: CupertinoColors.systemGray),
      const SizedBox(height: 16),
      Text('No feedings yet', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      Text(
        'Tap the button below to record your first feeding.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: CupertinoColors.systemGray),
      ),
      const SizedBox(height: 24),
      ElevatedButton.icon(icon: Icon(Icons.add), label: Text('Record Feeding'), onPressed: ...),
    ],
  ),
)
```

## Writing Copy for iOS

- **Sentence case** — Title Case only for app names and feature headings. Body text, button labels, error messages use sentence case.
- **Concise & action-oriented:** "Save Changes" (not "Click here to save your changes")
- **Error messages explain the problem AND offer a solution:**

| ❌ Bad | ✅ Good |
|---|---|
| "Something went wrong." | "Unable to sync data. Check your connection and try again." |
| "Invalid input" | "Please enter a valid weight (e.g., 3.5 kg)" |
| "Operation failed" | "Feeding wasn't saved. Tap Undo to retry." |

- **Use the user's language:** Say "baby" or "your baby", not "subject". Match tone of your app — warm and supportive for a parenting tracker.

## Typography & Text Hierarchy

- iOS uses SF Pro system font by default; in Flutter, `TextStyle()` without specifying fontFamily will use it automatically on iOS builds ✅
- **Text styles hierarchy** (use Flutter's built-in text theme):

```dart
// Use predefined text styles — they map to iOS type scales
Theme.of(context).textTheme.displayLarge   // ~34pt — hero titles
Theme.of(context).textTheme.headlineMedium  // ~28pt — page headers
Theme.of(context).textTheme.titleLarge      // ~20pt — section titles
Theme.of(context).textTheme.bodyLarge       // ~17pt — default body text ✅ most common size
Theme.of(context).textTheme.bodyMedium      // ~15pt — secondary content
Theme.of(context).textTheme.bodySmall       // ~13pt — captions, metadata
```

- **Never hardcode font sizes.** Use `TextScaler` to scale with system settings:

```dart
// ✅ Respects Dynamic Type (user's font size preference)
MediaQuery.textScalerOf(context).scale(17.0) // or just use text styles which auto-scale

// ❌ Fixed size — ignores accessibility settings
TextStyle(fontSize: 14) 
```
