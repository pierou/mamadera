import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/providers/app_preferences_provider.dart';
import '../screens/patch_notes_screen.dart';

/// Full-screen overlay showing patch notes with dismiss and opt-out options.
///
/// Has a "Close" button to dismiss, a "Don't show again" checkbox,
/// and a "Skip & Create Later" option for first-time users.
class PatchNotesDialog extends ConsumerWidget {
  const PatchNotesDialog({
    required this.onDismiss,
    this.showSkipButton = false,
    this.onSkip,
    super.key,
  });

  /// Callback invoked after dismissing patch notes.
  final VoidCallback onDismiss;

  /// Whether to show the "Skip & Create Later" button.
  final bool showSkipButton;

  /// Callback invoked when user chooses to skip patch notes.
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      // Respect status bar / notch at top. Bottom handled by main.dart SafeArea.
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            // Scrollable patch notes content — Expanded fills available space
            const Expanded(child: PatchNotesScreen()),
            // Bottom actions (main.dart SafeArea handles home indicator padding)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                children: [
                  // Don't show again checkbox
                  Row(
                    children: [
                      FutureBuilder<bool>(
                        future: ref.read(appPreferencesProvider.future)
                            .then((prefs) => prefs.patchNotesOptOut),
                        builder: (context, snapshot) {
                          final optOut = snapshot.data ?? false;
                          return Checkbox(
                            value: optOut,
                            onChanged: (value) async {
                              await ref
                                  .read(appPreferencesProvider.notifier)
                                  .setPatchNotesOptOut(value: value ?? false);
                            },
                          );
                        },
                      ),
                      Expanded(
                        child: Text(
                          context.l.patchNotesDontShowAgain,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Skip & Create Later button (only shown for first-time users)
                  if (showSkipButton) ...[
                    OutlinedButton(
                      onPressed: () async {
                        await ref
                            .read(appPreferencesProvider.notifier)
                            .markPatchNotesSeen();
                        // Ensure state update propagates before navigation.
                        await Future<void>.delayed(Duration.zero);
                        onSkip?.call();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        context.l.patchNotesSkipCreateLater,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Close button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await ref
                            .read(appPreferencesProvider.notifier)
                            .markPatchNotesSeen();
                        // Ensure state update propagates before navigation.
                        await Future<void>.delayed(Duration.zero);
                        onDismiss();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        context.l.patchNotesClose,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
