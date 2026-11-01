import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/providers/active_baby_provider.dart';
import '../../../../core/providers/any_baby_exists_provider.dart';
import '../../../../core/widgets/dialog_buttons.dart';
import '../../../../core/widgets/show_feedback.dart';
import '../../../../features/baby/presentation/providers/baby_profile_providers.dart';
import '../../../../features/reminders/presentation/providers/reminder_sync_notifier.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/domain/entities/baby_profile.dart';

/// Onboarding dialog shown on first launch when no baby profiles exist.
///
/// Allows the user to create their first baby profile quickly.
class OnboardingDialog extends ConsumerStatefulWidget {
  const OnboardingDialog({super.key});

  @override
  ConsumerState<OnboardingDialog> createState() => _OnboardingDialogState();
}

class _OnboardingDialogState extends ConsumerState<OnboardingDialog> {
  final _nameController = TextEditingController();
  final _birthDateController = TextEditingController();
  late DateTime _selectedDate;
  late AppLocalizations _locale;

  /// Guards against a double `pop`: a second one would pop another route off
  /// the navigator and the onboarding screen would close onto an unrelated
  /// screen.
  bool _closed = false;

  /// A save is in flight: the `anyBabyExistsProvider` listener in `build()`
  /// must not dismiss this sheet before the save has completed and shown its
  /// success feedback — otherwise a successful creation would end in a quiet
  /// closure.
  bool _saving = false;

  /// "Sheet [created]" indicates whether a profile has just been created here.
  void _dismiss(bool created) {
    if (_closed || !mounted) return;
    _closed = true;
    Navigator.of(context).pop(created);
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  String get localeText => _locale.appTitle;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _locale = context.l;

    // A restore can complete while this sheet is open (an import finished,
    // triggered from the menu). The form no longer makes sense — submitting it
    // would add a second profile to a list that is no longer empty — so the
    // sheet dismisses itself, silently: the welcome screen it leads to says
    // more than any error text could.
    ref.listen<AsyncValue<bool>>(anyBabyExistsProvider, (previous, next) {
      if (_saving) return;
      if (next.value ?? false) _dismiss(false);
    });

    return Dialog(
        child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Icon(
                    Icons.child_care,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _locale.onboardingWelcome,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _locale.onboardingSubtitle,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 24),

                  // Name field
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: _locale.babyName,
                      hintText: _locale.onboardingNameHint,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.badge),
                    ),
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),

                  // Birth date field
                  InkWell(
                    onTap: _selectBirthDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: _locale.birthDate,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.calendar_today),
                        suffixIcon: const Icon(Icons.calendar_today, size: 20),
                      ),
                      child: Text(
                        _birthDateController.text.isNotEmpty
                            ? _birthDateController.text
                            : _formatDate(_selectedDate),
                        style: TextStyle(
                          color: _birthDateController.text.isEmpty
                              ? Theme.of(context).colorScheme.onSurfaceVariant
                              : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Actions
                  DialogActionButtons(
                    onCancelPressed: () => _dismiss(false),
                    onConfirmPressed: _selectedDate.isAfter(
                            DateTime.now().add(const Duration(days: 365 * 20)))
                        ? null
                        : _saveProfile,
                    cancelLabel: _locale.cancelButton,
                    confirmLabel: _locale.confirmButton,
                  ),
                ],
              ),
            )));
  }

  Future<void> _selectBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: _locale.birthDate,
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _birthDateController.text = _formatDate(picked);
      });
    }
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    // Set before any write: the refreshes that follow will trigger the
    // listener in `build()`, and it must not take over the dismissal.
    _saving = true;

    try {
      final repository = await ref.read(babyProfileRepositoryProvider.future);

      // Check for duplicate names before inserting.
      final existingProfiles = await repository.getAllProfiles();
      final duplicateName = existingProfiles.any(
        (p) => p.name.toLowerCase() == name.toLowerCase(),
      );
      if (duplicateName && mounted) {
        _saving = false;
        showError(context, _locale.babyNameAlreadyExists(name));
        return;
      }

      // This sheet only exists because no profile was found. If the database
      // now contains one (an import completed while the form was open),
      // inserting would create the *second* baby, unasked — so dismiss
      // silently instead.
      if (existingProfiles.isNotEmpty) {
        _dismiss(false);
        return;
      }

      final newProfile = BabyProfile(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        birthDate: _selectedDate,
        isActive: true,
      );

      await repository.insertProfile(newProfile);
      await ref.read(activeBabyProvider.notifier).refresh();
      // Refresh the anyBabyExists provider so HomeScreen knows a profile now exists.
      await ref.read(anyBabyExistsProvider.notifier).refresh();
      // D6: a new baby starts being scheduled immediately — its presets join
      // the OS plan on this very sync, not on the next tick.
      unawaited(ref.read(reminderSyncNotifierProvider.notifier).syncNow());

      if (mounted) {
        showFeedback(context, _locale.babyAddedWithName(name));
      }
      // Dismiss the onboarding dialog after successful creation.
      _dismiss(true);
    } catch (e) {
      _saving = false;
      if (mounted) {
        showError(context, _locale.onboardingError);
      }
    }
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
