import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import '../../shared/domain/entities/quantity_unit.dart';

/// Localised suffix for a [QuantityUnit] — the single place where a stored
/// unit becomes text on screen.
///
/// Widgets must not spell units out themselves: a hardcoded `'ml'` beside a
/// row whose `unit` says `min` is a wrong health number, which is the defect
/// schema v12 exists to remove. Units come from the row, text comes from here.
String quantityUnitLabel(BuildContext context, QuantityUnit unit) =>
    switch (unit) {
      QuantityUnit.ml => AppLocalizations.of(context).millilitreSuffix,
      QuantityUnit.min => AppLocalizations.of(context).minuteSuffix,
      QuantityUnit.g => AppLocalizations.of(context).gramSuffix,
    };
