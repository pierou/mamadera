enum TrackingType {
  miam,
  sante,
  caca,
  dodo;

  /// Convertit le type en une chaîne lisible pour l'UI si nécessaire
  String get label {
    switch (this) {
      case TrackingType.miam: return 'Miam';
      case TrackingType.sante: return 'Santé';
      case TrackingType.caca: return 'Caca';
      case TrackingType.dodo: return 'Dodo';
    }
  }

  /// Convertit une chaîne en enum (utile pour la parsing depuis le DB ou l'UI)
  static TrackingType fromString(String value) {
    return switch (value.toLowerCase()) {
      'miam' => TrackingType.miam,
      'santé' || 'sante' => TrackingType.sante,
      'caca' => TrackingType.caca,
      'dodo' => TrackingType.dodo,
      _ => TrackingType.miam, // Valeur par défaut sécurisée
    };
  }
}
