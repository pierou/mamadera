// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Mamadera';

  @override
  String get navHome => 'Home';

  @override
  String get navHistory => 'History';

  @override
  String get navMenu => 'Menu';

  @override
  String get homeButtonMiam => 'Feeding';

  @override
  String get homeButtonSante => 'Health';

  @override
  String get homeButtonCaca => 'Diaper';

  @override
  String get homeButtonDodo => 'Sleep';

  @override
  String get durationPickerTitle => 'Sleep Duration';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get confirmButton => 'Confirm';

  @override
  String durationFormatHoursMinutes(Object hours, Object minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String durationFormatMinutes(Object minutes) {
    return '$minutes min';
  }

  @override
  String get healthSubtypeDialogTitle => 'Care Type';

  @override
  String get saveButton => 'Save';

  @override
  String get healthSubtypeRequiredError => 'Please select a care type';

  @override
  String get healthNettoyageYeux => 'Eye Cleaning';

  @override
  String get healthNettoyageNombril => 'Navel Care';

  @override
  String get healthNettoyageVisage => 'Face Cleaning';

  @override
  String get healthNettoyageNez => 'Nose Cleaning';

  @override
  String get healthVitamineD => 'Vitamin D';

  @override
  String get healthVitamineK => 'Vitamin K';

  @override
  String get reminderVitaminD => 'Vit. D';

  @override
  String get reminderVitaminK => 'Vit. K';

  @override
  String get reminderEyeCleaning => 'Eyes';

  @override
  String get reminderFaceCleaning => 'Face';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get daysAgo => ' days ago';

  @override
  String get lastTracked => 'Last tracked: ';

  @override
  String get wasteDialogTitle => 'Diaper Type';

  @override
  String get pipiColorSectionTitle => 'Urine Color';

  @override
  String get cacaColorSectionTitle => 'Stool Color';

  @override
  String get wasteTypePipi => '🟡 Pee';

  @override
  String get wasteTypeCaca => '🟤 Poop';

  @override
  String get wasteTypeLesDeux => '🟡🟤 Both';

  @override
  String get pipiColorIncolore => 'Clear';

  @override
  String get pipiColorJauneClair => 'Light Yellow';

  @override
  String get pipiColorJauneFonce => 'Dark Yellow';

  @override
  String get pipiColorRoseUrates => 'Pink/Orange (urates)';

  @override
  String get cacaColorMeconium => 'Meconium';

  @override
  String get cacaColorVertOlive => 'Olive Green';

  @override
  String get cacaColorJauneMoutarde => 'Mustard Yellow';

  @override
  String get cacaColorJauneClair => 'Light Yellow';

  @override
  String get historyTitle => 'History';

  @override
  String get filterAll => 'All';

  @override
  String get filterMiam => 'Feeding';

  @override
  String get filterDodo => 'Sleep';

  @override
  String get filterCaca => 'Diaper';

  @override
  String get filterSante => 'Health';

  @override
  String get noEvents => 'No events';

  @override
  String errorMessage(Object error) {
    return 'Error: $error';
  }

  @override
  String get typeLabelMiam => 'Feeding';

  @override
  String get typeLabelSommeil => 'Sleep';

  @override
  String get typeLabelPipi => 'Pee';

  @override
  String get typeLabelCaca => 'Poop';

  @override
  String get typeLabelPipiEtCaca => 'Pee & Poop';

  @override
  String durationPrefix(Object minutes) {
    return 'Duration: $minutes min';
  }

  @override
  String get editDialogTitle => 'Edit Event';

  @override
  String get editDateSectionTitle => 'Date and Time';

  @override
  String get editDurationSectionTitle => 'Duration';

  @override
  String get editTypeSectionTitle => 'Type';

  @override
  String get editPipiColorSectionTitle => 'Urine Color';

  @override
  String get editCacaColorSectionTitle => 'Stool Color';

  @override
  String get editNotesLabel => 'Notes';

  @override
  String get editNotesHint => 'Add a note...';

  @override
  String get minutesHintText => 'Minutes';

  @override
  String get minuteSuffix => 'min';

  @override
  String get deleteDialogTitle => 'Delete Event';

  @override
  String get deleteDialogContent =>
      'Are you sure you want to delete this event? This action cannot be undone.';

  @override
  String get deleteButton => 'Delete';

  @override
  String get menuTitle => 'Menu';

  @override
  String get settingsBodyText => 'Settings';

  @override
  String get languageSectionTitle => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageFrench => 'Français';

  @override
  String get themeSectionTitle => 'Theme';

  @override
  String get themeSystem => 'Follow system';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get dangerZoneTitle => 'Danger Zone';

  @override
  String get resetDatabaseButton => 'Reset Database';

  @override
  String get resetDatabaseConfirm => 'Reset Database?';

  @override
  String get resetDatabaseWarningDetail =>
      'This will permanently delete all baby profiles, tracking events, and reminder settings. Only your language and theme settings will be kept.';

  @override
  String get resetDatabaseSuccess =>
      'Database reset. A fresh database has been created.';

  @override
  String resetDatabaseError(Object error) {
    return 'Failed to reset: $error';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get babyProfilesSectionTitle => 'Babies';

  @override
  String get babyProfilesEmpty => 'No baby profiles yet';

  @override
  String get babyProfilesError => 'Failed to load baby profiles';

  @override
  String get addBaby => 'Add Baby';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get babyName => 'Baby Name';

  @override
  String get birthDate => 'Birth Date';

  @override
  String get update => 'Update';

  @override
  String get activate => 'Activate';

  @override
  String get edit => 'Edit';

  @override
  String get babyAddedSuccess => 'Baby profile added successfully';

  @override
  String get babyAddError => 'Failed to add baby profile';

  @override
  String get babyUpdatedSuccess => 'Baby profile updated successfully';

  @override
  String get babyUpdateError => 'Failed to update baby profile';

  @override
  String get babyDeletedSuccess => 'Baby profile deleted';

  @override
  String get babyDeleteError => 'Failed to delete baby profile';

  @override
  String get deleteBabyConfirm => 'Delete Baby Profile?';

  @override
  String deleteBabyWarning(Object formatName) {
    return 'Are you sure you want to delete \'$formatName\'?';
  }

  @override
  String get deleteBabyDataWarning =>
      'All tracking events for this baby will also be deleted.';

  @override
  String get delete => 'Delete';

  @override
  String get dayOld => 'day old';

  @override
  String get daysOld => 'days old';

  @override
  String get monthOld => 'month old';

  @override
  String get monthsOld => 'months old';

  @override
  String get yearOld => 'year old';

  @override
  String get yearsOld => 'years old';

  @override
  String get onboardingWelcome => 'Welcome to Mamadera!';

  @override
  String get onboardingSubtitle =>
      'Create your first baby profile to get started.';

  @override
  String get onboardingNameHint => 'Baby\'s name';

  @override
  String get onboardingSaveAndContinue => 'Save & Continue';

  @override
  String get onboardingSuccess => 'Baby profile created!';

  @override
  String get onboardingError => 'Failed to create baby profile';
}
