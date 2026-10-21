enum TrackingType {
  miam,
  sante,
  caca,
  dodo;

  /// Converts the data type into a human-readable string for the user interface, if necessary.
  String get label {
    switch (this) {
      case TrackingType.miam:
        return 'Miam';
      case TrackingType.sante:
        return 'Santé';
      case TrackingType.caca:
        return 'Caca';
      case TrackingType.dodo:
        return 'Dodo';
    }
  }

  /// Converts a string into an enumeration (useful for parsing data from a database or user interface).
  static TrackingType fromString(String value) {
    return switch (value.toLowerCase()) {
      'miam' => TrackingType.miam,
      'santé' || 'sante' => TrackingType.sante,
      'caca' => TrackingType.caca,
      'dodo' => TrackingType.dodo,
      _ => TrackingType.miam, // Secure default value.
    };
  }
}
