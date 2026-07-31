import 'package:flutter/widgets.dart';

import '../../../core/l10n/app_localizations_extension.dart';
import '../../shared/domain/entities/tracking_enums.dart';

/// Map of localized labels for each health subtype, keyed by labelKey.
final kHealthLabels = <String, String Function(BuildContext)>{
  'healthNettoyageYeux': (c) => c.l.healthNettoyageYeux,
  'healthNettoyageNombril': (c) => c.l.healthNettoyageNombril,
  'healthNettoyageVisage': (c) => c.l.healthNettoyageVisage,
  'healthNettoyageNez': (c) => c.l.healthNettoyageNez,
  'healthVitamineD': (c) => c.l.healthVitamineD,
  'healthVitamineK': (c) => c.l.healthVitamineK,
};

/// Resolves a localized label for the given health subtype via its labelKey.
String resolveHealthLabel(BuildContext context, HealthSubtype subtype) {
  return kHealthLabels[subtype.labelKey]?.call(context) ?? subtype.label;
}
