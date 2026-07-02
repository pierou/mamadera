/// Profil bébé : données identifiant un nouveau-né suivi dans l'application.
///
/// Utilisé comme source de vérité pour:
/// - Reminders mensuels basés sur le jour de naissance (ex: Vitamine K le même jour chaque mois)
/// - Calcul d'âge et statistiques par période postnatale
/// - Support multi-bébé à l'avenir (isActive permet la sélection du bébé actif)

library;

final class BabyProfile {
  /// Constructeur pour créer un profil bébé immuable.
  const BabyProfile({
    required this.id,
    required this.name,
    required this.birthDate,
    this.isActive = true,
  });

  /// Identifiant unique (UUID recommandé).
  final String id;

  /// Nom affiché du bébé dans l'UI.
  final String name;

  /// Date de naissance — utilisée pour calculer les reminders mensuels et l'âge.
  final DateTime birthDate;

  /// Indique si ce profil est le bébé actif (suivi courant).
  /// Un seul profil devrait être actif à la fois.
  final bool isActive;

  /// Jour du mois de naissance — utilisé pour les reminders mensuels basés sur la date de naissance.
  /// Ex: né le 15 mars → `birthDayOfMonth` = 15 → Vitamine K due le 15 de chaque mois.
  int get birthDayOfMonth => birthDate.day;

  /// Clone ce profil avec des propriétés modifiées (pour mises à jour immuables).
  BabyProfile copyWith({
    String? name,
    DateTime? birthDate,
    bool? isActive,
  }) {
    return BabyProfile(
      id: id,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() => 'BabyProfile(id: $id, name: $name, birthDate: $birthDate)';
}
