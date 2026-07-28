import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/l10n/date_localization.dart';

import '../../../../core/theme.dart';
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.shapeBottomSheetRadius)),
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
    return event.map(
      (e) => throw StateError('Cannot update base TrackingEvent'),
      feeding: (e) => TrackingEvent.feeding(
        id: e.id,
        timestamp: ts,
        subtype: result.subtype ?? e.subtype,
        quantity: result.quantity ?? e.quantity,
        notes: result.notes ?? e.notes,
        babyId: e.babyId,
      ),
      sleep: (e) => TrackingEvent.sleep(
        id: e.id,
        timestamp: ts,
        duration: result.duration ?? e.duration,
        notes: result.notes ?? e.notes,
        babyId: e.babyId,
      ),
      diaper: (e) => TrackingEvent.diaper(
        id: e.id,
        timestamp: ts,
        wasteType: result.wasteType ?? e.wasteType,
        pipiColor: result.pipiColor ?? e.pipiColor,
        cacaColor: result.cacaColor ?? e.cacaColor,
        notes: result.notes ?? e.notes,
        babyId: e.babyId,
      ),
      health: (e) {
        // Pour health, les notes contiennent le subtype value. Si changé, créer nouveau subtype.
        final subtype = result.notes != null
            ? (HealthSubtype.byValue(result.notes!) ?? e.subtype)
            : e.subtype;
        return TrackingEvent.health(
          id: e.id,
          timestamp: ts,
          subtype: subtype,
          notes: result.notes,
          babyId: e.babyId,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFilter = ref.watch(selectedFilterProvider);
    final eventsAsync = ref.watch(historyNotifierProvider(selectedFilter));

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l.historyTitle),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppTheme.spacingMd),
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


