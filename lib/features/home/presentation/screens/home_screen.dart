import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme.dart';
import '../../../../shared/domain/entities/tracking_enums.dart';
import '../../../../shared/domain/entities/tracking_type.dart';
import '../../../history/presentation/screens/history_screen.dart';
import '../../../menu/menu_screen.dart';
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

  void _onTrack(BuildContext context, WidgetRef ref, String type) {
    final eventType = TrackingType.fromString(type);

    if (eventType == TrackingType.sante) {
      _showHealthSubtypeDialog(context, ref);
      return;
    }

    if (eventType == TrackingType.caca) {
      _showWasteDialog(context, ref);
      return;
    }

    ref.read(trackNotifierProvider.notifier).track(type: eventType);
  }

void _onTapDodo(BuildContext context, WidgetRef ref) {
   showModalBottomSheet<void>(
     context: context,
     backgroundColor: AppTheme.background,
     shape: const RoundedRectangleBorder(
       borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
     ),
     builder: (context) {
       return DurationPickerDialog(
         onDurationSelected: (minutes) {
           ref.read(trackNotifierProvider.notifier).track(
              type: TrackingType.dodo,
                 duration: minutes,
               );
           debugPrint('✅ Dodo enregistré avec durée : $minutes min');
         },
       );
     },
   );
 }

 Future<void> _showWasteDialog(BuildContext context, WidgetRef ref) async {
   final result = await showModalBottomSheet<Map<String, dynamic>?>(
     context: context,
     backgroundColor: AppTheme.background,
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
   }
 }

  void _showHealthSubtypeDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const HealthSubtypeDialog(),
            );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          TrackButton(
            label: 'Miam',
            color: AppTheme.miam,
            onTap: () => _onTrack(context, ref, 'Miam'),
          ),
          TrackButton(
            label: 'Santé',
            color: AppTheme.sante,
            onTap: () => _onTrack(context, ref, 'Santé'),
          ),
          TrackButton(
            label: 'Caca',
            color: AppTheme.caca,
            onTap: () => _onTrack(context, ref, 'Caca'),
          ),
          TrackButton(
            label: 'Dodo',
            color: AppTheme.dodo,
            onTap: () => _onTapDodo(context, ref),
          ),
        ],
      ),
    );
  }
}


