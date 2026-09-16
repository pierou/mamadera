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
  String get routerPageNotFoundTitle => 'Page introuvable';

  @override
  String get routerBackToHome => 'Retour à l\'accueil';

  @override
  String get routerGenericError => 'Une erreur est survenue.';

  @override
  String get homeButtonMiam => 'Miam';

  @override
  String get homeButtonSante => 'Santé';

  @override
  String get homeButtonCaca => 'Caca';

  @override
  String get homeButtonDodo => 'Dodo';

  @override
  String feedbackFeedingWithQuantity(Object subtype, Object quantity) {
    return '$subtype · $quantity';
  }

  @override
  String feedbackFeedingWithoutQuantity(Object subtype) {
    return '$subtype';
  }

  @override
  String feedbackSleep(Object duration) {
    return 'Dodo · $duration min';
  }

  @override
  String feedbackPipi(Object color) {
    return '🟡 Pipi$color';
  }

  @override
  String feedbackCaca(Object color) {
    return '🟤 Caca$color';
  }

  @override
  String get feedbackBoth => '🟡🟤 Pipi & Caca';

  @override
  String get historyUpdatedSuccess => 'Événement mis à jour avec succès';

  @override
  String get historyDeletedSuccess => 'Événement supprimé';

  @override
  String historyUpdateError(Object error) {
    return 'Échec de la mise à jour : $error';
  }

  @override
  String historyDeleteError(Object error) {
    return 'Échec de la suppression : $error';
  }

  @override
  String get durationPickerTitle => 'Durée du sommeil';

  @override
  String get cancelButton => 'Annuler';

  @override
  String get confirmButton => 'Confirmer';

  @override
  String get saveButton => 'Enregistrer';

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
  String get reminderSettingsTile => 'Choisir les rappels affichés';

  @override
  String get reminderSettingsTitle => 'Rappels';

  @override
  String get reminderSettingsError => 'Échec du chargement des rappels';

  @override
  String get reminderSettingsDescription =>
      'Bandeaux affichés sur l\'accueil tant que le soin n\'a pas été saisi. Aucune notification système n\'est envoyée : tout reste sur cet appareil.';

  @override
  String get reminderFrequencyDaily => 'Tous les jours';

  @override
  String get reminderFrequencyWeekly => 'Chaque semaine';

  @override
  String reminderFrequencyMonthly(Object day) {
    return 'Le $day de chaque mois';
  }

  @override
  String reminderFrequencyEveryNDays(Object days) {
    return 'Tous les $days jours';
  }

  @override
  String get reminderCustomSectionTitle => 'Rappels personnalisés';

  @override
  String get reminderCustomSectionDescription =>
      'Un rappel s\'efface de l\'accueil dès que vous enregistrez le soin associé.';

  @override
  String get reminderCustomAdd => 'Ajouter un rappel';

  @override
  String get reminderCustomEmpty =>
      'Aucun rappel personnalisé pour l\'instant.';

  @override
  String get reminderCustomSheetAdd => 'Nouveau rappel';

  @override
  String get reminderCustomSheetEdit => 'Modifier le rappel';

  @override
  String get reminderCustomLabelField => 'Nom du rappel';

  @override
  String get reminderCustomLabelRequired => 'Donnez un nom au rappel';

  @override
  String get reminderCustomCareField => 'Soin associé';

  @override
  String get reminderCustomFrequencyField => 'Fréquence';

  @override
  String get reminderCustomIntervalField => 'Intervalle en jours';

  @override
  String get reminderCustomIntervalRequired =>
      'Indiquez un nombre de jours, de 1 à 365';

  @override
  String get reminderFrequencyMonthlyBirth =>
      'Le jour de naissance, chaque mois';

  @override
  String get reminderCustomDeleteConfirm => 'Supprimer ce rappel ?';

  @override
  String get reminderCustomDeleteWarning =>
      'Le rappel disparaît de l\'accueil. Les événements déjà enregistrés sont conservés.';

  @override
  String get reminderCustomSaveError =>
      'Le rappel n\'a pas pu être enregistré. Réessayez.';

  @override
  String get reminderCustomDeleteError =>
      'Le rappel n\'a pas pu être supprimé. Réessayez.';

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
  String get stoolTextureSectionTitle => 'Texture du caca';

  @override
  String get stoolTextureAqueuse => 'Aqueuse';

  @override
  String get stoolTextureGrumeleuse => 'Grumeleuse';

  @override
  String get stoolTexturePateuse => 'Pâteuse';

  @override
  String get stoolTextureMoulee => 'Moulée';

  @override
  String get stoolTextureDure => 'Dure';

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
  String quantityPrefix(Object quantity, Object unit) {
    return 'Quantité : $quantity $unit';
  }

  @override
  String get editQuantitySectionTitle => 'Quantité';

  @override
  String get quantityPickerTitle => 'Quantité';

  @override
  String get feedingQuantityLabel => 'Quantité';

  @override
  String get feedingQuantityHint => 'Sélectionner la quantité';

  @override
  String get feedingDialogTitle => 'Suivre l\'Alimentation';

  @override
  String get feedingSubtypeLabel => 'Type d\'Alimentation';

  @override
  String get feedingSubtypeNatural => 'Lait Maternel';

  @override
  String get feedingSubtypeArtificial => 'Lait Artificiel';

  @override
  String get editDialogTitle => 'Modifier l\'événement';

  @override
  String get eventDateSectionTitle => 'Date et heure';

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
  String get languageSpanish => 'Español';

  @override
  String get themeSectionTitle => 'Thème';

  @override
  String get themeSystem => 'Système';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get languageChanged => 'Langue changée';

  @override
  String get themeChanged => 'Thème mis à jour';

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
  String get closeButton => 'Fermer';

  @override
  String get exportDataTitle => 'Exporter mes données';

  @override
  String get exportDataDescription => 'Sauvegarde JSON de toutes vos données';

  @override
  String get exportDataConfirm => 'Exporter';

  @override
  String get exportDataWarning =>
      'Ce fichier contiendra toutes vos données, y compris les notes de santé en texte lisible. Vous choisissez où l\'enregistrer : rien n\'est envoyé automatiquement.';

  @override
  String get exportDataSuccess => 'Export terminé';

  @override
  String get exportDataError => 'L\'export a échoué';

  @override
  String get exportDataEmpty => 'Aucune donnée à exporter';

  @override
  String get importDataTitle => 'Restaurer depuis une sauvegarde';

  @override
  String get importDataDescription =>
      'Restaurez toutes vos données depuis un fichier JSON que vous avez exporté';

  @override
  String get importDataConfirm => 'Choisir un fichier…';

  @override
  String get importDataWarning =>
      'Cette action supprimera définitivement toutes les données actuellement sur cet appareil et les remplacera par le contenu du fichier. Choisissez le fichier que vous avez exporté.';

  @override
  String importDataSummary(int profiles, int events, int reminders) {
    return 'Ce fichier contient $profiles profil(s) bébé, $events événement(s) et $reminders rappel(s) personnalisé(s). Restaurer effacera toutes les données actuelles de cet appareil.';
  }

  @override
  String get importDataNoProfile =>
      'Attention : ce fichier ne contient aucun profil bébé. Les événements seront restaurés mais rattachés à aucun bébé, et il faudra créer un profil pour les voir.';

  @override
  String get importDataProceed => 'Restaurer';

  @override
  String importDataSuccess(int profiles, int events) {
    return 'Restauration terminée : $profiles profil(s) et $events événement(s)';
  }

  @override
  String get importDataErrorInvalidFile =>
      'Fichier non reconnu : ce n\'est pas une sauvegarde Mamadera valide.';

  @override
  String get importDataErrorNotMamadera =>
      'Ce fichier n\'a pas été créé par Mamadera.';

  @override
  String get importDataErrorNewerVersion =>
      'Ce fichier a été créé par une version plus récente de l\'application. Mettez à jour Mamadera avant de le restaurer.';

  @override
  String get importDataErrorNewerSchema =>
      'Ce fichier contient des données plus récentes que cette version de l\'application. Mettez à jour Mamadera avant de le restaurer.';

  @override
  String get importDataErrorEmpty =>
      'Ce fichier ne contient aucune donnée à restaurer.';

  @override
  String get importDataErrorUnreadable =>
      'Impossible de lire le fichier choisi.';

  @override
  String get importDataErrorFailed =>
      'Échec de la restauration. Vos données actuelles sont intactes.';

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
  String get activate => 'Activer';

  @override
  String get edit => 'Modifier';

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
  String babyAddedWithName(Object name) {
    return '\'$name\' ajouté';
  }

  @override
  String babyUpdatedWithName(Object name) {
    return '\'$name\' modifié';
  }

  @override
  String babyDeletedWithName(Object name) {
    return '\'$name\' supprimé';
  }

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
  String get onboardingSuccess => 'Profil bébé créé !';

  @override
  String get onboardingError => 'Échec de la création du profil bébé';

  @override
  String babyNameAlreadyExists(Object name) {
    return 'Un bébé nommé « $name » existe déjà.';
  }

  @override
  String get termsTitle => 'Conditions Générales';

  @override
  String get termsAcceptButton => 'J\'accepte';

  @override
  String get termsLoadingError =>
      'Échec du chargement des conditions. Veuillez réessayer.';

  @override
  String get patchNotesTitle => 'Nouvelles Fonctionnalités';

  @override
  String get patchNotesUnavailable => 'Aucune note de version disponible';

  @override
  String get patchNotesClose => 'Fermer';

  @override
  String get patchNotesDontShowAgain => 'Ne plus afficher';

  @override
  String get patchNotesWhatChanged => 'Ce qui a changé';

  @override
  String get patchNotesReleaseDate => 'Date de publication';

  @override
  String get patchNotesSkipCreateLater => 'Plutard - Créer un profil bébé';

  @override
  String get supportSectionTitle => 'Support';

  @override
  String get feedbackButtonTitle => 'Signaler un bug ou proposer une idée';

  @override
  String get feedbackTitle => 'Feedback';

  @override
  String get feedbackTypeBug => 'Bug';

  @override
  String get feedbackTypeError => 'Idée';

  @override
  String get feedbackTypeLabel => 'Type';

  @override
  String get feedbackTitleLabel => 'Titre';

  @override
  String get feedbackTitleHint => 'Résumé court du problème ou de l\'idée';

  @override
  String get feedbackDescriptionLabel => 'Description';

  @override
  String get feedbackDescriptionHint =>
      'Décrivez le bug ou votre suggestion en détail…';

  @override
  String get feedbackSubmitGitHub => 'Soumettre via GitHub';

  @override
  String get feedbackSubmitEmail => 'Soumettre par email';

  @override
  String get feedbackValidationTitle => 'Le titre est requis';

  @override
  String get feedbackValidationDescription => 'La description est requise';

  @override
  String get feedbackLaunchError =>
      'Impossible d\'ouvrir l\'application cible.';

  @override
  String get feedbackGitHubHint =>
      'Nécessite un compte GitHub. Si vous n\'êtes pas connecté, on vous le demandera.';

  @override
  String get aboutSectionTitle => 'À propos';

  @override
  String get aboutButtonTitle => 'Informations et crédits';

  @override
  String get aboutTitle => 'À propos de Mamadera';

  @override
  String get aboutVersionLabel => 'Version';

  @override
  String get aboutDescription =>
      'Application de suivi nouveau-née respectueuse de votre vie privée — sans télémétrie, sans cloud, vos données restent sur votre appareil.';

  @override
  String get aboutAttributionsSectionTitle => 'Crédits et attributions';

  @override
  String get aboutFlaticonCredit =>
      'Icône splash fournie par Flaticon (Magnific)';

  @override
  String get aboutLicenseLabel =>
      'Licence MIT — Code open source disponible sur GitHub';
}
