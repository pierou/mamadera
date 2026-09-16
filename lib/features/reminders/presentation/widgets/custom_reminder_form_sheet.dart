import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets/dialog_buttons.dart';
import '../../../../shared/domain/entities/tracking_enums.dart';
import '../../../../shared/utils/health_label_resolver.dart';
import '../../domain/entities/custom_reminder.dart';
import '../../domain/entities/reminder_frequency.dart';

/// Rythmes proposés à la création d'un rappel.
///
/// Quatre, pas plus : ce sont les quatre que `isDue` sait évaluer. Un rythme
/// « chaque mardi à 20 h » demanderait une horloge et une notification système,
/// deux choses que cette app n'a pas.
enum CustomReminderFrequencyChoice { daily, weekly, monthlyBirth, everyNDays }

/// Formulaire d'un rappel personnalisé, en feuille modale.
///
/// Ne fait aucun écrit : il construit un [CustomReminder] et le rend au
/// Navigator. L'écran qui l'a ouvert décide de créer ou modifier, et passe par
/// le notifieur — c'est le seul chemin qui invalide les pastilles de l'accueil.
class CustomReminderFormSheet extends StatefulWidget {
  const CustomReminderFormSheet({this.existing, super.key});

  /// Rappel à préremplir ; `null` pour une création.
  final CustomReminder? existing;

  @override
  State<CustomReminderFormSheet> createState() => _CustomReminderFormSheetState();
}

class _CustomReminderFormSheetState extends State<CustomReminderFormSheet> {
  /// Borne haute de l'intervalle : au-delà d'un an, le parent veut une date,
  /// pas un rappel.
  static const int _maxIntervalDays = 365;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelController;
  late final TextEditingController _daysController;
  late String _subtypeValue;
  late CustomReminderFrequencyChoice _choice;

