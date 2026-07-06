import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/theme.dart';
import '../../../../shared/domain/entities/tracking_enums.dart';
import '../../../../shared/domain/entities/tracking_type.dart';
import '../../../history/presentation/screens/history_screen.dart';
import '../../../menu/presentation/screens/menu_screen.dart';
import '../../../reminders/domain/entities/reminders_state.dart';
import '../../../reminders/presentation/providers/reminder_notifier.dart';
import '../../../reminders/presentation/providers/reminder_providers.dart';
import '../providers/nav_provider.dart';
import '../providers/track_notifier.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/duration_picker_dialog.dart';
import '../widgets/health_subtype_dialog.dart';
import '../widgets/track_button.dart';
import '../widgets/waste_dialog.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navIndex = ref.watch(navIndexProvider);

    return Scaffold(
      body: _screens[navIndex],
      bottomNavigationBar: AppBottomNav(
        currentIndex: navIndex,
        onTap: (index) => ref.read(navIndexProvider.notifier).setIndex(index),
      ),
    );
  }

  static const List<Widget> _screens = [
    _HomeContent(),
    HistoryScreen(),
    MenuScreen(),
  ];
}

class _HomeContent extends ConsumerWidget {
  const _HomeContent();

  Future<void> _onTrack(BuildContext context, WidgetRef ref, String type) async {
    final eventType = TrackingType.fromString(type);

    if (eventType == TrackingType.sante) {
      await _showHealthSubtypeDialog(context, ref);
      return;
    }

    if (eventType == TrackingType.caca) {
      await _showWasteDialog(context, ref);
      return;
    }

    // Miam tracking — default to sein (breastfeeding), no subtype dialog needed
    await ref.read(trackNotifierProvider.notifier).track(
      type: TrackingType.miam,
      feedingSubtype: FeedingSubtype.sein,
    );
    if (context.mounted) {
      unawaited(ref.read(reminderNotifierProvider.notifier).refresh());
      _showFeedback(context, context.l.homeButtonMiam, type: eventType);
    }
  }

Future<void> _onTapDodo(BuildContext context, WidgetRef ref) async {
   final minutes = await showModalBottomSheet<int>(
     context: context,
     backgroundColor: Theme.of(context).scaffoldBackgroundColor,
     shape: const RoundedRectangleBorder(
       borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
       duration: minutes.toDouble(),
     );
     if (context.mounted) {
       unawaited(ref.read(reminderNotifierProvider.notifier).refresh());
       _showFeedback(context, context.l.homeButtonDodo, type: TrackingType.dodo);
     }
   }
 }

 Future<void> _showWasteDialog(BuildContext context, WidgetRef ref) async {
   final result = await showModalBottomSheet<Map<String, dynamic>?>(
     context: context,
     backgroundColor: Theme.of(context).scaffoldBackgroundColor,
     shape: const RoundedRectangleBorder(
       borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
       _showFeedback(context, context.l.homeButtonCaca, type: TrackingType.caca);
     }
   }
 }

 Future<void> _showHealthSubtypeDialog(BuildContext context, WidgetRef ref) async {
   final result = await showModalBottomSheet<Map<String, dynamic>?>(
     context: context,
     backgroundColor: Theme.of(context).scaffoldBackgroundColor,
     shape: const RoundedRectangleBorder(
       borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
       _showFeedback(context, context.l.homeButtonSante, type: TrackingType.sante, subtype: subtype);
     }
   }
 }

  void _showFeedback(BuildContext context, String label, {required TrackingType type, HealthSubtype? subtype}) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(label),
        duration: const Duration(milliseconds: 800),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch pending reminder counts per TrackingType.
      final statusesAsync = ref.watch(reminderNotifierProvider);
      final statusMap = statusesAsync.value ?? const <TrackingType, List<ReminderStatus>>{};

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
            TrackButton(
              label: context.l.homeButtonMiam,
              color: AppTheme.miam,
              reminders: statusMap[TrackingType.miam],
              onTap: () => _onTrack(context, ref, TrackingType.miam.name),
            ),
            TrackButton(
              label: context.l.homeButtonSante,
              color: AppTheme.sante,
              reminders: statusMap[TrackingType.sante],
              onTap: () => _onTrack(context, ref, TrackingType.sante.name),
            ),
            TrackButton(
              label: context.l.homeButtonCaca,
              color: AppTheme.caca,
              reminders: statusMap[TrackingType.caca],
              onTap: () => _onTrack(context, ref, TrackingType.caca.name),
            ),
            TrackButton(
              label: context.l.homeButtonDodo,
              color: AppTheme.dodo,
              reminders: statusMap[TrackingType.dodo],
              onTap: () => _onTapDodo(context, ref),
            ),
        ],
      ),
    );
  }
}


