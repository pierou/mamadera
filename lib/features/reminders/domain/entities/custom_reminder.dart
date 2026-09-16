import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../shared/domain/entities/tracking_type.dart';
import 'reminder_frequency.dart';
import 'reminder_item.dart';

part 'custom_reminder.freezed.dart';

/// Un rappel inventé par le parent : « pommade sur le cordon, tous les 2 jours ».
///
/// Il ne décrit que *quand* réclamer. Comme les quatre préréglages, il n'a pas
/// d'état « fait » propre : il est accompli dès qu'un événement `sante` du
/// [subtypeValue] lié existe dans la période (`isDue` de [ReminderFrequency]). C'est
/// ce lien qui le distingue d'une alarme, et c'est aussi ce qui l'oblige à
/// porter un soin existant plutôt qu'un texte libre côté suivi.
@freezed
abstract class CustomReminder with _$CustomReminder {
  const factory CustomReminder({
    /// Saisie libre du parent, affichée telle quelle (jamais traduite).
    required String label,

    /// Valeur de `HealthSubtype` dont l'absence rend le rappel dû.
    required String subtypeValue,

    /// Rythme demandé. [ReminderFrequency.monthly] est stocké sans jour
    /// précis : le jour est celui de naissance du bébé actif, lu au moment de
    /// construire la liste — comme pour la vitamine K.
    required ReminderFrequency frequency,

    /// Clé de `custom_reminders`, `null` tant que le rappel n'est pas écrit.
    int? id,
  }) = _CustomReminder;
}

/// Conversion en [ReminderItem] et clés de table partagées.
extension CustomReminderPresets on ReminderItem {
  /// Préfixe de la clé utilisée dans `reminder_settings` et
  /// `reminder_dismissals` pour un rappel personnalisé.
  ///
  /// Le préfixe est un espace de noms : un id personnalisé ne peut jamais
  /// écraser celui d'un préréglage (`vitamine_d`, …), dont les lignes déjà
  /// écrites doivent survivre.
  static const String customIdPrefix = 'custom_';

  /// Le jour du mois utilisé par [ReminderFrequency.monthly] quand aucun bébé
  /// n'est actif : le 1er, pour qu'un rappel mensuel reste mensuel.
  static const int monthlyFallbackDay = 1;

  /// La vue « rappel d'accueil » d'un rappel enregistré.
  ///
  /// [monthlyDay] est le jour de naissance du bébé actif ; il n'est lu que pour
  /// un rythme mensuel, et [monthlyFallbackDay] s'applique sans profil.
  /// L'id est la clé stable `custom_<id>` — jamais le libellé, que le parent
  /// peut renommer sans orpheliner ses réglages et ses rangs d'acquittement.
  static ReminderItem forCustom(
    CustomReminder reminder, {
    int? monthlyDay,
  }) {
    return ReminderItem(
      id: '$customIdPrefix${reminder.id}',
      labelKey: reminder.label,
      frequency: switch (reminder.frequency) {
        Monthly() => ReminderFrequency.monthly(
            dayOfMonth: monthlyDay ?? monthlyFallbackDay,
          ),
        final ReminderFrequency frequency => frequency,
      },
      trackingType: TrackingType.sante,
      subtypeValue: reminder.subtypeValue,
    );
  }
}
