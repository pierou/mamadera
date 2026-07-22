/// Profil bébé : données identifiant un nouveau-né suivi dans l'application.
///
/// Utilisé comme source de vérité pour:
/// - Reminders mensuels basés sur le jour de naissance (ex: Vitamine K le même jour chaque mois)
/// - Calcul d'âge et statistiques par période postnatale
/// - Support multi-bébé à l'avenir (isActive permet la sélection du bébé actif)

library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'baby_profile.freezed.dart';

/// @freezed BabyProfile model
@freezed
abstract class BabyProfile with _$BabyProfile {
  const factory BabyProfile({
    required String id,
    required String name,
    required DateTime birthDate,
    @Default(true) bool isActive,
  }) = _BabyProfile;
}

/// Clone this profile with updated fields.
BabyProfile babyProfileUpdated(
  BabyProfile profile, {
  String? name,
  DateTime? birthDate,
  bool? isActive,
}) {
  return BabyProfile(
    id: profile.id,
    name: name ?? profile.name,
    birthDate: birthDate ?? profile.birthDate,
    isActive: isActive ?? profile.isActive,
  );
}

/// Jour du mois de naissance — utilisé pour les reminders mensuels basés sur la date de naissance.
/// Ex: né le 15 mars → `birthDayOfMonth` = 15 → Vitamine K due le 15 de chaque mois.
int babyProfileBirthDayOfMonth(DateTime birthDate) => birthDate.day;
