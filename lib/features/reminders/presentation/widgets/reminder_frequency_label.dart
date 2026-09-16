import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../domain/entities/reminder_frequency.dart';

/// Libellé de rythme, pour la liste des préréglages comme pour les tuiles des
/// rappels personnalisés.
///
/// Un seul endroit : un préréglage et un rappel personnalisé doivent se décrire
/// avec les mêmes mots, sinon le même rythme s'affiche « Tous les 30 jours »
/// d'un côté et « Toutes les 4 semaines » de l'autre.
String reminderFrequencyLabel(
  BuildContext context,
  ReminderFrequency frequency,
) {
  return frequency.map(
    daily: (_) => context.l.reminderFrequencyDaily,
    weekly: (_) => context.l.reminderFrequencyWeekly,
    monthly: (f) => context.l.reminderFrequencyMonthly(f.dayOfMonth),
    customInterval: (f) => context.l.reminderFrequencyEveryNDays(f.days),
  );
}
