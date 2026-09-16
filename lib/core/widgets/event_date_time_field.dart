import 'package:flutter/material.dart';

import '../l10n/app_localizations_extension.dart';
import '../l10n/date_localization.dart';
import '../theme.dart';

/// Section title + tappable row used to pick the date and time of an event.
///
/// Single implementation shared by the four creation bottom sheets (home) and
/// by the edit bottom sheet (history), so both paths get exactly the same
/// two-step date → time interaction and the same selectable range.
///
/// The row itself is stateless: the owning dialog holds the [DateTime] and
/// receives the new value through [onChanged].
class EventDateTimeField extends StatelessWidget {
  const EventDateTimeField({
    required this.value,
    required this.onChanged,
    this.title,
    this.firstDate,
    this.lastDate,
    super.key,
  });

  /// Currently selected date and time.
  final DateTime value;

  /// Called with the newly selected date and time.
  final ValueChanged<DateTime> onChanged;

  /// Section title; defaults to the localized "Date and time" label.
  final String? title;

  /// Earliest selectable date. Defaults to [defaultLookBack] before [lastDate].
  final DateTime? firstDate;

  /// Latest selectable date. Defaults to the moment the picker is opened: an
  /// event cannot be dated in the future.
  final DateTime? lastDate;

  /// How far back the picker reaches when [firstDate] is not supplied.
  static const Duration defaultLookBack = Duration(days: 365 * 2);

  Future<void> _pickDateTime(BuildContext context) async {
    final rangeEnd = lastDate ?? DateTime.now();
    final rangeStart = firstDate ?? rangeEnd.subtract(defaultLookBack);

    final date = await showDatePicker(
      context: context,
      initialDate: _clampToRange(value, rangeStart, rangeEnd),
      firstDate: rangeStart,
      lastDate: rangeEnd,
    );
    if (date == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(value),
    );

    // Cancelling the time step keeps the chosen day and the previous clock
    // time — the behaviour the edit sheet had before this field was shared.
    if (time == null) {
      onChanged(
          DateTime(date.year, date.month, date.day, value.hour, value.minute));
      return;
    }

    onChanged(
        DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  /// Pulls [value] inside `[start, end]` so `showDatePicker`'s `initialDate`
  /// assertion cannot be tripped by an out-of-range timestamp (e.g. an event
  /// recorded long ago, or dated by a clock that was wrong at insert time).
  static DateTime _clampToRange(DateTime value, DateTime start, DateTime end) {
    if (value.isBefore(start)) return start;
    if (value.isAfter(end)) return end;
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            title ?? context.l.eventDateSectionTitle,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Semantics(
          button: true,
          label: context.l.eventDateSectionTitle,
          child: InkWell(
            onTap: () => _pickDateTime(context),
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outline),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  // Expanded + ellipsis : la ligne est aussi utilisée dans des
                  // feuilles étroites, un Spacer la ferait déborder.
                  Expanded(
                    child: Text(
                      formatDate(context, value),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.edit_outlined,
                      size: 18, color: theme.colorScheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