  /// Intervalle par défaut proposé à la création : trois jours, le rythme
  /// d'une application de crème sur avis médical, le plus courant demandé.
  static const int _defaultIntervalDays = 3;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _labelController = TextEditingController(text: existing?.label ?? '');
    _subtypeValue = existing?.subtypeValue ?? HealthSubtype.nettoyageNez.value;
    _choice = _choiceOf(existing?.frequency);
    // Seul un roulement porte un nombre de jours à préremplir ; les autres
    // rythmes partent sur l'intervalle par défaut, invisible tant que le choix
    // est ailleurs.
    final storedDays = existing?.frequency.map(
      daily: (_) => null,
      weekly: (_) => null,
      monthly: (_) => null,
      customInterval: (f) => f.days,
    );
    _daysController = TextEditingController(
      text: '${storedDays ?? _defaultIntervalDays}',
    );
  }

  /// Intervalle demandé, borné à [1, _maxIntervalDays].
  ///
  /// Une saisie illisible remonte à l'intervalle par défaut plutôt que de
  /// bloquer : le validateur du champ a déjà eu sa chance, et un rappel créé
  /// reste modifiable.
  int get _intervalDays =>
      (int.tryParse(_daysController.text) ?? _defaultIntervalDays)
          .clamp(1, _maxIntervalDays);

  CustomReminderFrequencyChoice _choiceOf(ReminderFrequency? frequency) {
    return switch (frequency) {
      CustomInterval() => CustomReminderFrequencyChoice.everyNDays,
      Weekly() => CustomReminderFrequencyChoice.weekly,
      Monthly() => CustomReminderFrequencyChoice.monthlyBirth,
      _ => CustomReminderFrequencyChoice.daily,
    };
  }

  @override
  void dispose() {
    _labelController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final frequency = switch (_choice) {
      CustomReminderFrequencyChoice.daily => const ReminderFrequency.daily(),
      // Le jour de semaine n'est pas demandé : `isDue` l'ignore (achever un
      // rappel hebdo le fait attendre à la semaine suivante, quel que soit le
      // jour), et proposer « mardi » pour un rappel qui sonne aussi le vendredi
      // serait un mensonge.
      CustomReminderFrequencyChoice.weekly => const ReminderFrequency.weekly(
          dayOfWeek: 1,
        ),
      // Aucun jour n'est choisi ici : le jour est celui de naissance du bébé
      // actif, lu à l'affichage comme pour la vitamine K.
      CustomReminderFrequencyChoice.monthlyBirth => const ReminderFrequency.monthly(
          dayOfMonth: CustomReminderPresets.monthlyFallbackDay,
        ),
      CustomReminderFrequencyChoice.everyNDays => ReminderFrequency.customInterval(
          days: _intervalDays,
        ),
    };

    Navigator.of(context).pop(
      CustomReminder(
        label: _labelController.text.trim(),
        subtypeValue: _subtypeValue,
        frequency: frequency,
        id: widget.existing?.id,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.existing;

    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.spacingXxl,
        right: AppTheme.spacingXxl,
        top: AppTheme.spacingXl,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppTheme.spacingXl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              existing == null
                  ? context.l.reminderCustomSheetAdd
                  : context.l.reminderCustomSheetEdit,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.spacingXl),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabelField(),
                  const SizedBox(height: AppTheme.spacingLg),
                  _buildCareField(),
                  const SizedBox(height: AppTheme.spacingLg),
                  _buildFrequencyField(),
                  if (_choice == CustomReminderFrequencyChoice.everyNDays) ...[
                    const SizedBox(height: AppTheme.spacingLg),
                    _buildIntervalField(),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingXl),
            DialogActionButtons(
              cancelLabel: context.l.cancelButton,
              confirmLabel: context.l.confirmButton,
              onCancelPressed: () => Navigator.of(context).pop(),
              onConfirmPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabelField() {
    return TextFormField(
      controller: _labelController,
      maxLength: 60,
      textCapitalization: TextCapitalization.sentences,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: context.l.reminderCustomLabelField,
        counterText: '',
        border: const OutlineInputBorder(),
      ),
      validator: (value) => (value ?? '').trim().isEmpty
          ? context.l.reminderCustomLabelRequired
          : null,
    );
  }

  Widget _buildCareField() {
    return DropdownButtonFormField<String>(
      initialValue: _subtypeValue,
      decoration: InputDecoration(
        labelText: context.l.reminderCustomCareField,
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final subtype in HealthSubtype.values)
          DropdownMenuItem(
            value: subtype.value,
            child: Text(resolveHealthLabel(context, subtype)),
          ),
      ],
      onChanged: (value) {
        if (value != null) _subtypeValue = value;
      },
    );
  }

  Widget _buildFrequencyField() {
    return DropdownButtonFormField<CustomReminderFrequencyChoice>(
      initialValue: _choice,
      decoration: InputDecoration(
        labelText: context.l.reminderCustomFrequencyField,
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final choice in CustomReminderFrequencyChoice.values)
          DropdownMenuItem(
            value: choice,
            child: Text(_frequencyChoiceLabel(choice)),
          ),
      ],
      onChanged: (value) {
        if (value == null) return;
        // Le champ « nombre de jours » n'existe que pour un roulement.
        setState(() => _choice = value);
      },
    );
  }

  Widget _buildIntervalField() {
    return TextFormField(
      controller: _daysController,
      keyboardType: TextInputType.number,
      maxLength: 3,
      decoration: InputDecoration(
        labelText: context.l.reminderCustomIntervalField,
        counterText: '',
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        final days = int.tryParse((value ?? '').trim());
        if (days == null || days < 1 || days > _maxIntervalDays) {
          return context.l.reminderCustomIntervalRequired;
        }
        return null;
      },
    );
  }

  /// Wording d'un choix de rythme dans la liste déroulante.
  ///
  /// Le roulement emprunte le libellé du champ « Intervalle en jours » plutôt que
  /// « Tous les N jours » : le nombre n'est pas encore saisi à cet endroit, et lui
  /// en afficher un figerait un décalage entre la liste et le champ.
  String _frequencyChoiceLabel(CustomReminderFrequencyChoice choice) {
    return switch (choice) {
      CustomReminderFrequencyChoice.daily => context.l.reminderFrequencyDaily,
      CustomReminderFrequencyChoice.weekly => context.l.reminderFrequencyWeekly,
      CustomReminderFrequencyChoice.monthlyBirth =>
        context.l.reminderFrequencyMonthlyBirth,
      CustomReminderFrequencyChoice.everyNDays =>
        context.l.reminderCustomIntervalField,
    };
  }
}
