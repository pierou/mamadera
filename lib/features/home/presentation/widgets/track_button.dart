import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../reminders/domain/entities/reminders_state.dart';
import 'reminder_pill.dart';

class TrackButton extends StatefulWidget {
  const TrackButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.onLongPress,
    this.reminders,
    super.key,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  /// Reminder statuses for this tracking type (pending or with last-event info).
  /// `null` means no reminder information available.
  final List<ReminderStatus>? reminders;

  @override
  State<TrackButton> createState() => _TrackButtonState();
}

class _TrackButtonState extends State<TrackButton> {
  bool _isPressed = false;

  /// Check if any reminders are pending (not yet tracked this period).
  bool get _hasPendingReminders {
    return widget.reminders != null && widget.reminders!.isNotEmpty;
  }

  String? _lastTrackedLabel(BuildContext context) {
    final items = widget.reminders ?? [];
    if (items.isEmpty) return null;

    DateTime? lastEvent;
    for (final s in items) {
      final evt = s.lastEventAt;
      if (evt == null) continue;
      lastEvent = lastEvent == null || evt.isAfter(lastEvent) ? evt : lastEvent;
    }

    if (lastEvent == null) return null;

    final diff = DateTime.now().difference(lastEvent);

    if (diff.inMinutes < 1) return '< 1 min';
    if (diff.inHours < 1) return '${diff.inMinutes}min ago';
    if (diff.inDays < 1) return '${diff.inHours}h ${diff.inMinutes % 60}m ago';
    if (diff.inDays == 1) return context.l.yesterday;
    if (diff.inDays < 7) return '${diff.inDays}${context.l.daysAgo}';
    return '${lastEvent.day}/${lastEvent.month}/${lastEvent.year}';
  }

  String _pillLabelFor(BuildContext context, ReminderStatus status) {
    switch (status.item.labelKey) {
      case 'reminderVitaminD':
        return context.l.reminderVitaminD;
      case 'reminderVitaminK':
        return context.l.reminderVitaminK;
      case 'reminderEyeCleaning':
        return context.l.reminderEyeCleaning;
      case 'reminderFaceCleaning':
        return context.l.reminderFaceCleaning;
      default:
        return status.item.labelKey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPending = _hasPendingReminders;
    final items = widget.reminders ?? [];

    return Semantics(
      label: widget.label,
      button: true,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedContainer(
          duration: MediaQuery.of(context).disableAnimations
              ? Duration.zero
              : const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          transform: Matrix4.identity()
            ..scaleByDouble(
                _isPressed ? 0.97 : 1.0, _isPressed ? 0.97 : 1.0, 1, 1),
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            border: Border.all(color: widget.color, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top: label (prominent)
                Expanded(
                  flex: hasPending ? 3 : 4,
                  child: Center(
                    child: Text(
                      widget.label,
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: widget.color,
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

                // Middle: pills row (when pending) or "last tracked" text
                if (hasPending) ...[
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        alignment: WrapAlignment.center,
                        children: [
                          for (final status in items)
                            ReminderPill(label: _pillLabelFor(context, status)),
                        ],
                      ),
                    ),
                  ),
                ] else if (_lastTrackedLabel(context) != null) ...[
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: Text(
                        _lastTrackedLabel(context)!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                ],

                // Bottom spacer
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
