import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mamadera'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get navHome;

  /// No description provided for @navHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get navHistory;

  /// No description provided for @navMenu.
  ///
  /// In fr, this message translates to:
  /// **'Menu'**
  String get navMenu;

  /// No description provided for @homeButtonMiam.
  ///
  /// In fr, this message translates to:
  /// **'Miam'**
  String get homeButtonMiam;

  /// No description provided for @homeButtonSante.
  ///
  /// In fr, this message translates to:
  /// **'Santé'**
  String get homeButtonSante;

  /// No description provided for @homeButtonCaca.
  ///
  /// In fr, this message translates to:
  /// **'Caca'**
  String get homeButtonCaca;

  /// No description provided for @homeButtonDodo.
  ///
  /// In fr, this message translates to:
  /// **'Dodo'**
  String get homeButtonDodo;

  /// No description provided for @durationPickerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Durée du sommeil'**
  String get durationPickerTitle;

  /// No description provided for @cancelButton.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancelButton;

  /// No description provided for @confirmButton.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get confirmButton;

  /// No description provided for @durationFormatHoursMinutes.
  ///
  /// In fr, this message translates to:
  /// **'{hours}h{minutes}'**
  String durationFormatHoursMinutes(Object hours, Object minutes);

  /// No description provided for @durationFormatMinutes.
  ///
  /// In fr, this message translates to:
  /// **'{minutes} min'**
  String durationFormatMinutes(Object minutes);

  /// No description provided for @healthSubtypeDialogTitle.
  ///
  /// In fr, this message translates to:
  /// **'Type de soin'**
  String get healthSubtypeDialogTitle;

  /// No description provided for @saveButton.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get saveButton;

  /// No description provided for @healthSubtypeRequiredError.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner un type de soin'**
  String get healthSubtypeRequiredError;

  /// No description provided for @healthNettoyageYeux.
  ///
  /// In fr, this message translates to:
  /// **'Nettoyage des yeux'**
  String get healthNettoyageYeux;

  /// No description provided for @healthNettoyageNombril.
  ///
  /// In fr, this message translates to:
  /// **'Nettoyage du nombril'**
  String get healthNettoyageNombril;

  /// No description provided for @healthNettoyageVisage.
  ///
  /// In fr, this message translates to:
  /// **'Nettoyage du visage'**
  String get healthNettoyageVisage;

  /// No description provided for @healthNettoyageNez.
  ///
  /// In fr, this message translates to:
  /// **'Nettoyage du nez'**
  String get healthNettoyageNez;

  /// No description provided for @healthVitamineD.
  ///
  /// In fr, this message translates to:
  /// **'Vitamine D'**
  String get healthVitamineD;

  /// No description provided for @healthVitamineK.
  ///
  /// In fr, this message translates to:
  /// **'Vitamine K'**
  String get healthVitamineK;

  /// No description provided for @reminderVitaminD.
  ///
  /// In fr, this message translates to:
  /// **'Vit. D'**
  String get reminderVitaminD;

  /// No description provided for @reminderVitaminK.
  ///
  /// In fr, this message translates to:
  /// **'Vit. K'**
  String get reminderVitaminK;

  /// No description provided for @reminderEyeCleaning.
  ///
  /// In fr, this message translates to:
  /// **'Yeux'**
  String get reminderEyeCleaning;

  /// No description provided for @reminderFaceCleaning.
  ///
  /// In fr, this message translates to:
  /// **'Visage'**
  String get reminderFaceCleaning;

  /// No description provided for @yesterday.
  ///
  /// In fr, this message translates to:
  /// **'Hier'**
  String get yesterday;

  /// No description provided for @daysAgo.
  ///
  /// In fr, this message translates to:
  /// **' jours'**
  String get daysAgo;

  /// No description provided for @lastTracked.
  ///
  /// In fr, this message translates to:
  /// **'Dernière activité: '**
  String get lastTracked;

  /// No description provided for @wasteDialogTitle.
  ///
  /// In fr, this message translates to:
  /// **'Type de selle'**
  String get wasteDialogTitle;

  /// No description provided for @pipiColorSectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Couleur du pipi'**
  String get pipiColorSectionTitle;

  /// No description provided for @cacaColorSectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Couleur du caca'**
  String get cacaColorSectionTitle;

  /// No description provided for @wasteTypePipi.
  ///
  /// In fr, this message translates to:
  /// **'🟡 Pipi'**
  String get wasteTypePipi;

  /// No description provided for @wasteTypeCaca.
  ///
  /// In fr, this message translates to:
  /// **'🟤 Caca'**
  String get wasteTypeCaca;

  /// No description provided for @wasteTypeLesDeux.
  ///
  /// In fr, this message translates to:
  /// **'🟡🟤 Les deux'**
  String get wasteTypeLesDeux;

  /// No description provided for @pipiColorIncolore.
  ///
  /// In fr, this message translates to:
  /// **'Incolore'**
  String get pipiColorIncolore;

  /// No description provided for @pipiColorJauneClair.
  ///
  /// In fr, this message translates to:
  /// **'Jaune clair'**
  String get pipiColorJauneClair;

  /// No description provided for @pipiColorJauneFonce.
  ///
  /// In fr, this message translates to:
  /// **'Jaune foncé'**
  String get pipiColorJauneFonce;

  /// No description provided for @pipiColorRoseUrates.
  ///
  /// In fr, this message translates to:
  /// **'Rose/Orange (urates)'**
  String get pipiColorRoseUrates;

  /// No description provided for @cacaColorMeconium.
  ///
  /// In fr, this message translates to:
  /// **'Mécônium'**
  String get cacaColorMeconium;

  /// No description provided for @cacaColorVertOlive.
  ///
  /// In fr, this message translates to:
  /// **'Vert olive'**
  String get cacaColorVertOlive;

  /// No description provided for @cacaColorJauneMoutarde.
  ///
  /// In fr, this message translates to:
  /// **'Jaune moutarde'**
  String get cacaColorJauneMoutarde;

  /// No description provided for @cacaColorJauneClair.
  ///
  /// In fr, this message translates to:
  /// **'Jaune clair'**
  String get cacaColorJauneClair;

  /// No description provided for @historyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get historyTitle;

  /// No description provided for @filterAll.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get filterAll;

  /// No description provided for @filterMiam.
  ///
  /// In fr, this message translates to:
  /// **'Miam'**
  String get filterMiam;

  /// No description provided for @filterDodo.
  ///
  /// In fr, this message translates to:
  /// **'Sommeil'**
  String get filterDodo;

  /// No description provided for @filterCaca.
  ///
  /// In fr, this message translates to:
  /// **'Caca'**
  String get filterCaca;

  /// No description provided for @filterSante.
  ///
  /// In fr, this message translates to:
  /// **'Santé'**
  String get filterSante;

  /// No description provided for @noEvents.
  ///
  /// In fr, this message translates to:
  /// **'Aucun événement'**
  String get noEvents;

  /// No description provided for @errorMessage.
  ///
  /// In fr, this message translates to:
  /// **'Erreur: {error}'**
  String errorMessage(Object error);

  /// No description provided for @typeLabelMiam.
  ///
  /// In fr, this message translates to:
  /// **'Miam'**
  String get typeLabelMiam;

  /// No description provided for @typeLabelSommeil.
  ///
  /// In fr, this message translates to:
  /// **'Sommeil'**
  String get typeLabelSommeil;

  /// No description provided for @typeLabelPipi.
  ///
  /// In fr, this message translates to:
  /// **'Pipi'**
  String get typeLabelPipi;

  /// No description provided for @typeLabelCaca.
  ///
  /// In fr, this message translates to:
  /// **'Caca'**
  String get typeLabelCaca;

  /// No description provided for @typeLabelPipiEtCaca.
  ///
  /// In fr, this message translates to:
  /// **'Pipi & Caca'**
  String get typeLabelPipiEtCaca;

  /// No description provided for @durationPrefix.
  ///
  /// In fr, this message translates to:
  /// **'Durée: {minutes} min'**
  String durationPrefix(Object minutes);

  /// No description provided for @editDialogTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l\'événement'**
  String get editDialogTitle;

  /// No description provided for @editDateSectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Date et heure'**
  String get editDateSectionTitle;

  /// No description provided for @editDurationSectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Durée'**
  String get editDurationSectionTitle;

  /// No description provided for @editTypeSectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Type'**
  String get editTypeSectionTitle;

  /// No description provided for @editPipiColorSectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Couleur du pipi'**
  String get editPipiColorSectionTitle;

  /// No description provided for @editCacaColorSectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Couleur du caca'**
  String get editCacaColorSectionTitle;

  /// No description provided for @editNotesLabel.
  ///
  /// In fr, this message translates to:
  /// **'Notes'**
  String get editNotesLabel;

  /// No description provided for @editNotesHint.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une note...'**
  String get editNotesHint;

  /// No description provided for @minutesHintText.
  ///
  /// In fr, this message translates to:
  /// **'Minutes'**
  String get minutesHintText;

  /// No description provided for @minuteSuffix.
  ///
  /// In fr, this message translates to:
  /// **'min'**
  String get minuteSuffix;

  /// No description provided for @deleteDialogTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer l\'événement'**
  String get deleteDialogTitle;

  /// No description provided for @deleteDialogContent.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vraiment supprimer cet événement ? Cette action est irréversible.'**
  String get deleteDialogContent;

  /// No description provided for @deleteButton.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get deleteButton;

  /// No description provided for @menuTitle.
  ///
  /// In fr, this message translates to:
  /// **'Menu'**
  String get menuTitle;

  /// No description provided for @settingsBodyText.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settingsBodyText;

  /// No description provided for @languageSectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get languageSectionTitle;

  /// No description provided for @languageEnglish.
  ///
  /// In fr, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageFrench.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// No description provided for @themeSectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Thème'**
  String get themeSectionTitle;

  /// No description provided for @themeSystem.
  ///
  /// In fr, this message translates to:
  /// **'Système'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In fr, this message translates to:
  /// **'Clair'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In fr, this message translates to:
  /// **'Sombre'**
  String get themeDark;

  /// No description provided for @dangerZoneTitle.
  ///
  /// In fr, this message translates to:
  /// **'Zone de danger'**
  String get dangerZoneTitle;

  /// No description provided for @resetDatabaseButton.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser la base de données'**
  String get resetDatabaseButton;

  /// No description provided for @resetDatabaseConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser la base de données ?'**
  String get resetDatabaseConfirm;

  /// No description provided for @resetDatabaseWarningDetail.
  ///
  /// In fr, this message translates to:
  /// **'Cette action supprimera définitivement tous les profils bébé, événements trackés et paramètres de rappels. Seules vos préférences de langue et thème seront conservées.'**
  String get resetDatabaseWarningDetail;

  /// No description provided for @resetDatabaseSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Base de données réinitialisée. Une nouvelle base a été créée.'**
  String get resetDatabaseSuccess;

  /// No description provided for @resetDatabaseError.
  ///
  /// In fr, this message translates to:
  /// **'Échec de la réinitialisation : {error}'**
  String resetDatabaseError(Object error);

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
