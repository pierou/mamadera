import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Displays a success feedback snackbar with haptic touch confirmation.
///
/// Uses the app's [SnackBarThemeData] for consistent styling across light/dark modes.
/// Defaults to a short 800ms duration suitable for quick tracking confirmations.
/// Set [duration] explicitly for longer-lived messages (e.g., profile CRUD operations).
void showFeedback(
  BuildContext context,
  String message, {
  Duration? duration,
}) {
  // B17 — the haptic contract: one successful insert of a record gives exactly one
  // haptic, at the moment it commits, and this line is where every creation path in
  // the app gets it (events, measurements, baby profiles, custom reminders all end
  // here). The magnitude is **`selectionClick`** for all of them — one class chosen
  // once, deliberately not a per-site scale (the ticket's wording: a decision, not a
  // tweak). `lightImpact` was the previous choice, and it is what the parent
  // described as unfelt at 3 a.m. one-handed; `medium`/`heavy` would make a routine
  // tap into battery noise on the smallest devices. Whether it is felt *correctly*
  // can only be settled on a handset — emulators do not vibrate (M9's device pass).
  HapticFeedback.selectionClick();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: duration ?? const Duration(milliseconds: 800),
    ),
  );
}

/// Displays an error feedback snackbar with error-colored background.
///
/// No haptic feedback is triggered for errors — haptics are reserved for positive confirmations.
void showError(
  BuildContext context,
  String message, {
  Duration? duration,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Theme.of(context).colorScheme.error,
      duration: duration ?? const Duration(seconds: 3),
    ),
  );
}
