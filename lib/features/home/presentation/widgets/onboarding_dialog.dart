import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/providers/active_baby_provider.dart';
import '../../../../features/baby/presentation/providers/baby_profile_providers.dart';
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

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(_locale.cancel),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _selectedDate.isAfter(DateTime.now().add(const Duration(days: 365 * 20)))
                    ? null
                    : _saveProfile,
                child: Text(_locale.onboardingSaveAndContinue),
              ),
            ],
          ),
        ],
      ),
    ));
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

    try {
      final repository = await ref.read(babyProfileRepositoryProvider.future);
      final newProfile = BabyProfile(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        birthDate: _selectedDate,
        isActive: true,
      );

      await repository.insertProfile(newProfile);
      await ref.read(activeBabyProvider.notifier).refresh();

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_locale.onboardingSuccess),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_locale.onboardingError),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
