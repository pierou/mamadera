import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';

/// Convenience extension to access [AppLocalizations] via `context.l`.
extension AppLocalizationsX on BuildContext {
  /// Returns the localized strings for this context.
  AppLocalizations get l => AppLocalizations.of(this);
}
