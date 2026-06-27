import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/l10n/date_localization.dart';

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
      builder: (_) => EditEventDialog(event),
    );

    if (!context.mounted) {
      return;
    }

    // Gestion du résultat selon le type (update ou delete) via sealed class
    switch (result) {
      case UpdateResult(): {
        final updated = _applyUpdate(result, event);
        await ref.read(historyNotifierProvider(selectedFilter).notifier).updateEvent(updated);
      }
      case DeleteResult(): {
        if (event.id != null) {
          await ref.read(historyNotifierProvider(selectedFilter).notifier).deleteEvent(event.id!);
        }
      }
      case null:
        break;
    }
  }

  /// Applique les modifications retournées par le dialog sur l'événement original.
  TrackingEvent _applyUpdate(UpdateResult result, TrackingEvent event) {
    final ts = result.timestamp ?? event.timestamp;
    switch (event) {
      case FeedingEvent():
        return FeedingEvent(
          id: event.id!,
          timestamp: ts,
          subtype: event.subtype,
          duration: result.duration ?? event.duration,
          notes: result.notes ?? event.notes,
        );
      case SleepEvent():
        return SleepEvent(
          id: event.id!,
          timestamp: ts,
          duration: result.duration ?? event.duration,
          notes: result.notes ?? event.notes,
        );
      case DiaperEvent():
        return DiaperEvent(
          id: event.id!,
          timestamp: ts,
          wasteType: result.wasteType ?? event.wasteType,
          pipiColor: result.pipiColor ?? event.pipiColor,
          cacaColor: result.cacaColor ?? event.cacaColor,
          notes: result.notes ?? event.notes,
        );
      case HealthEvent():
        // Pour health, les notes contiennent le subtype value. Si changé, créer nouveau subtype.
        final subtype = result.notes != null
            ? (HealthSubtype.byValue(result.notes!) ?? event.subtype)
            : event.subtype;
        return HealthEvent(
          id: event.id!,
          timestamp: ts,
          subtype: subtype,
          notes: result.notes,
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFilter = ref.watch(selectedFilterProvider);
    final eventsAsync = ref.watch(historyNotifierProvider(selectedFilter));

    return Scaffold(
      appBar: AppBar(title: Text(context.l.historyTitle)),
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
                      label: Text(getHistoryFilterLabel(context, filter)),
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
                  return Center(child: Text(context.l.noEvents));
                }
                return ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    final timeFormatted =
                        formatDate(context, event.timestamp);
                    // Skip if no id (shouldn't happen in DB-fetched data, but safe guard)
                    return HistoryTile(
                      event: event,
                      time: timeFormatted,
                      onTap: () => _showEditDialog(context, ref, event, selectedFilter),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text(context.l.errorMessage(error.toString()))),
            ),
          ),
        ],
      ),
    );
  }
}


