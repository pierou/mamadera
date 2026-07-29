import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/providers/app_preferences_provider.dart';
import 'terms_content.dart';

/// Full-screen overlay shown once on first launch when T&C not accepted.
///
/// Presents the Terms & Conditions with an accept button at the bottom.
/// On accept, sets `termsAccepted = true` via the provider and calls [onAccepted].
class TermsAcceptanceDialog extends ConsumerWidget {
  const TermsAcceptanceDialog({
    required this.onAccepted, super.key,
  });

  /// Callback invoked after the user accepts the terms.
  final VoidCallback onAccepted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      // Respect status bar / notch at top. Bottom is handled by the outer
      // SafeArea in main.dart so we avoid double-padding on modern iPhones.
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            // Scrollable terms content — Expanded ensures it fills all available space
            const Expanded(child: TermsContent()),
            // Accept button at bottom (main.dart SafeArea handles home indicator)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              // ignore: prefer_const_constructors
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    // Accept terms and wait for state to persist.
                    await ref.read(appPreferencesProvider.notifier).acceptTerms();
                    // Ensure state update propagates before navigation.
                    // This prevents the redirect callback from seeing stale state.
                    await Future<void>.delayed(Duration.zero);
                    onAccepted();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    context.l.termsAcceptButton,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
