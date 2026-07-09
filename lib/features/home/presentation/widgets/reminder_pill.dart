import 'package:flutter/material.dart';

/// Small pill-shaped badge for display on track buttons when a reminder is pending.
/// Shows the localized short label (e.g., "Vit. D", "Yeux") with amber background.
class ReminderPill extends StatelessWidget {
  const ReminderPill({
    required this.label,
    super.key,
  });

  /// Short display text for the pill badge.
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onTertiary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
