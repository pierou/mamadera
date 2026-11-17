import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/l10n/date_localization.dart';
import '../../../../core/providers/active_baby_provider.dart';
import '../../../../core/theme.dart';
import '../../../../shared/domain/entities/baby_profile.dart';
import 'add_baby_dialog.dart';

/// Open the home baby switcher (B9).
///
/// Called from the Home app bar's title, which used to be inert: the name was
/// displayed and did nothing, so switching a child meant walking to Menu → Bébés.
/// The reactive chain already exists (`activeBabyProvider` is watched by the
/// reminders, the history and this header), so the switcher is one sheet and one
/// `onTap`, and no manual invalidation.
Future<void> showBabyPickerSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    // The add-baby dialog is opened on **this** context, the screen's: the sheet's
    // own context dies when it pops, and a dialog pushed on a dead route is a
    // silent no-op — the worst kind of broken button.
    builder: (sheetContext) => BabyPickerSheet(
      onAdd: () => showAddBabyDialog(context, ref),
    ),
  );
}

/// The list of children, the active one checked, and the row that adds one.
///
/// A **switcher**, not a manager: editing a name, correcting a birth date and
/// deleting a profile stay in Menu → Bébés (B9's "Do not"). Two entry points for a
/// deletion is how a profile disappears by accident.
class BabyPickerSheet extends ConsumerWidget {
  const BabyPickerSheet({required this.onAdd, super.key});

  /// Opens the shared add-baby dialog (the Menu's own row uses the same one, so the
  /// duplicate-name rule lives in exactly one place).
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final profilesAsync = ref.watch(babyProfileListProvider);
    final active = ref.watch(activeBabyProvider).value;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacingXl,
                0,
                AppTheme.spacingXl,
                AppTheme.spacingSm,
              ),
              child: Text(
                l.babyProfilesSectionTitle,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            if (profilesAsync.hasValue)
              for (final profile in profilesAsync.value!)
                ListTile(
                  leading: _Avatar(
                      profile: profile, isActive: _isActive(profile, active)),
                  title: Text(
                    profile.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(formatDateShort(context, profile.birthDate)),
                  trailing: _isActive(profile, active)
                      ? Icon(Icons.check,
                          color: Theme.of(context).colorScheme.primary)
                      : null,
                  // The sheet closes on the choice: the switch ends this
                  // interaction, and a sheet left open over a rebuilt Home reads as
                  // "nothing happened".
                  onTap: () {
                    Navigator.of(context).pop();
                    if (!_isActive(profile, active)) {
                      ref
                          .read(activeBabyProvider.notifier)
                          .switchProfile(profile.id);
                    }
                  },
                ),
            const Divider(height: AppTheme.spacingLg),
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: Text(l.addBaby),
              onTap: () {
                Navigator.of(context).pop();
                onAdd();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// While the list is still in flight the stored flag is the best available answer
  /// — the same fallback the Menu's list uses, so the two surfaces cannot disagree
  /// about who is active for one frame.
  bool _isActive(BabyProfile profile, BabyProfile? active) =>
      active == null ? profile.isActive : active.id == profile.id;
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.profile, required this.isActive});

  final BabyProfile profile;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return CircleAvatar(
      backgroundColor:
          isActive ? cs.primaryContainer : cs.surfaceContainerHighest,
      child: Text(
        profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
      ),
    );
  }
}
