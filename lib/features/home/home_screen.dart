import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../widgets/track_button.dart';
import '../../widgets/bottom_nav.dart';
import '../../data/local/database.dart';
import '../../data/local/app_db.dart';
import '../history/history_screen.dart';
import '../menu/menu_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  final List<Widget> _screens = [
    const _HomeContent(),
    const HistoryScreen(),
    const MenuScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_navIndex],
      bottomNavigationBar: AppBottomNav(
        currentIndex: _navIndex,
        onTap: (index) {
          setState(() => _navIndex = index);
        },
      ),
    );
  }
}

class _HomeContent extends StatefulWidget {
  const _HomeContent();

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  void _onTrack(String type) {
    final eventType = type.toLowerCase();

    if (eventType == 'santé') {
      _showHealthSubtypeDialog();
      return;
    }

    final companion = TrackingEventsCompanion(
      type: Value(eventType),
      timestamp: Value(DateTime.now()),
    );
    DatabaseService().database.insertEvent(companion);
    debugPrint('✅ Suivi enregistré : $companion');
  }

  void _showHealthSubtypeDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
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
                icon: Icons.remove_red_eye,
                label: 'Nettoyage des yeux',
                note: 'nettoyage_yeux',
              ),
              _buildHealthSubtypeTile(
                icon: Icons.circle,
                label: 'Nettoyage du nombril',
                note: 'nettoyage_nombril',
              ),
              _buildHealthSubtypeTile(
                icon: Icons.face,
                label: 'Nettoyage du visage',
                note: 'nettoyage_visage',
              ),
              _buildHealthSubtypeTile(
                icon: Icons.arrow_upward,
                label: 'Nettoyage du nez',
                note: 'nettoyage_nez',
              ),
              _buildHealthSubtypeTile(
                icon: Icons.wb_sunny,
                label: 'Vitamine D',
                note: 'vitamine_d',
              ),
              _buildHealthSubtypeTile(
                icon: Icons.healing,
                label: 'Vitamine K',
                note: 'vitamine_k',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHealthSubtypeTile({
    required IconData icon,
    required String label,
    required String note,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.sante),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: () {
        final companion = TrackingEventsCompanion(
          type: Value('sante'),
          timestamp: Value(DateTime.now()),
          notes: Value(note),
        );
        DatabaseService().database.insertEvent(companion);
        debugPrint('✅ Suivi santé enregistré : $companion');
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          TrackButton(label: 'Miam', color: AppTheme.miam, onTap: () => _onTrack('Miam')),
          TrackButton(label: 'Santé', color: AppTheme.sante, onTap: () => _onTrack('Santé')),
          TrackButton(label: 'Caca', color: AppTheme.caca, onTap: () => _onTrack('Caca')),
          TrackButton(label: 'Dodo', color: AppTheme.dodo, onTap: () => _onTrack('Dodo')),
        ],
      ),
    );
  }
}
