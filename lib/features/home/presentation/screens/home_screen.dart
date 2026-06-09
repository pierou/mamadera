import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme.dart';
import '../../../../widgets/bottom_nav.dart';
import '../../../../widgets/track_button.dart';
import '../../../history/presentation/screens/history_screen.dart';
import '../../../menu/menu_screen.dart';
import '../providers/nav_provider.dart';
import '../providers/track_notifier.dart';

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
    final eventType = type.toLowerCase();

    if (eventType == 'santé') {
      _showHealthSubtypeDialog(context, ref);
      return;
    }

    ref.read(trackNotifierProvider.notifier).track(type: eventType);
    debugPrint('✅ Suivi enregistré : $eventType');
  }

  void _showHealthSubtypeDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Type de soin',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildHealthSubtypeTile(
                      context: context,
                      ref: ref,
                      icon: Icons.remove_red_eye,
                      label: 'Nettoyage des yeux',
                      note: 'nettoyage_yeux',
                    ),
                    _buildHealthSubtypeTile(
                      context: context,
                      ref: ref,
                      icon: Icons.circle,
                      label: 'Nettoyage du nombril',
                      note: 'nettoyage_nombril',
                    ),
                    _buildHealthSubtypeTile(
                      context: context,
                      ref: ref,
                      icon: Icons.face,
                      label: 'Nettoyage du visage',
                      note: 'nettoyage_visage',
                    ),
                    _buildHealthSubtypeTile(
                      context: context,
                      ref: ref,
                      icon: Icons.arrow_upward,
                      label: 'Nettoyage du nez',
                      note: 'nettoyage_nez',
                    ),
                    _buildHealthSubtypeTile(
                      context: context,
                      ref: ref,
                      icon: Icons.wb_sunny,
                      label: 'Vitamine D',
                      note: 'vitamine_d',
                    ),
                    _buildHealthSubtypeTile(
                      context: context,
                      ref: ref,
                      icon: Icons.healing,
                      label: 'Vitamine K',
                      note: 'vitamine_k',
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHealthSubtypeTile({
    required BuildContext context,
    required WidgetRef ref,
    required IconData icon,
    required String label,
    required String note,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.sante),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: () {
        ref.read(trackNotifierProvider.notifier).track(
              type: 'sante',
              notes: note,
            );
        debugPrint('✅ Suivi santé enregistré : $note');
        Navigator.pop(context);
      },
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
            onTap: () => _onTrack(context, ref, 'Dodo'),
          ),
        ],
      ),
    );
  }
}
