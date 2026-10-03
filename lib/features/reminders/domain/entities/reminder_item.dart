import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../data/local/db_constants.dart';
import '../../../../shared/domain/entities/baby_profile.dart';
import '../../../../shared/domain/entities/tracking_type.dart';
import 'reminder_frequency.dart';

part 'reminder_item.freezed.dart';

/// Un rappel à afficher tant que le soin associé n'a pas été saisi.
///
/// L'identifiant est une clé stable (pas un UUID) : il indexe les lignes de
/// `reminder_settings` et `reminder_dismissals`.
@freezed
abstract class ReminderItem with _$ReminderItem {
  const factory ReminderItem({
    required String id,
    required String labelKey,
    required ReminderFrequency frequency,
    required TrackingType trackingType,

    /// Soin lié (sous-type du domaine de [trackingType]), quand le
    /// rappel se règle d'après un événement saisi.
    ///
    /// `null` : rappel détaché d'un soin — sa complétion n'est décidée que
    /// par l'utilisateur, jamais déduite d'un événement (invariant D2).
    String? subtypeValue,

    /// Bébé propriétaire du rappel, quand il existe.
    ///
    /// `null` sur les préréglages : le portage est porté par la ligne de
    /// base (`reminder_settings.baby_id`), jamais par l'item lui-même.
    String? babyId,

    /// Ce qui règle ce rappel :
    /// - [completionFromEvents] : un événement de
    ///   [trackingType] portant [subtypeValue] (sa date vaut pour la
    ///   complétion) ;
    /// - [completionManual] : une ligne de `reminder_completions`
    ///   écrite par l'utilisateur — sans [subtypeValue], rien d'autre ne
    ///   peut le régler (invariant D2).
    ///
    /// `null` se lit comme [completionFromEvents].
    String? completionSource,
  }) = _ReminderItem;
}

/// Préréglages v1.
extension ReminderItemPresets on ReminderItem {
  /// Vitamine D — quotidienne, se règle par le suivi de santé `vitamine_d`.
  static const vitaminD = ReminderItem(
    id: 'vitamine_d',
    labelKey: 'reminderVitaminD',
    frequency: Daily(),
    trackingType: TrackingType.sante,
    subtypeValue: 'vitamine_d',
    babyId: null,
    completionSource: completionFromEvents,
  );

  /// Vitamine K — un point de départ sans date de naissance : roulement
  /// de 30 jours. `buildForBaby` le cale sur le jour de naissance du
  /// profil actif.
  static const vitaminK = ReminderItem(
    id: 'vitamine_k',
    labelKey: 'reminderVitaminK',
    frequency: CustomInterval(days: 30),
    trackingType: TrackingType.sante,
    subtypeValue: 'vitamine_k',
    babyId: null,
    completionSource: completionFromEvents,
  );

  /// Nettoyage des yeux — quotidien, se règle par `nettoyage_yeux`.
  static const eyeCleaning = ReminderItem(
    id: 'eye_cleaning',
    labelKey: 'reminderEyeCleaning',
    frequency: Daily(),
    trackingType: TrackingType.sante,
    subtypeValue: 'nettoyage_yeux',
    babyId: null,
    completionSource: completionFromEvents,
  );

  /// Nettoyage du visage — quotidien, se règle par `nettoyage_visage`.
  static const faceCleaning = ReminderItem(
    id: 'face_cleaning',
    labelKey: 'reminderFaceCleaning',
    frequency: Daily(),
    trackingType: TrackingType.sante,
    subtypeValue: 'nettoyage_visage',
    babyId: null,
    completionSource: completionFromEvents,
  );

  /// Construit la liste des rappels préréglés à partir du profil actif.
  ///
  /// Seule la vitamine K change : elle est calée sur le jour de naissance du
  /// profil (mensuelle), au lieu du roulement de 30 jours du préréglage
  /// statique. Le reste est renvoyé tel quel.
  static List<ReminderItem> buildForBaby(BabyProfile profile) {
    final vitaminK = ReminderItem(
      id: ReminderItemPresets.vitaminK.id,
      frequency: Monthly(dayOfMonth: profile.birthDate.day),
      labelKey: ReminderItemPresets.vitaminK.labelKey,
      trackingType: ReminderItemPresets.vitaminK.trackingType,
      subtypeValue: ReminderItemPresets.vitaminK.subtypeValue,
      // Le portage (babyId) n'est pas celui de l'item : il vit dans les
      // lignes de base, qui partagent le même id.
      completionSource: ReminderItemPresets.vitaminK.completionSource,
    );

    return [
      vitaminD,
      vitaminK,
      eyeCleaning,
      faceCleaning,
    ];
  }
}
