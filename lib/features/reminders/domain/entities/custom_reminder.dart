import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../data/local/db_constants.dart';
import '../../../../shared/domain/entities/tracking_type.dart';
import 'reminder_frequency.dart';
import 'reminder_item.dart';

part 'custom_reminder.freezed.dart';

/// Un rappel inventé par le parent : « pommade sur le cordon, tous les 2 jours ».
///
/// Il ne décrit que *quand* réclamer ; [completionSource] dit qui décide
/// qu'il est fait. Lié à un soin, il est accompli dès qu'un événement `sante`
/// de son [subtypeValue] existe dans la période (`isDue` de [ReminderFrequency])
/// — c'est ce lien qui le distingue d'une alarme, et qui l'oblige à porter un
/// soin existant plutôt qu'un texte libre côté suivi. Détaché
/// (`subtypeValue == null`), il n'est achevé que par le tap « Fait »
/// de l'utilisateur.
@freezed
abstract class CustomReminder with _$CustomReminder {
  const factory CustomReminder({
    /// Saisie libre du parent, affichée telle quelle (jamais traduite).
    required String label,

    /// Rythme demandé. [ReminderFrequency.monthly] est stocké sans jour
    /// précis : le jour est celui de naissance du bébé actif, lu au moment de
    /// construire la liste — comme pour la vitamine K.
    required ReminderFrequency frequency,

    /// Valeur de `HealthSubtype` dont l'absence rend le rappel dû.
    ///
    /// `null` = rappel **détaché** (D2) : aucun soin n'y est lié, c'est le tap
    /// « Fait » qui l'achève (`completion_source = 'manual'`). Invariant :
    /// `subtypeValue == null` ⟺ `completionSource == manual` — un rappel détaché
    /// laissé en `from_events` matcherait *n'importe quel* événement `sante`.
    String? subtypeValue,

    /// Qui décide que le rappel est fait : [completionFromEvents] — l'absence
    /// d'un événement `sante` portant [subtypeValue] dans la période le règle,
    /// comme les préréglages — ou [completionManual] — seul le tap « Fait »
    /// l'achève, via `reminder_completions`.
    ///
    /// Invariant D2 : `subtypeValue == null` ⟺ [completionSource] vaut
    /// [completionManual] — un rappel détaché laissé en [completionFromEvents]
    /// matcherait *n'importe quel* événement de santé.
    @Default(completionFromEvents) String completionSource,

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
  /// [CustomReminder.completionSource] est propagé tel quel : c'est lui qui
  /// dit au service de quel journal lire l'achèvement.
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
      // Le détaché reste sans soin ici : c'est [reminder.completionSource] qui
      // dit qui le règle, et lui inventer un sous-type le referait au premier
      // événement de santé venu (invariant D2).
      subtypeValue: reminder.subtypeValue,
      completionSource: reminder.completionSource,
    );
  }
}
