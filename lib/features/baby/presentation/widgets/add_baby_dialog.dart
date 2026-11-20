import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/providers/active_baby_provider.dart';
import '../../../../core/providers/any_baby_exists_provider.dart';
import '../../../../core/theme.dart';
import '../../../../core/utils/calendar_date.dart';
import '../../../../core/widgets/show_feedback.dart';
import '../../../../shared/domain/entities/baby_profile.dart';
import '../../../reminders/presentation/providers/reminder_sync_notifier.dart';
import '../providers/baby_profile_providers.dart';

/// The "add a baby" dialog, shared by Menu → Profil bébés and by the home baby
/// switcher (B9): the switcher is the family's entry point, so it has to be able to
/// add the second child without walking back down into the menu — and a second copy
/// of this form would be a second place to keep the duplicate-name rule true.
///
/// The new profile is created **inactive**: switching stays a separate, deliberate
/// tap (`ActiveBabyNotifier.switchProfile`), which is also what keeps the `''`
/// carry-over trap of the ticket's "Do not" out of creation.
Future<void> showAddBabyDialog(BuildContext context, WidgetRef ref) async {
  final locale = context.l;
  final nameController = TextEditingController();
  final birthDateController = TextEditingController();
  var selectedDate = DateTime.now();

  await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(locale.addBaby),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: locale.babyName,
                  border: const OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: AppTheme.spacingXl),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: dialogContext,
                    initialDate: selectedDate,
                    firstDate:
                        DateTime.now().subtract(const Duration(days: 365 * 20)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() => selectedDate = picked);
                    birthDateController.text = formatCalendarDate(picked);
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: locale.birthDate,
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    birthDateController.text.isNotEmpty
                        ? birthDateController.text
                        : formatCalendarDate(selectedDate),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(locale.cancel),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;

              try {
                final repository =
                    await ref.read(babyProfileRepositoryProvider.future);

                // Check for duplicate names before inserting.
                final existingProfiles = await repository.getAllProfiles();
                final duplicateName = existingProfiles.any(
                  (p) => p.name.toLowerCase() == name.toLowerCase(),
                );
                if (duplicateName && dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(locale.babyNameAlreadyExists(name)),
                      backgroundColor:
                          Theme.of(dialogContext).colorScheme.error,
                    ),
                  );
                  return;
                }

                final newProfile = BabyProfile(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  birthDate: selectedDate,
                  isActive: false,
                );
                await repository.insertProfile(newProfile);
                // Invalidate the list provider so the menu UI rebuilds with the new profile.
                ref.invalidate(babyProfileListProvider);
                await ref.read(activeBabyProvider.notifier).refresh();
                await ref.read(anyBabyExistsProvider.notifier).refresh();
                // D6: a new baby starts being scheduled immediately — its
                // presets join the OS plan on this very sync.
                unawaited(
                    ref.read(reminderSyncNotifierProvider.notifier).syncNow());

                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (dialogContext.mounted) {
                  showFeedback(context, locale.babyAddedWithName(name));
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  showError(context, locale.babyAddError);
                }
              }
            },
            child: Text(locale.addBaby),
          ),
        ],
      ),
    ),
  );
}
