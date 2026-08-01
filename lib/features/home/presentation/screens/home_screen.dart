import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/providers/any_baby_exists_provider.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets/show_feedback.dart';
import '../../../../shared/domain/entities/tracking_enums.dart';
import '../../../../shared/domain/entities/tracking_icons.dart';
import '../../../../shared/domain/entities/tracking_type.dart';
import '../../../../shared/utils/health_label_resolver.dart';
import '../../../reminders/domain/entities/reminders_state.dart';
import '../../../reminders/presentation/providers/reminder_notifier.dart';
import '../../../reminders/presentation/providers/reminder_providers.dart';
import '../providers/track_notifier.dart';
import '../widgets/duration_picker_dialog.dart';
import '../widgets/feeding_tracking_dialog.dart';
import '../widgets/health_subtype_dialog.dart';
import '../widgets/onboarding_dialog.dart';
import '../widgets/track_button.dart';
import '../widgets/waste_dialog.dart';

/// Home screen content — rendered by go_router ShellRoute.
/// AppShell (router.dart) provides the Scaffold + bottom navigation bar.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _onboardingShown = false;

  @override
  Widget build(BuildContext context) {
    // Watch the async provider in build() — ref.listen is only valid here.
    final anyExistsAsync = ref.watch(anyBabyExistsProvider);
    if (anyExistsAsync.hasValue && !_onboardingShown) {
      final hasProfiles = anyExistsAsync.value!;
      if (!hasProfiles) {
        // Trigger once, then mark as shown so we don't repeat on rebuilds.
        _onboardingShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            showModalBottomSheet<Object?>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const OnboardingWrapper(),
            );
          }
        });
      }
    }

    return const _HomeContent();
  }
}

/// Wrapper to access WidgetRef in showModalBottomSheet callback
class OnboardingWrapper extends ConsumerWidget {
  const OnboardingWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: const OnboardingDialog(),
    );
  }
}

class _HomeContent extends ConsumerWidget {
  const _HomeContent();

