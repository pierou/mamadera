import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/providers/active_baby_provider.dart';
import '../../../../core/providers/any_baby_exists_provider.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets/show_feedback.dart';
import '../../../../features/baby/presentation/providers/baby_profile_providers.dart';
import '../../../../features/reminders/presentation/providers/reminder_sync_notifier.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/domain/entities/baby_profile.dart';

/// Baby profile management section displayed in the Menu screen.
///
/// Shows the active baby profile with avatar, name, and birthdate.
/// Allows adding new babies, switching active profile, and deleting profiles.
class BabyProfileSection extends ConsumerWidget {
  const BabyProfileSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = context.l;
    final profilesAsync = ref.watch(babyProfileListProvider);
    final activeBabyAsync = ref.watch(activeBabyProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          locale.babyProfilesSectionTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        if (profilesAsync.isLoading || profilesAsync.value == null)
          const ListTile(
              leading: CircularProgressIndicator(), title: Text('Loading...'))
        else if (profilesAsync.hasError)
          ListTile(
            leading:
                Icon(Icons.error, color: Theme.of(context).colorScheme.error),
            title: Text(locale.babyProfilesError),
          )
        else if (profilesAsync.value == null || profilesAsync.value!.isEmpty)
          _buildEmptyState(context, ref, locale)
        else
          ..._buildProfileTiles(
              context, ref, profilesAsync.value!, activeBabyAsync, locale),
      ],
    );
  }

  Widget _buildEmptyState(
      BuildContext context, WidgetRef ref, AppLocalizations locale) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.cake_outlined),
          title: Text(locale.babyProfilesEmpty),
          trailing: ElevatedButton.icon(
            onPressed: () => _showAddBabyDialog(context, ref, locale),
            icon: const Icon(Icons.add, size: 18),
            label: Text(locale.addBaby),
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
      ],
    );
  }

  List<Widget> _buildProfileTiles(
    BuildContext context,
    WidgetRef ref,
    List<BabyProfile> profiles,
    AsyncValue<BabyProfile?> activeBabyAsync,
    AppLocalizations locale,
  ) {
    return [
      ...profiles.map((profile) {
        final isActive = activeBabyAsync.when(
          data: (active) => active?.id == profile.id,
          loading: () => profile.isActive,
          error: (_, __) => profile.isActive,
        );

        final cs = Theme.of(context).colorScheme;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor:
                isActive ? cs.primaryContainer : cs.surfaceContainerHighest,
            child: Icon(
              isActive ? Icons.child_care : Icons.child_care_outlined,
              color: cs.onPrimaryContainer,
            ),
          ),
          title: Text(
            profile.name,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: Text(
            _formatBirthdate(profile.birthDate, locale),
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isActive)
                Icon(Icons.check_circle, color: cs.primary, size: 20),
              PopupMenuButton<String>(
                onSelected: (value) =>
                    _handleMenuAction(context, ref, value, profile, locale),
                itemBuilder: (context) => [
                  if (!isActive)
                    PopupMenuItem(
                      value: 'activate',
                      child: Row(
                        children: [
                          const Icon(Icons.star_border, size: 20),
                          const SizedBox(width: AppTheme.spacingMd),
                          Text(locale.activate),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit, size: 20),
                        const SizedBox(width: AppTheme.spacingMd),
                        Text(locale.edit),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete,
                            size: 20,
                            color: Theme.of(context).colorScheme.error),
                        const SizedBox(width: AppTheme.spacingMd),
                        Text(locale.delete,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          onTap: () {
            if (!isActive) {
              ref.read(activeBabyProvider.notifier).switchProfile(profile.id);
            }
          },
        );
      }),
      const SizedBox(height: AppTheme.spacingMd),
      ListTile(
        leading: const Icon(Icons.add_circle_outline),
        title: Text(locale.addBaby),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _showAddBabyDialog(context, ref, locale),
      ),
    ];
  }

  void _handleMenuAction(
    BuildContext context,
    WidgetRef ref,
    String action,
    BabyProfile profile,
    AppLocalizations locale,
  ) {
    switch (action) {
      case 'activate':
        ref.read(activeBabyProvider.notifier).switchProfile(profile.id);
      case 'edit':
        _showEditBabyDialog(context, ref, profile, locale);
      case 'delete':
        _showDeleteConfirmation(context, ref, profile, locale);
    }
  }

  Future<void> _showAddBabyDialog(
      BuildContext context, WidgetRef ref, AppLocalizations locale) async {
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
                      firstDate: DateTime.now()
                          .subtract(const Duration(days: 365 * 20)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => selectedDate = picked);
                      birthDateController.text = _formatShortDate(picked);
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
                          : _formatShortDate(selectedDate),
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
                  unawaited(ref
                      .read(reminderSyncNotifierProvider.notifier)
                      .syncNow());

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

  Future<void> _showEditBabyDialog(BuildContext context, WidgetRef ref,
      BabyProfile profile, AppLocalizations locale) async {
    final nameController = TextEditingController(text: profile.name);
    var selectedDate = profile.birthDate;

    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(locale.editProfile),
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
                      firstDate: DateTime.now()
                          .subtract(const Duration(days: 365 * 20)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => selectedDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: locale.birthDate,
                      border: const OutlineInputBorder(),
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                    child: Text(_formatShortDate(selectedDate)),
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

                  // Check for duplicate names (excluding the profile being edited).
                  final existingProfiles = await repository.getAllProfiles();
                  final duplicateName = existingProfiles
                      .where((p) => p.id != profile.id)
                      .any((p) => p.name.toLowerCase() == name.toLowerCase());
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

                  await repository.updateProfile(
                    profile.id,
                    name: name,
                    birthDate: selectedDate,
                  );
                  // Invalidate the list provider so the menu UI rebuilds with updated data.
                  ref.invalidate(babyProfileListProvider);
                  await ref.read(activeBabyProvider.notifier).refresh();

                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                  if (dialogContext.mounted) {
                    showFeedback(context, locale.babyUpdatedWithName(name));
                  }
                } catch (e) {
                  if (dialogContext.mounted) {
                    showError(context, locale.babyUpdateError);
                  }
                }
              },
              child: Text(locale.saveButton),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context, WidgetRef ref,
      BabyProfile profile, AppLocalizations locale) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(locale.deleteBabyConfirm),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(locale.deleteBabyWarning(profile.name)),
            const SizedBox(height: 16),
            Text(
              locale.deleteBabyDataWarning,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(locale.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            child: Text(locale.delete),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        final repository = await ref.read(babyProfileRepositoryProvider.future);
        await repository.deleteProfile(profile.id);

        // Invalidate the list provider so the menu UI rebuilds with updated data.
        ref.invalidate(babyProfileListProvider);

        // D6: the deleted baby's entries are stale — reconcile now so the OS
        // plan (and the profileless fallback, if this was the last baby)
        // tracks the profile list without waiting for the next tick.
        unawaited(ref.read(reminderSyncNotifierProvider.notifier).syncNow());

        // B31: if the deleted baby was the active one, deleteProfile has
        // already re-activated a survivor inside its own transaction — the
        // provider only re-reads. No second write, no kill-in-the-gap.
        await ref.read(activeBabyProvider.notifier).refresh();

        if (context.mounted) {
          showFeedback(context, locale.babyDeletedWithName(profile.name));
        }
      } catch (e) {
        if (context.mounted) {
          showError(context, locale.babyDeleteError);
        }
      }
    }
  }

  String _formatBirthdate(DateTime birthDate, AppLocalizations locale) {
    // B18: anniversary-based age. A month counts only once the clamped
    // anniversary of that many months has been reached: a baby born on
    // 31 January turns one month old on 28/29 February and reads as 1 month
    // old on 1 March, not 2. Future birthdates (invalid, not guarded
    // upstream) clamp to 0 instead of going negative.
    final now = DateTime.now();
    var months =
        (now.year - birthDate.year) * 12 + (now.month - birthDate.month);
    if (months < 0) months = 0;
    if (now.isBefore(_addMonths(birthDate, months))) months--;
    if (months < 0) months = 0;

    if (months < 1) {
      final days = now.difference(birthDate).inDays.clamp(0, 1 << 30);
      return '$days ${locale.daysOld}';
    } else if (months < 12) {
      return '$months ${locale.monthsOld}';
    } else {
      return '${months ~/ 12} ${locale.yearsOld}';
    }
  }

  /// [date] shifted by [months], the day clamped to the last day of the
  /// target month (31 January + 1 month = 28/29 February).
  static DateTime _addMonths(DateTime date, int months) {
    final total = date.year * 12 + (date.month - 1) + months;
    final year = total ~/ 12;
    final month = total % 12 + 1;
    final firstOfNext =
        month == 12 ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
    final lastDay = firstOfNext.subtract(const Duration(days: 1)).day;
    return DateTime(year, month, date.day.clamp(1, lastDay));
  }

  String _formatShortDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
