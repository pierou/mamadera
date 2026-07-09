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
  String get reminderVitaminD => 'Vit. D';

  @override
  String get reminderVitaminK => 'Vit. K';

  @override
  String get reminderEyeCleaning => 'Yeux';

  @override
  String get reminderFaceCleaning => 'Visage';

  @override
  String get yesterday => 'Hier';

  @override
  String get daysAgo => ' jours';

  @override
  String get lastTracked => 'Dernière activité: ';

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

  @override
  String get dangerZoneTitle => 'Zone de danger';

  @override
  String get resetDatabaseButton => 'Réinitialiser la base de données';

  @override
  String get resetDatabaseConfirm => 'Réinitialiser la base de données ?';

  @override
  String get resetDatabaseWarningDetail =>
      'Cette action supprimera définitivement tous les profils bébé, événements trackés et paramètres de rappels. Seules vos préférences de langue et thème seront conservées.';

  @override
  String get resetDatabaseSuccess =>
      'Base de données réinitialisée. Une nouvelle base a été créée.';

  @override
  String resetDatabaseError(Object error) {
    return 'Échec de la réinitialisation : $error';
  }

  @override
  String get cancel => 'Annuler';

  @override
  String get babyProfilesSectionTitle => 'Bébés';

  @override
  String get babyProfilesEmpty => 'Aucun profil bébé';

  @override
  String get babyProfilesError => 'Échec du chargement des profils';

  @override
  String get addBaby => 'Ajouter un bébé';

  @override
  String get editProfile => 'Modifier le profil';

  @override
  String get babyName => 'Nom du bébé';

  @override
  String get birthDate => 'Date de naissance';

  @override
  String get update => 'Modifier';

  @override
  String get babyAddedSuccess => 'Profil bébé ajouté avec succès';

  @override
  String get babyAddError => 'Échec de l\'ajout du profil bébé';

  @override
  String get babyUpdatedSuccess => 'Profil bébé modifié avec succès';

  @override
  String get babyUpdateError => 'Échec de la modification du profil bébé';

  @override
  String get babyDeletedSuccess => 'Profil bébé supprimé';

  @override
  String get babyDeleteError => 'Échec de la suppression du profil bébé';

  @override
  String get deleteBabyConfirm => 'Supprimer le profil bébé ?';

  @override
  String deleteBabyWarning(Object formatName) {
    return 'Voulez-vous vraiment supprimer \'$formatName\' ?';
  }

  @override
  String get deleteBabyDataWarning =>
      'Tous les événements trackés pour ce bébé seront également supprimés.';

  @override
  String get delete => 'Supprimer';

  @override
  String get dayOld => 'jour';

  @override
  String get daysOld => 'jours';

  @override
  String get monthOld => 'mois';

  @override
  String get monthsOld => 'mois';

  @override
  String get yearOld => 'an';

  @override
  String get yearsOld => 'ans';

  @override
  String get onboardingWelcome => 'Bienvenue sur Mamadera !';

  @override
  String get onboardingSubtitle =>
      'Créez le premier profil bébé pour commencer.';

  @override
  String get onboardingNameHint => 'Nom du bébé';

  @override
  String get onboardingSaveAndContinue => 'Enregistrer & Continuer';

  @override
  String get onboardingSuccess => 'Profil bébé créé !';

  @override
  String get onboardingError => 'Échec de la création du profil bébé';
}