  Future<void> _onTrack(
      BuildContext context, WidgetRef ref, String type) async {
    final eventType = TrackingType.fromString(type);

    if (eventType == TrackingType.sante) {
      await _showHealthSubtypeDialog(context, ref);
      return;
    }

    if (eventType == TrackingType.caca) {
      await _showWasteDialog(context, ref);
      return;
    }

    // Miam tracking — show feeding subtype + quantity dialog
    final feedingResult = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTheme.shapeBottomSheetRadius)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return const FeedingTrackingDialog();
          },
        );
      },
    );

    if (feedingResult != null && context.mounted) {
      final subtype = feedingResult['subtype'] as FeedingSubtype;
      final quantity = feedingResult['quantity'] as double? ??
          0.0; // fallback to 0 if dialog returns null
      await ref.read(trackNotifierProvider.notifier).track(
            type: TrackingType.miam,
            feedingSubtype: subtype,
            quantity: quantity,
          );
      if (context.mounted) {
        unawaited(ref.read(reminderNotifierProvider.notifier).refresh());
        _showFeedingFeedback(context, subtype, quantity);
      }
    }
  }

  Future<void> _onTapDodo(BuildContext context, WidgetRef ref) async {
    final minutes = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTheme.shapeBottomSheetRadius)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return DurationPickerDialog(
              onDurationSelected: (minutes) {
                Navigator.of(context).pop(minutes);
              },
            );
          },
        );
      },
    );

    if (minutes != null && context.mounted) {
      await ref.read(trackNotifierProvider.notifier).track(
            type: TrackingType.dodo,
            duration: minutes,
            quantity: minutes,
          );
      if (context.mounted) {
        unawaited(ref.read(reminderNotifierProvider.notifier).refresh());
        showFeedback(context, context.l.feedbackSleep(minutes.round()));
      }
    }
  }

  Future<void> _showWasteDialog(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTheme.shapeBottomSheetRadius)),
      ),
      builder: (context) => const WasteDialog(),
    );

    if (result != null && context.mounted) {
      final wasteType = result['wasteType'] as WasteType?;
      await ref.read(trackNotifierProvider.notifier).track(
            type: TrackingType.caca,
            wasteType: wasteType,
            pipiColor: result['pipiColor'] as PipiColor?,
            cacaColor: result['cacaColor'] as CacaColor?,
          );
      if (context.mounted) {
        unawaited(ref.read(reminderNotifierProvider.notifier).refresh());
        _showDiaperFeedback(context, wasteType);
      }
    }
  }

  Future<void> _showHealthSubtypeDialog(
      BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTheme.shapeBottomSheetRadius)),
      ),
      builder: (context) => const HealthSubtypeDialog(),
    );

    if (result != null && context.mounted) {
      final subtype = result['subtype'] as HealthSubtype;
      await ref.read(trackNotifierProvider.notifier).track(
            type: TrackingType.sante,
            healthSubtype: subtype,
          );
      if (context.mounted) {
        unawaited(ref.read(reminderNotifierProvider.notifier).refresh());
        showFeedback(context, resolveHealthLabel(context, subtype));
      }
    }
  }

  /// Formats and shows a feeding tracking confirmation with quantity details.
  void _showFeedingFeedback(
      BuildContext context, FeedingSubtype subtype, double? quantity) {
    final subtypeLabel = subtype == FeedingSubtype.natural
        ? context.l.feedingSubtypeNatural
        : context.l.feedingSubtypeArtificial;
    if (quantity != null && quantity > 0) {
      final qtyStr = '${quantity.round()}ml';
      showFeedback(
        context,
        context.l.feedbackFeedingWithQuantity(subtypeLabel, qtyStr),
      );
      return;
    }
    showFeedback(context, subtypeLabel);
  }

  /// Formats and shows a diaper tracking confirmation with waste type.
  void _showDiaperFeedback(BuildContext context, WasteType? wasteType) {
    switch (wasteType) {
      case WasteType.pipi:
        showFeedback(context, context.l.feedbackPipi(''));
      case WasteType.caca:
        showFeedback(context, context.l.feedbackCaca(''));
      case WasteType.lesDeux:
        showFeedback(context, context.l.feedbackBoth);
      case null:
        showFeedback(context, context.l.homeButtonCaca);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch pending reminder counts per TrackingType.
    final statusesAsync = ref.watch(reminderNotifierProvider);
    final statusMap =
        statusesAsync.value ?? const <TrackingType, List<ReminderStatus>>{};

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: AppTheme.spacingXl,
          crossAxisSpacing: AppTheme.spacingXl,
          children: [
            TrackButton(
              key: const ValueKey('track-miam'),
              label: context.l.homeButtonMiam,
              color: AppTheme.miam,
              icon: TrackingType.miam.icon,
              reminders: statusMap[TrackingType.miam],
              onTap: () => _onTrack(context, ref, TrackingType.miam.name),
            ),
            TrackButton(
              key: const ValueKey('track-sante'),
              label: context.l.homeButtonSante,
              color: AppTheme.sante,
              icon: TrackingType.sante.icon,
              reminders: statusMap[TrackingType.sante],
              onTap: () => _onTrack(context, ref, TrackingType.sante.name),
            ),
            TrackButton(
              key: const ValueKey('track-caca'),
              label: context.l.homeButtonCaca,
              color: AppTheme.caca,
              icon: TrackingType.caca.icon,
              reminders: statusMap[TrackingType.caca],
              onTap: () => _onTrack(context, ref, TrackingType.caca.name),
            ),
            TrackButton(
              key: const ValueKey('track-dodo'),
              label: context.l.homeButtonDodo,
              color: AppTheme.dodo,
              icon: TrackingType.dodo.icon,
              reminders: statusMap[TrackingType.dodo],
              onTap: () => _onTapDodo(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}
