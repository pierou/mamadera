import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/l10n/unit_localization.dart';
import '../../../../core/providers/active_baby_provider.dart';
import '../../../../core/providers/any_baby_exists_provider.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets/show_feedback.dart';
import '../../../../shared/domain/entities/quantity_unit.dart';
import '../../../../shared/domain/entities/tracking_enums.dart';
import '../../../../shared/domain/entities/tracking_type.dart';
import '../../../../shared/utils/health_label_resolver.dart';
import '../../../../shared/widgets/tracking_icons.dart';
import '../../../growth/presentation/widgets/measurement_button.dart';
import '../../../reminders/domain/entities/reminders_state.dart';
import '../../../reminders/presentation/providers/reminder_notifier.dart';
import '../../../reminders/presentation/providers/reminder_providers.dart';
import '../../../reminders/presentation/widgets/home_reminders_section.dart';
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
  /// The sheet was opened – only once for each instance of the screen.
  bool _onboardingShown = false;

  /// A frame is waiting to open the sheet. Distinguish "waiting" from...
  /// "Open" is required: if the re-verification below results in cancellation.
  /// The display, with a single latch, would result in an initial launch without a data sheet.
  /// Onboarding – a failure that's worse than one that can be corrected.
  bool _onboardingScheduled = false;

  /// Open the onboarding sheet to the next frame, and double-check this.
  /// precise moment.
  ///
  /// The decision was based on the supplier's performance in the previous project phase, and...
  /// The callback function no longer checked anything; it simply indicated whether a restore operation had been successful or not, regardless of what happened in between.
  /// the two, the sheet stayed open above an already-populated database and
  /// It added a profile to the form. `null` (currently being invalidated) means...
  /// "We don't know": we don't open an investigation into an absence that we haven't confirmed.
  /// And we remain in a waiting state until a value arrives.
  void _scheduleOnboardingSheet() {
    _onboardingScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onboardingScheduled = false;
      if (!mounted) return;
      if (ref.read(anyBabyExistsProvider).value ?? true) return;
      _onboardingShown = true;
      showModalBottomSheet<Object?>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const OnboardingWrapper(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch + listen to anyBabyExistsProvider in build().
    // Riverpod requires listeners to be created during widget build, not initState.
    final anyExistsAsync = ref.watch(anyBabyExistsProvider);

    // Initialize onboarding state from current provider value (handles tab navigation).
    if (_onboardingShown == false &&
        anyExistsAsync.hasValue &&
        anyExistsAsync.value! == true) {
      _onboardingShown = true;
    }

    // Listen for provider changes to handle cases where a baby is created
    // from another screen (e.g., Settings) while HomeScreen is mounted.
    ref.listen<AsyncValue<bool>>(anyBabyExistsProvider, (previous, next) {
      if (!next.hasValue || !next.value!) return;
      if (mounted) setState(() => _onboardingShown = true);
    });
    if (anyExistsAsync.hasValue && !_onboardingShown && !_onboardingScheduled) {
      final hasProfiles = anyExistsAsync.value!;
      if (!hasProfiles) {
        // Trigger once, then mark as shown so we don't repeat on rebuilds.
        _scheduleOnboardingSheet();
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
      // The sense of belonging comes from communication: it was the parent who chose this individual within the group.
      // The fallback mechanism only handles incomplete results and specifies the unit of measurement.
      // subtype, never a guessing game.
      final unit = feedingResult['unit'] as QuantityUnit? ??
          defaultUnitFor(
            typeValue: TrackingType.miam.name,
            subtypeValue: subtype.dbValue,
          );
      final quantity = feedingResult['quantity'] as double? ??
          0.0; // fallback to 0 if dialog returns null
      await ref.read(trackNotifierProvider.notifier).track(
            type: TrackingType.miam,
            feedingSubtype: subtype,
            unit: unit,
            quantity: quantity,
            timestamp: feedingResult['timestamp'] as DateTime?,
          );
      if (context.mounted) {
        unawaited(ref.read(reminderNotifierProvider.notifier).refresh());
        _showFeedingFeedback(context, subtype, quantity, unit);
      }
    }
  }

  Future<void> _onTapDodo(BuildContext context, WidgetRef ref) async {
    final selection = await showModalBottomSheet<SleepSelection>(
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
              onSleepSelected: (result) {
                Navigator.of(context).pop(result);
              },
            );
          },
        );
      },
    );

    if (selection != null && context.mounted) {
      await ref.read(trackNotifierProvider.notifier).track(
            type: TrackingType.dodo,
            duration: selection.minutes,
            unit: QuantityUnit.min,
            quantity: selection.minutes,
            timestamp: selection.start,
          );
      if (context.mounted) {
        unawaited(ref.read(reminderNotifierProvider.notifier).refresh());
        showFeedback(
            context, context.l.feedbackSleep(selection.minutes.round()));
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
            stoolTexture: result['texture'] as StoolTexture?,
            timestamp: result['timestamp'] as DateTime?,
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
            timestamp: result['timestamp'] as DateTime?,
          );
      if (context.mounted) {
        unawaited(ref.read(reminderNotifierProvider.notifier).refresh());
        showFeedback(context, resolveHealthLabel(context, subtype));
      }
    }
  }

  /// Formats and shows a feeding tracking confirmation with quantity details.
  void _showFeedingFeedback(BuildContext context, FeedingSubtype subtype,
      double? quantity, QuantityUnit unit) {
    // The label indicates the subtype, while the unit specifies the line: a "40 ml" marking within the...
    // Providing feedback based on a 20-minute feeding time would be misleading and inaccurate from a health perspective.
    final subtypeLabel = switch (subtype) {
      FeedingSubtype.natural => context.l.feedingSubtypeNatural,
      FeedingSubtype.artificial => context.l.feedingSubtypeArtificial,
      FeedingSubtype.solid => context.l.feedingSolid,
    };
    if (quantity != null && quantity > 0) {
      final qtyStr = '${quantity.round()}${quantityUnitLabel(context, unit)}';
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

    // The baby's name displayed above the grid: context, not a title.
    // `watch` (not `read`): the header should reflect changes in the baby's condition.
    // Never display a first name that was captured during the initial setup.
    final babyName = ref.watch(activeBabyProvider).value?.name;

    // The name holds the application bar (title) and remains visible at all times.
    // system status bar on Android, where a name is displayed at the top.
    // The grid was hidden. Without an active baby monitor, the app bar disappears.
    // The initial setup process manages the creation of the profile.
    final name =
        (babyName != null && babyName.trim().isNotEmpty) ? babyName : null;
    return Scaffold(
      appBar: name == null
          ? null
          : AppBar(
              title: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              centerTitle: true,
            ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        // Without any app-specific features (no active baby mode), it's the content itself that...
        // respects the status bar: the first block should not overlap with it.
        // rendre.
        child: SafeArea(
          // Scrollable so the 2x2 grid stays reachable on small viewports
          // (small phones, resized desktop windows).
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingXl),
            child: Column(
              children: [
                GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppTheme.spacingXl,
                  crossAxisSpacing: AppTheme.spacingXl,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    TrackButton(
                      key: const ValueKey('track-miam'),
                      label: context.l.homeButtonMiam,
                      color: AppTheme.miam,
                      icon: TrackingType.miam.icon,
                      reminders: statusMap[TrackingType.miam],
                      onTap: () =>
                          _onTrack(context, ref, TrackingType.miam.name),
                    ),
                    TrackButton(
                      key: const ValueKey('track-sante'),
                      label: context.l.homeButtonSante,
                      color: AppTheme.sante,
                      icon: TrackingType.sante.icon,
                      reminders: statusMap[TrackingType.sante],
                      onTap: () =>
                          _onTrack(context, ref, TrackingType.sante.name),
                    ),
                    TrackButton(
                      key: const ValueKey('track-caca'),
                      label: context.l.homeButtonCaca,
                      color: AppTheme.caca,
                      icon: TrackingType.caca.icon,
                      reminders: statusMap[TrackingType.caca],
                      onTap: () =>
                          _onTrack(context, ref, TrackingType.caca.name),
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
                const SizedBox(height: AppTheme.spacingXl),
                // Boutons de croissance (item 1 de v1.2) : widget autonome, la
                // The 2x2 grid shown above remains unchanged.
                const MeasurementButtonRow(),
                // List of overdue recalls (D1): replaces the reading of "+N".
                // small adhesive pads, without touching the grid or the buttons.
                const HomeRemindersSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
