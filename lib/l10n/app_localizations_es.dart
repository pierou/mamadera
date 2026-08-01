// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Mamadera';

  @override
  String get navHome => 'Inicio';

  @override
  String get navHistory => 'Historial';

  @override
  String get navMenu => 'Menú';

  @override
  String get homeButtonMiam => 'Alimento';

  @override
  String get homeButtonSante => 'Salud';

  @override
  String get homeButtonCaca => 'Pañal';

  @override
  String get homeButtonDodo => 'Sueño';

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
    return 'Sueño · $duration min';
  }

  @override
  String feedbackPipi(Object color) {
    return '🟡 Orina$color';
  }

  @override
  String feedbackCaca(Object color) {
    return '🟤 Caca$color';
  }

  @override
  String get feedbackBoth => '🟡🟤 Orina y Caca';

  @override
  String get historyUpdatedSuccess => 'Evento actualizado correctamente';

  @override
  String get historyDeletedSuccess => 'Evento eliminado';

  @override
  String historyUpdateError(Object error) {
    return 'No se pudo actualizar: $error';
  }

  @override
  String historyDeleteError(Object error) {
    return 'No se pudo eliminar: $error';
  }

  @override
  String get durationPickerTitle => 'Duración del sueño';

  @override
  String get cancelButton => 'Cancelar';

  @override
  String get confirmButton => 'Confirmar';

  @override
  String get saveButton => 'Guardar';

  @override
  String durationFormatHoursMinutes(Object hours, Object minutes) {
    return '${hours}h$minutes';
  }

  @override
  String durationFormatMinutes(Object minutes) {
    return '$minutes min';
  }

  @override
  String get healthSubtypeDialogTitle => 'Tipo de cuidado';

  @override
  String get healthSubtypeRequiredError => 'Selecciona un tipo de cuidado';

  @override
  String get healthNettoyageYeux => 'Limpieza de ojos';

  @override
  String get healthNettoyageNombril => 'Limpieza del ombligo';

  @override
  String get healthNettoyageVisage => 'Limpieza del rostro';

  @override
  String get healthNettoyageNez => 'Limpieza de nariz';

  @override
  String get healthVitamineD => 'Vitamina D';

  @override
  String get healthVitamineK => 'Vitamina K';

  @override
  String get reminderVitaminD => 'Vit. D';

  @override
  String get reminderVitaminK => 'Vit. K';

  @override
  String get reminderEyeCleaning => 'Ojos';

  @override
  String get reminderFaceCleaning => 'Rostro';

  @override
  String get yesterday => 'Ayer';

  @override
  String get daysAgo => ' días';

  @override
  String get lastTracked => 'Última actividad: ';

  @override
  String get wasteDialogTitle => 'Tipo de pañal';

  @override
  String get pipiColorSectionTitle => 'Color de la orina';

  @override
  String get cacaColorSectionTitle => 'Color de la caca';

  @override
  String get wasteTypePipi => '🟡 Orina';

  @override
  String get wasteTypeCaca => '🟤 Caca';

  @override
  String get wasteTypeLesDeux => '🟡🟤 Ambos';

  @override
  String get pipiColorIncolore => 'Transparente';

  @override
  String get pipiColorJauneClair => 'Amarillo claro';

  @override
  String get pipiColorJauneFonce => 'Amarillo oscuro';

  @override
  String get pipiColorRoseUrates => 'Rosado/Naranja (uratos)';

  @override
  String get cacaColorMeconium => 'Meconio';

  @override
  String get cacaColorVertOlive => 'Verde oliva';

  @override
  String get cacaColorJauneMoutarde => 'Amarillo mostaza';

  @override
  String get cacaColorJauneClair => 'Amarillo claro';

  @override
  String get historyTitle => 'Historial';

  @override
  String get filterAll => 'Todos';

  @override
  String get filterMiam => 'Alimento';

  @override
  String get filterDodo => 'Sueño';

  @override
  String get filterCaca => 'Pañal';

  @override
  String get filterSante => 'Salud';

  @override
  String get noEvents => 'Sin eventos';

  @override
  String errorMessage(Object error) {
    return 'Error: $error';
  }

  @override
  String get typeLabelMiam => 'Alimento';

  @override
  String get typeLabelSommeil => 'Sueño';

  @override
  String get typeLabelPipi => 'Orina';

  @override
  String get typeLabelCaca => 'Caca';

  @override
  String get typeLabelPipiEtCaca => 'Orina y Caca';

  @override
  String durationPrefix(Object minutes) {
    return 'Duración: $minutes min';
  }

  @override
  String quantityPrefix(Object quantity, Object unit) {
    return 'Cantidad: $quantity $unit';
  }

  @override
  String get editQuantitySectionTitle => 'Cantidad';

  @override
  String get quantityPickerTitle => 'Cantidad';

  @override
  String get feedingQuantityLabel => 'Cantidad';

  @override
  String get feedingQuantityHint => 'Seleccionar la cantidad';

  @override
  String get feedingDialogTitle => 'Registrar Alimentación';

  @override
  String get feedingSubtypeLabel => 'Tipo de Alimentación';

  @override
  String get feedingSubtypeNatural => 'Leche Materna';

  @override
  String get feedingSubtypeArtificial => 'Fórmula Infantil';

  @override
  String get editDialogTitle => 'Editar evento';

  @override
  String get editDateSectionTitle => 'Fecha y hora';

  @override
  String get editDurationSectionTitle => 'Duración';

  @override
  String get editTypeSectionTitle => 'Tipo';

  @override
  String get editPipiColorSectionTitle => 'Color de la orina';

  @override
  String get editCacaColorSectionTitle => 'Color de la caca';

  @override
  String get editNotesLabel => 'Notas';

  @override
  String get editNotesHint => 'Añadir una nota...';

  @override
  String get minutesHintText => 'Minutos';

  @override
  String get minuteSuffix => 'min';

  @override
  String get deleteDialogTitle => 'Eliminar evento';

  @override
  String get deleteDialogContent =>
      '¿Estás seguro de que quieres eliminar este evento? Esta acción no se puede deshacer.';

  @override
  String get deleteButton => 'Eliminar';

  @override
  String get menuTitle => 'Menú';

  @override
  String get settingsBodyText => 'Ajustes';

  @override
  String get languageSectionTitle => 'Idioma';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageSpanish => 'Español';

  @override
  String get themeSectionTitle => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get dangerZoneTitle => 'Zona de peligro';

  @override
  String get resetDatabaseButton => 'Restablecer la base de datos';

  @override
  String get resetDatabaseConfirm => '¿Restablecer la base de datos?';

  @override
  String get resetDatabaseWarningDetail =>
      'Esta acción eliminará permanentemente todos los perfiles de bebé, eventos registrados y configuraciones de recordatorios. Solo se conservarán tus preferencias de idioma y tema.';

  @override
  String get resetDatabaseSuccess =>
      'Base de datos restablecida. Se ha creado una nueva base.';

  @override
  String resetDatabaseError(Object error) {
    return 'No se pudo restablecer: $error';
  }

  @override
  String get cancel => 'Cancelar';

  @override
  String get closeButton => 'Cerrar';

  @override
  String get babyProfilesSectionTitle => 'Bebés';

  @override
  String get babyProfilesEmpty => 'Sin perfiles de bebé';

  @override
  String get babyProfilesError => 'No se pudieron cargar los perfiles';

  @override
  String get addBaby => 'Añadir un bebé';

  @override
  String get editProfile => 'Editar perfil';

  @override
  String get babyName => 'Nombre del bebé';

  @override
  String get birthDate => 'Fecha de nacimiento';

  @override
  String get update => 'Modificar';

  @override
  String get activate => 'Activar';

  @override
  String get edit => 'Editar';

  @override
  String get babyAddedSuccess => 'Perfil de bebé añadido correctamente';

  @override
  String get babyAddError => 'No se pudo añadir el perfil de bebé';

  @override
  String get babyUpdatedSuccess => 'Perfil de bebé modificado correctamente';

  @override
  String get babyUpdateError => 'No se pudo modificar el perfil de bebé';

  @override
  String get babyDeletedSuccess => 'Perfil de bebé eliminado';

  @override
  String get babyDeleteError => 'No se pudo eliminar el perfil de bebé';

  @override
  String babyAddedWithName(Object name) {
    return '\'$name\' añadido';
  }

  @override
  String babyUpdatedWithName(Object name) {
    return '\'$name\' modificado';
  }

  @override
  String babyDeletedWithName(Object name) {
    return '\'$name\' eliminado';
  }

  @override
  String get deleteBabyConfirm => '¿Eliminar perfil de bebé?';

  @override
  String deleteBabyWarning(Object formatName) {
    return '¿Estás seguro de que quieres eliminar a \'$formatName\'?';
  }

  @override
  String get deleteBabyDataWarning =>
      'Todos los eventos registrados para este bebé también se eliminarán.';

  @override
  String get delete => 'Eliminar';

  @override
  String get dayOld => 'día';

  @override
  String get daysOld => 'días';

  @override
  String get monthOld => 'mes';

  @override
  String get monthsOld => 'meses';

  @override
  String get yearOld => 'año';

  @override
  String get yearsOld => 'años';

  @override
  String get onboardingWelcome => '¡Bienvenido/a a Mamadera!';

  @override
  String get onboardingSubtitle =>
      'Crea el primer perfil de bebé para comenzar.';

  @override
  String get onboardingNameHint => 'Nombre del bebé';

  @override
  String get onboardingSuccess => '¡Perfil de bebé creado!';

  @override
  String get onboardingError => 'No se pudo crear el perfil de bebé';

  @override
  String babyNameAlreadyExists(Object name) {
    return 'Ya existe un bebé con el nombre «$name».';
  }

  @override
  String get termsTitle => 'Términos y Condiciones';

  @override
  String get termsAcceptButton => 'Acepto';

  @override
  String get termsLoadingError =>
      'No se pudieron cargar los términos. Inténtalo de nuevo.';

  @override
  String get patchNotesTitle => 'Novedades';

  @override
  String get patchNotesClose => 'Cerrar';

  @override
  String get patchNotesDontShowAgain => 'No volver a mostrar';

  @override
  String get patchNotesWhatChanged => 'Qué ha cambiado';

  @override
  String get patchNotesReleaseDate => 'Fecha de publicación';

  @override
  String get patchNotesSkipCreateLater => 'Después — Crear perfil de bebé';

  @override
  String get supportSectionTitle => 'Soporte';

  @override
  String get feedbackButtonTitle => 'Reportar un error o sugerir una idea';

  @override
  String get feedbackTitle => 'Comentarios';

  @override
  String get feedbackTypeBug => 'Error';

  @override
  String get feedbackTypeError => 'Idea';

  @override
  String get feedbackTypeLabel => 'Tipo';

  @override
  String get feedbackTitleLabel => 'Título';

  @override
  String get feedbackTitleHint => 'Resumen breve del problema o la idea';

  @override
  String get feedbackDescriptionLabel => 'Descripción';

  @override
  String get feedbackDescriptionHint =>
      'Describe el error o tu sugerencia en detalle…';

  @override
  String get feedbackSubmitGitHub => 'Enviar por GitHub';

  @override
  String get feedbackSubmitEmail => 'Enviar por email';

  @override
  String get feedbackValidationTitle => 'El título es obligatorio';

  @override
  String get feedbackValidationDescription => 'La descripción es obligatoria';

  @override
  String get feedbackLaunchError => 'No se puede abrir la aplicación destino.';

  @override
  String get feedbackGitHubHint =>
      'Requiere una cuenta de GitHub. Si no has iniciado sesión, te lo pedirá.';

  @override
  String get aboutSectionTitle => 'Acerca de';

  @override
  String get aboutButtonTitle => 'Información y créditos';

  @override
  String get aboutTitle => 'Acerca de Mamadera';

  @override
  String get aboutVersionLabel => 'Versión';

  @override
  String get aboutDescription =>
      'Aplicación de seguimiento para recién nacidos respetuosa con su privacidad — sin telemetría, sin nube, sus datos permanecen en su dispositivo.';

  @override
  String get aboutAttributionsSectionTitle => 'Créditos y atribuciones';

  @override
  String get aboutFlaticonCredit =>
      'Icono splash proporcionado por Flaticon (Magnific)';

  @override
  String get aboutLicenseLabel =>
      'Licencia MIT — Código fuente abierto disponible en GitHub';
}
