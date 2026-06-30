// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Mamadera';

  @override
  String get navHome => 'Accueil';

  @override
  String get navHistory => 'Historique';

  @override
  String get navMenu => 'Menu';

  @override
  String get homeButtonMiam => 'Miam';

  @override
  String get homeButtonSante => 'Santé';

  @override
  String get homeButtonCaca => 'Caca';

  @override
  String get homeButtonDodo => 'Dodo';

  @override
  String get durationPickerTitle => 'Durée du sommeil';

  @override
  String get cancelButton => 'Annuler';

  @override
  String get confirmButton => 'Confirmer';

  @override
  String durationFormatHoursMinutes(Object hours, Object minutes) {
    return '${hours}h$minutes';
  }

  @override
  String durationFormatMinutes(Object minutes) {
    return '$minutes min';
  }

  @override
  String get healthSubtypeDialogTitle => 'Type de soin';

  @override
  String get saveButton => 'Enregistrer';

  @override
  String get healthSubtypeRequiredError =>
      'Veuillez sélectionner un type de soin';

  @override
  String get healthNettoyageYeux => 'Nettoyage des yeux';

  @override
  String get healthNettoyageNombril => 'Nettoyage du nombril';

  @override
  String get healthNettoyageVisage => 'Nettoyage du visage';

  @override
  String get healthNettoyageNez => 'Nettoyage du nez';

  @override
  String get healthVitamineD => 'Vitamine D';

  @override
  String get healthVitamineK => 'Vitamine K';

  @override
  String get wasteDialogTitle => 'Type de selle';

  @override
  String get pipiColorSectionTitle => 'Couleur du pipi';

  @override
  String get cacaColorSectionTitle => 'Couleur du caca';

  @override
  String get wasteTypePipi => '🟡 Pipi';

  @override
  String get wasteTypeCaca => '🟤 Caca';

  @override
  String get wasteTypeLesDeux => '🟡🟤 Les deux';

  @override
  String get pipiColorIncolore => 'Incolore';

  @override
  String get pipiColorJauneClair => 'Jaune clair';

  @override
  String get pipiColorJauneFonce => 'Jaune foncé';

  @override
  String get pipiColorRoseUrates => 'Rose/Orange (urates)';

  @override
  String get cacaColorMeconium => 'Mécônium';

  @override
  String get cacaColorVertOlive => 'Vert olive';

  @override
  String get cacaColorJauneMoutarde => 'Jaune moutarde';

  @override
  String get cacaColorJauneClair => 'Jaune clair';

  @override
  String get historyTitle => 'Historique';

  @override
  String get filterAll => 'Tous';

  @override
  String get filterMiam => 'Miam';

  @override
  String get filterDodo => 'Sommeil';

  @override
  String get filterCaca => 'Caca';

  @override
  String get filterSante => 'Santé';

  @override
  String get noEvents => 'Aucun événement';

  @override
  String errorMessage(Object error) {
    return 'Erreur: $error';
  }

  @override
  String get typeLabelMiam => 'Miam';

  @override
  String get typeLabelSommeil => 'Sommeil';

  @override
  String get typeLabelPipi => 'Pipi';

  @override
  String get typeLabelCaca => 'Caca';

  @override
  String get typeLabelPipiEtCaca => 'Pipi & Caca';

  @override
  String durationPrefix(Object minutes) {
    return 'Durée: $minutes min';
  }

  @override
  String get editDialogTitle => 'Modifier l\'événement';

  @override
  String get editDateSectionTitle => 'Date et heure';

  @override
  String get editDurationSectionTitle => 'Durée';

  @override
  String get editTypeSectionTitle => 'Type';

  @override
  String get editPipiColorSectionTitle => 'Couleur du pipi';

  @override
  String get editCacaColorSectionTitle => 'Couleur du caca';

  @override
  String get editNotesLabel => 'Notes';

  @override
  String get editNotesHint => 'Ajouter une note...';

  @override
  String get minutesHintText => 'Minutes';

  @override
  String get minuteSuffix => 'min';

  @override
  String get deleteDialogTitle => 'Supprimer l\'événement';

  @override
  String get deleteDialogContent =>
      'Voulez-vous vraiment supprimer cet événement ? Cette action est irréversible.';

  @override
  String get deleteButton => 'Supprimer';

  @override
  String get menuTitle => 'Menu';

  @override
  String get settingsBodyText => 'Paramètres';

  @override
  String get languageSectionTitle => 'Langue';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageFrench => 'Français';

  @override
  String get themeSectionTitle => 'Thème';

  @override
  String get themeSystem => 'Système';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';
}
