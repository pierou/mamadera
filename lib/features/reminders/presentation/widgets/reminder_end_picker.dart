import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/l10n/date_localization.dart';
import '../../../../core/theme.dart';
import '../../../../core/utils/calendar_date.dart';
import '../../../../core/utils/date_arithmetic.dart';
import '../../domain/services/reminder_end.dart';

/// "Program an end" (B33, D-R5): the three forms a reminder can be ended in, as
/// one section of the edit sheet — used by **presets and custom reminders alike**,
/// so the same words and the same order mean the same thing on both.
///
/// What it guarantees structurally, rather than by validation:
///
/// * **one form at a time** — choosing a date clears the age and vice versa
///   (D-R5's mutual exclusivity, which the repository also enforces at the write:
///   the schema only has the two columns);
/// * **an age that resolves to a real day** — the value is stored as whole months
///   (`years × 12 + months`, so "2 years 6 months" is 30 and nothing else), and
///   the day it means is shown beside it, computed with B18's clamped anniversary.
///   Showing the resolved date is not decoration: it is how a parent sees that the
///   end follows the *baby*, and it moves on screen the moment a birthdate is
///   corrected, which is the whole point of storing months instead of a date;
/// * **a past end warns but is accepted** — a series that is already over is a
///   legitimate thing to write (D-R5), and blocking it would trap a parent who is
///   cleaning up an old reminder.
class ReminderEndPicker extends StatelessWidget {
  const ReminderEndPicker({
    required this.birthDate,
    required this.onChanged,
    required this.endDate,
    required this.endAgeMonths,
    super.key,
  });

  /// The stored `end_date`, if any.
  final DateTime? endDate;

  /// The stored `end_age_months`, if any.
  final int? endAgeMonths;

  /// The scope's birthdate. `null` on the legacy profileless scope, where the age
  /// option is disabled with a hint (D-R10) rather than guessing a day.
  final DateTime? birthDate;

  /// Exactly one of its arguments is non-null, or both are (no end).
  final void Function({DateTime? endDate, int? endAgeMonths}) onChanged;

  ReminderEndKind get _kind => reminderEndKindOf(
        // The same codec the columns use — a second formatter here would be a
        // second opinion on what "the stored date" means.
        endDate: endDate == null ? null : formatCalendarDate(endDate!),
        endAgeMonths: endAgeMonths,
      );

  int get _months => endAgeMonths ?? 0;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final kind = _kind;
    final resolved = _resolvedEnd();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.reminderEndSectionTitle,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Wrap(
          spacing: AppTheme.spacingSm,
          children: [
            ChoiceChip(
              label: Text(l.reminderEndNone),
              selected: kind == ReminderEndKind.none,
              onSelected: (_) => onChanged(),
            ),
            ChoiceChip(
              label: Text(l.reminderEndOnDate),
              selected: kind == ReminderEndKind.date,
              onSelected: (_) => onChanged(endDate: _defaultDate(context)),
            ),
            ChoiceChip(
              label: Text(l.reminderEndAtAge),
              selected: kind == ReminderEndKind.age,
              // An age means nothing without a birthday to count from.
              onSelected: birthDate == null
                  ? null
                  : (_) => onChanged(endAgeMonths: _months),
            ),
          ],
        ),
        if (birthDate == null && kind != ReminderEndKind.age)
          Padding(
            padding: const EdgeInsets.only(top: AppTheme.spacingSm),
            child: Text(
              l.reminderEndNeedsBirthdate,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        if (kind == ReminderEndKind.date)
          _DateRow(
            date: endDate,
            onPick: () => _pickDate(context),
          ),
        if (kind == ReminderEndKind.age)
          _AgeStepper(
            months: _months,
            onChanged: (months) => onChanged(
                endAgeMonths: months.clamp(0, maxReminderEndAgeMonths)),
          ),
        // The day the series stops, named in the form the parent chose. For the
        // age form this is the point of the whole section: the stored value is a
        // number of months, and this line is what makes the resulting day visible
        // — and it moves the moment a birthdate is corrected.
        if (resolved != null)
          Padding(
            padding: const EdgeInsets.only(top: AppTheme.spacingSm),
            child: Text(
              _kind == ReminderEndKind.age
                  ? l.reminderEndAgeResolved(
                      endAgeMonths ?? 0,
                      formatDateShort(context, resolved),
                    )
                  : l.reminderEndUntilDate(
                      formatDateShort(context, resolved),
                    ),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
        // D-R5: accepted, with the consequence said out loud.
        if (resolved != null && resolved.isBefore(DateTime.now()))
          Padding(
            padding: const EdgeInsets.only(top: AppTheme.spacingSm),
            child: Text(
              l.reminderEndAlreadyPast,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ),
      ],
    );
  }

  /// The day the series actually stops — the age form resolved against the
  /// birthdate, exactly as `reminderEndFor` resolves it at read time.
  DateTime? _resolvedEnd() {
    final date = endDate;
    if (date != null) return date;
    final months = endAgeMonths;
    final born = birthDate;
    if (months == null || born == null) return null;
    return addMonthsClamped(born, months);
  }

  DateTime _defaultDate(BuildContext context) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 20),
    );
    if (picked == null) return;
    onChanged(
      endDate: DateTime(picked.year, picked.month, picked.day),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.date, required this.onPick});

  final DateTime? date;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spacingSm),
      child: TextButton.icon(
        onPressed: onPick,
        icon: const Icon(Icons.event),
        label: Text(
          date == null
              ? context.l.reminderEndOnDate
              : formatDateShort(context, date!),
        ),
      ),
    );
  }
}

/// Years + months, stored as one canonical month count (D-R5: `end_age_months` is
/// whole months, 0-180). "2 years 6 months" leaves this widget as 30, never as a
/// pair of columns a later reader would have to multiply.
class _AgeStepper extends StatelessWidget {
  const _AgeStepper({
    required this.months,
    required this.onChanged,
  });

  final int months;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final years = months ~/ 12;
    final rest = months % 12;

    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spacingSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Step(
                icon: Icons.remove,
                tooltip: '${years}y −',
                onTap: () => onChanged(months - 12),
                enabled: years > 0,
              ),
              _Step(
                icon: Icons.add,
                tooltip: '${years}y +',
                onTap: () => onChanged(months + 12),
                enabled: months + 12 <= maxReminderEndAgeMonths,
              ),
              const SizedBox(width: AppTheme.spacingLg),
              _Step(
                icon: Icons.remove,
                tooltip: '${rest}m −',
                onTap: () => onChanged(months - 1),
                enabled: months > 0,
              ),
              _Step(
                icon: Icons.add,
                tooltip: '${rest}m +',
                onTap: () => onChanged(months + 1),
                enabled: months + 1 <= maxReminderEndAgeMonths,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(l.reminderEndAgeValue(months)),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.enabled,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon),
        onPressed: enabled ? onTap : null,
        style: IconButton.styleFrom(
          side: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
    );
  }
}
