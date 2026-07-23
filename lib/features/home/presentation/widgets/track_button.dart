import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/theme.dart';
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
    return Semantics(
      label: widget.label,
      button: true,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: _TrackButtonContent(
          isPressed: _isPressed,
          label: widget.label,
          color: widget.color,
          reminders: widget.reminders,
          context: context,
          pillLabelBuilder: _pillLabelFor,
          lastTrackedLabelBuilder: _lastTrackedLabel,
        ),
      ),
    );
  }
}

/// Internal content of TrackButton, extracted to keep build method under 25 lines.
class _TrackButtonContent extends StatelessWidget {
  const _TrackButtonContent({
    required this.isPressed,
    required this.label,
    required this.color,
    required this.reminders,
    required this.context,
    required this.pillLabelBuilder,
    required this.lastTrackedLabelBuilder,
  });

  final bool isPressed;
  final String label;
  final Color color;
  final List<ReminderStatus>? reminders;
  final BuildContext context;
  final String Function(BuildContext, ReminderStatus) pillLabelBuilder;
  final String? Function(BuildContext) lastTrackedLabelBuilder;

  bool get _hasPendingReminders => reminders != null && reminders!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final hasPending = _hasPendingReminders;
    final items = reminders ?? [];
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    return AnimatedContainer(
      duration: MediaQuery.of(this.context).disableAnimations
          ? Duration.zero
          : const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      transform: Matrix4.identity()
        ..scaleByDouble(isPressed ? 0.97 : 1.0, isPressed ? 0.97 : 1.0, 1, 1),
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.08),
            color.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.all(Radius.circular(AppTheme.shapeCardRadius)),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: hasPending ? 3 : 4,
              child: Center(
                child: Text(
                  label,
                  style: theme.textTheme.headlineLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (hasPending) ...[
              Expanded(
                flex: 2,
                child: Center(
                  child: Wrap(
                    spacing: AppTheme.spacingSm,
                    runSpacing: AppTheme.spacingSm,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final status in items)
                        ReminderPill(label: pillLabelBuilder(this.context, status)),
                    ],
                  ),
                ),
              ),
            ] else if (lastTrackedLabelBuilder(this.context) != null) ...[
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    lastTrackedLabelBuilder(this.context)!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black54,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppTheme.spacingSm),
          ],
        ),
      ),
    );
  }
}
