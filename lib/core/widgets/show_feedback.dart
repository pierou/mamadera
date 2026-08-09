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
  HapticFeedback.lightImpact();
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
