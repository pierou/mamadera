import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/providers/active_baby_provider.dart';
import '../../../../core/theme.dart';
import '../../../../features/baby/presentation/providers/baby_profile_providers.dart';
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
          const ListTile(leading: CircularProgressIndicator(), title: Text('Loading...'))
        else if (profilesAsync.hasError)
          ListTile(
            leading: Icon(Icons.error, color: Theme.of(context).colorScheme.error),
            title: Text(locale.babyProfilesError),
          )
        else if (profilesAsync.value == null || profilesAsync.value!.isEmpty)
          _buildEmptyState(context, ref, locale)
        else ..._buildProfileTiles(context, ref, profilesAsync.value!, activeBabyAsync, locale),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, AppLocalizations locale) {
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
            backgroundColor: isActive ? cs.primaryContainer : cs.surfaceContainerHighest,
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
            _formatBirthdate(profile.birthDate),
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isActive) Icon(Icons.check_circle, color: cs.primary, size: 20),
              PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(context, ref, value, profile, locale),
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
                        Icon(Icons.delete, size: 20, color: Theme.of(context).colorScheme.error),
                        const SizedBox(width: AppTheme.spacingMd),
                        Text(locale.delete, style: TextStyle(color: Theme.of(context).colorScheme.error)),
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

  Future<void> _showAddBabyDialog(BuildContext context, WidgetRef ref, AppLocalizations locale) async {
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
                      firstDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
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
                  final repository = await ref.read(babyProfileRepositoryProvider.future);
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

                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text(locale.babyAddedSuccess),
                        backgroundColor: Theme.of(dialogContext).colorScheme.primary,
                      ),
                    );
                  }
                } catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text(locale.babyAddError),
                        backgroundColor: Theme.of(dialogContext).colorScheme.error,
                      ),
                    );
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

  Future<void> _showEditBabyDialog(BuildContext context, WidgetRef ref, BabyProfile profile, AppLocalizations locale) async {
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
                      firstDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
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
                  final repository = await ref.read(babyProfileRepositoryProvider.future);
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
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text(locale.babyUpdatedSuccess),
                        backgroundColor: Theme.of(dialogContext).colorScheme.primary,
                      ),
                    );
                  }
                } catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text(locale.babyUpdateError),
                        backgroundColor: Theme.of(dialogContext).colorScheme.error,
                      ),
                    );
                  }
                }
              },
              child: Text(locale.update),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context, WidgetRef ref, BabyProfile profile, AppLocalizations locale) async {
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
              style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.bold),
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
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: Text(locale.delete),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        final repository = await ref.read(babyProfileRepositoryProvider.future);
        final isActive = profile.id == ref.read(activeBabyProvider).value?.id;
        await repository.deleteProfile(profile.id);

        // Invalidate the list provider so the menu UI rebuilds with updated data.
        ref.invalidate(babyProfileListProvider);

        if (isActive) {
          // If we deleted the active baby, activate the first other profile if exists.
          final allProfiles = await repository.getAllProfiles();
          if (allProfiles.isNotEmpty) {
            await ref.read(activeBabyProvider.notifier).switchProfile(allProfiles.first.id);
          } else {
            await ref.read(activeBabyProvider.notifier).refresh();
          }
        } else {
          await ref.read(activeBabyProvider.notifier).refresh();
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(locale.babyDeletedSuccess),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(locale.babyDeleteError),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  String _formatBirthdate(DateTime birthDate) {
    final now = DateTime.now();
    final age = now.year - birthDate.year;
    final months = now.month - birthDate.month;

    if (age == 0 && months == 0) {
      final days = now.difference(birthDate).inDays;
      return '$days ${days == 1 ? 'day' : 'days'} old';
    } else if (age == 0) {
      return '$months ${months == 1 ? 'month' : 'months'} old';
    } else {
      return '$age ${age == 1 ? 'year' : 'years'} old';
    }
  }

  String _formatShortDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
