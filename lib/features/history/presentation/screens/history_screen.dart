import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../shared/domain/entities/tracking_enums.dart';
import '../../../../shared/domain/entities/tracking_event.dart';
import '../providers/history_notifier.dart';
import '../widgets/edit_event_dialog.dart';
import '../widgets/history_tile.dart';


class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  /// Liste des filtres pour l'historique (utilisée uniquement pour les labels UI).
  static const List<HistoryFilter> _filters = [
    HistoryFilter.all,
    HistoryFilter.miam,
    HistoryFilter.dodo,
    HistoryFilter.caca,
    HistoryFilter.sante,
  ];

  /// Ouvre le bottom sheet d'édition pour un événement donné.
  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    TrackingEvent event,
    HistoryFilter selectedFilter,
  ) async {
    final result = await showModalBottomSheet<EditResult?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => EditEventDialog(
        type: event.type.label,
        initialTimestamp: event.timestamp,
        initialDuration: event.duration,
        initialNotes: event.notes,
        initialWasteType: event.wasteType?.dbValue, // backward compat pour le dialog
        initialColor: event.colorDbValue,
      ),
    );

    if (!context.mounted) {
      return;
    }

    // Gestion du résultat selon le type (update ou delete) via sealed class
    switch (result) {
      case UpdateResult(): {
        // Construit l'événement mis à jour en conservant le type et l'ID inchangés
        final updated = TrackingEvent(
          id: event.id!,
          type: event.type,
          timestamp: result.timestamp ?? event.timestamp,
          duration: result.duration,
          notes: result.notes,
          wasteType: result.wasteTypeEnum,
          pipiColor: result.pipiColorEnum,
          cacaColor: result.cacaColorEnum,
        );

        await ref.read(historyNotifierProvider(selectedFilter).notifier).updateEvent(updated);
      }
      case DeleteResult(): {
        // Supprime l'événement
        if (event.id != null) {
          await ref.read(historyNotifierProvider(selectedFilter).notifier).deleteEvent(event.id!);
        }
      }
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFilter = ref.watch(selectedFilterProvider);
    final eventsAsync = ref.watch(historyNotifierProvider(selectedFilter));

    return Scaffold(
      appBar: AppBar(title: const Text('Historique')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter.label),
                      selected: isSelected,
                      onSelected: (_) {
                        ref.read(selectedFilterProvider.notifier).setFilter(filter);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: eventsAsync.when(
              data: (events) {
                if (events.isEmpty) {
                  return const Center(child: Text('Aucun événement'));
                }
                return ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    final timeFormatted =
                        DateFormat('dd/MM/yyyy HH:mm').format(event.timestamp);
                    // Skip if no id (shouldn't happen in DB-fetched data, but safe guard)
                    return HistoryTile(
                      type: event.type.label,
                      time: timeFormatted,
                      notes: event.notes,
                      duration: event.duration,
                      wasteType: event.wasteType?.dbValue, // backward compat pour le tile
                      color: event.colorDbValue,
                      onTap: () => _showEditDialog(context, ref, event, selectedFilter),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Erreur: $error')),
            ),
          ),
        ],
      ),
    );
  }
}


