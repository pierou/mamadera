import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/providers/active_baby_provider.dart';
import '../../../../core/providers/any_baby_exists_provider.dart';
import '../../../../core/widgets/dialog_buttons.dart';
import '../../../../core/widgets/show_feedback.dart';
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

  /// Un `pop` a déjà été émis : un second en enlèverait une autre route du
  /// navigator, et la feuille d'onboarding se fermerait sur un écran sans rapport.
  bool _closed = false;

  /// Une sauvegarde est en cours : l'écoute de `anyBabyExistsProvider` ne doit
  /// pas rendre la feuille avant qu'elle l'ait fait elle-même, avec le message de
  /// succès — sinon une création réussie se termine en fermeture silencieuse.
  bool _saving = false;

  /// Rend la feuille. [created] dit si un profil vient d'être créé ici.
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

    // Une restauration peut aboutir pendant que cette feuille est ouverte (import
    // déclenché ailleurs, autre appareil). Son formulaire n'a plus de sens : il
    // ajouterait un deuxième profil à une liste qui n'est plus vide. Elle se rend
    // donc d'elle-même, sans message — la liste d'accueil qui se rafraîchit
    // juste derrière explique l'affaire mieux qu'un texte.
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

    // Marquée avant la moindre écriture : les rafraîchissements qui suivent
    // l'insertion déclenchent l'écoute posée dans `build()`, et elle ne doit pas
    // prendre la main sur la fermeture de la sauvegarde.
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

      // Cette feuille n'existe que parce qu'aucun profil n'existait. Si la base en
      // contient maintenant, un import a abouti pendant la saisie : insérer ne
      // créerait pas « le premier bébé » mais le deuxième, sans que personne
      // n'ait rien demandé — d'où la fermeture plutôt que l'écriture.
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
