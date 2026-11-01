import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/l10n/date_localization.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets/show_feedback.dart';
import '../../../../shared/domain/entities/tracking_enums.dart';
import '../../../../shared/domain/entities/tracking_event.dart';
import '../../../growth/domain/entities/growth_measurement.dart';
import '../../../growth/presentation/widgets/edit_measurement_sheet.dart';
import '../../domain/history_row.dart';
import '../providers/history_notifier.dart';
import '../widgets/edit_event_dialog.dart';
import '../widgets/history_tile.dart';
import '../widgets/measurement_history_tile.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  /// List of filters for the history (used only for UI labels).
  static const List<HistoryFilter> _filters = [
    HistoryFilter.all,
    HistoryFilter.miam,
    HistoryFilter.dodo,
    HistoryFilter.caca,
    HistoryFilter.sante,
  ];

  /// Opens the editing panel for a specific event.
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
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTheme.shapeBottomSheetRadius)),
      ),
      builder: (_) => EditEventDialog(event),
    );

    if (!context.mounted) {
      return;
    }

    // Managing the outcome based on the type of operation (update or delete) using a sealed class.
    switch (result) {
      case UpdateResult():
        {
          final updated = _applyUpdate(result, event);
          try {
            await ref
                .read(historyNotifierProvider(selectedFilter).notifier)
                .updateEvent(updated);
            if (context.mounted) {
              showFeedback(context, context.l.historyUpdatedSuccess);
            }
          } catch (e) {
            if (context.mounted) {
              showError(
                context,
                context.l.historyUpdateError('$e'),
              );
            }
          }
        }
      case DeleteResult():
        {
          if (event.id != null) {
            try {
              await ref
                  .read(historyNotifierProvider(selectedFilter).notifier)
                  .deleteEvent(event.id!);
              if (context.mounted) {
                showFeedback(context, context.l.historyDeletedSuccess);
              }
            } catch (e) {
              if (context.mounted) {
                showError(
                  context,
                  context.l.historyDeleteError('$e'),
                );
              }
            }
          }
        }
      case null:
        break;
    }
  }

  /// Open the editing sheet for a growth measure (unified scale).
  /// v1.2.1: The line is either corrected on-site or removed.
  Future<void> _showEditMeasurementSheet(
    BuildContext context,
    WidgetRef ref,
    GrowthMeasurement measurement,
    HistoryFilter selectedFilter,
  ) async {
    final result =
        await EditMeasurementSheet.show(context, measurement: measurement);

    if (!context.mounted) {
      return;
    }

    switch (result) {
      case final MeasurementUpdated updated:
        try {
          await ref
              .read(historyNotifierProvider(selectedFilter).notifier)
              .updateMeasurement(updated.measurement);
          if (context.mounted) {
            showFeedback(context, context.l.growthMeasurementUpdated);
          }
        } catch (e) {
          if (context.mounted) {
            showError(context, context.l.growthMeasurementUpdateError('$e'));
          }
        }
      case final MeasurementDeleted deleted:
        try {
          await ref
              .read(historyNotifierProvider(selectedFilter).notifier)
              .deleteMeasurement(deleted.id);
          if (context.mounted) {
            showFeedback(context, context.l.growthMeasurementDeleted);
          }
        } catch (e) {
          if (context.mounted) {
            showError(context, context.l.growthMeasurementDeleteError('$e'));
          }
        }
      case null:
        break;
    }
  }

  /// Apply the modifications returned by the dialog to the original event.
  TrackingEvent _applyUpdate(UpdateResult result, TrackingEvent event) {
    final ts = result.timestamp ?? event.timestamp;
    return event.map(
      (e) => throw StateError('Cannot update base TrackingEvent'),
      feeding: (e) => TrackingEvent.feeding(
        id: e.id,
        timestamp: ts,
        subtype: result.subtype ?? e.subtype,
        // The unit follows the specified line and subtype: changing from...
        // `natural` to `solid` changes `g` to, and keeping it within the range preserves the choice of...
        // parent (`ml` or `min`). Never a silent defect.
        unit: result.unit ?? e.unit,
        quantity: result.quantity ?? e.quantity,
        notes: result.notes ?? e.notes,
        babyId: e.babyId,
      ),
      sleep: (e) => TrackingEvent.sleep(
        id: e.id,
        timestamp: ts,
        duration: result.duration ?? e.duration,
        unit: e.unit,
        quantity: result.quantity ?? e.quantity,
        notes: result.notes ?? e.notes,
        babyId: e.babyId,
      ),
      diaper: (e) => TrackingEvent.diaper(
        id: e.id,
        timestamp: ts,
        wasteType: result.wasteType ?? e.wasteType,
        pipiColor: result.pipiColor ?? e.pipiColor,
        cacaColor: result.cacaColor ?? e.cacaColor,
        stoolTexture: result.stoolTexture ?? e.stoolTexture,
        notes: result.notes ?? e.notes,
        babyId: e.babyId,
      ),
      health: (e) => TrackingEvent.health(
        id: e.id,
        timestamp: ts,
        subtype: result.healthSubtype ?? e.subtype,
        notes: result.notes ?? e.notes,
        babyId: e.babyId,
      ),
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
                        ref
                            .read(selectedFilterProvider.notifier)
                            .setFilter(filter);
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
              data: (rows) {
                if (rows.isEmpty) {
                  return Center(child: Text(context.l.noEvents));
                }
                // Unified timeline: a line represents either a tracking event,
                // either a measure of growth (a numerically quantified "ground truth" file),
                // never duplicated here).
                return ListView.builder(
                  itemCount: rows.length,
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    final timeFormatted = formatDate(context, row.timestamp);
                    return switch (row) {
                      EventHistoryRow(:final event) => HistoryTile(
                          event: event,
                          time: timeFormatted,
                          onTap: () => _showEditDialog(
                              context, ref, event, selectedFilter),
                        ),
                      MeasurementHistoryRow(:final measurement) =>
                        MeasurementHistoryTile(
                          measurement: measurement,
                          time: timeFormatted,
                          onTap: () => _showEditMeasurementSheet(
                              context, ref, measurement, selectedFilter),
                        ),
                    };
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) =>
                  Center(child: Text(context.l.errorMessage(error.toString()))),
            ),
          ),
        ],
      ),
    );
  }
}
