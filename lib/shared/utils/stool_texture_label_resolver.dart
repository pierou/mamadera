import 'package:flutter/widgets.dart';

import '../../core/l10n/app_localizations_extension.dart';
import '../domain/entities/tracking_enums.dart';

/// Map of localized labels for each stool texture, keyed by labelKey.
final kStoolTextureLabels = <String, String Function(BuildContext)>{
  'stoolTextureAqueuse': (c) => c.l.stoolTextureAqueuse,
  'stoolTextureGrumeleuse': (c) => c.l.stoolTextureGrumeleuse,
  'stoolTexturePateuse': (c) => c.l.stoolTexturePateuse,
  'stoolTextureMoulee': (c) => c.l.stoolTextureMoulee,
  'stoolTextureDure': (c) => c.l.stoolTextureDure,
};

/// Resolves a localized label for the given stool texture via its labelKey.
String resolveStoolTextureLabel(BuildContext context, StoolTexture texture) {
  return kStoolTextureLabels[texture.labelKey]?.call(context) ?? texture.label;
}
