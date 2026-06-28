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
}
