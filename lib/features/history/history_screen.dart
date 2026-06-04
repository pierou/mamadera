import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/local/database.dart';
import '../../widgets/history_tile.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedFilter = 'all';
  final DatabaseService _dbService = DatabaseService();

  static const List<Map<String, dynamic>> _filters = [
    {'value': 'all', 'label': 'Tous'},
    {'value': 'miam', 'label': 'Miam'},
    {'value': 'dodo', 'label': 'Sommeil'},
    {'value': 'caca', 'label': 'Caca'},
    {'value': 'sante', 'label': 'Santé'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historique')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = _selectedFilter == filter['value'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter['label'] as String),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = filter['value'] as String;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder(
              future: _selectedFilter == 'all'
                  ? _dbService.database.getAllEventsOrdered()
                  : _dbService.database.getEventsByType(_selectedFilter),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Erreur: ${snapshot.error}'));
                }
                final events = snapshot.data ?? [];
                if (events.isEmpty) {
                  return const Center(child: Text('Aucun événement'));
                }
                return ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    final timeFormatted = DateFormat('dd/MM/yyyy HH:mm')
                        .format(event.timestamp);
                    return HistoryTile(
                      type: event.type,
                      time: timeFormatted,
                      notes: event.notes,
                      duration: event.duration,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
