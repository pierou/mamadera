import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../shared/domain/entities/tracking_enums.dart';
import '../../../shared/domain/entities/tracking_type.dart';
import '../../l10n/app_localizations.dart';

/// Formats a [DateTime] using locale-appropriate date/time patterns.
///
/// - FR → `dd/MM/yyyy HH:mm` (24-hour, day-first)
/// - EN → `MM/dd/yyyy hh:aa` (12-hour with AM/PM, month-first)
///
/// Falls back to the French format for unsupported locales.
String formatDate(BuildContext context, DateTime date) {
  final localeName = AppLocalizations.of(context).localeName;
  final languageCode = localeName.split('_').first.toLowerCase();

  switch (languageCode) {
    case 'en':
      return DateFormat('MM/dd/yyyy hh:aa', 'en_US').format(date);
    case 'fr':
    default:
      return DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(date);
  }
}

/// Formats a [DateTime] displaying date only (no time).
String formatDateShort(BuildContext context, DateTime date) {
  final localeName = AppLocalizations.of(context).localeName;
  final languageCode = localeName.split('_').first.toLowerCase();

  switch (languageCode) {
    case 'en':
      return DateFormat('MM/dd/yyyy', 'en_US').format(date);
    case 'fr':
    default:
      return DateFormat('dd/MM/yyyy', 'fr_FR').format(date);
  }
}

/// Resolves the localized label for a [HistoryFilter] using AppLocalizations.
String getHistoryFilterLabel(BuildContext context, HistoryFilter filter) {
  final l = _l10nOf(context);
  switch (filter) {
    case HistoryFilter.all:
      return l.filterAll;
    case HistoryFilter.miam:
      return l.filterMiam;
    case HistoryFilter.dodo:
      return l.filterDodo;
    case HistoryFilter.caca:
      return l.filterCaca;
    case HistoryFilter.sante:
      return l.filterSante;
  }
}

/// Resolves the localized label for a [TrackingType] using AppLocalizations.
String getTrackingTypeLabel(BuildContext context, TrackingType type) {
  final l = _l10nOf(context);
  switch (type) {
    case TrackingType.miam:
      return l.homeButtonMiam;
    case TrackingType.dodo:
      return l.homeButtonDodo;
    case TrackingType.caca:
      return l.homeButtonCaca;
    case TrackingType.sante:
      return l.homeButtonSante;
  }
}

/// Helper to access AppLocalizations without extension methods.
AppLocalizations _l10nOf(BuildContext context) => AppLocalizations.of(context);
