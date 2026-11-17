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
        // B13: no `quantity` carried over — the repository clears the column on an
        // edit, so a touched row stops holding the same minutes twice.
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
                  return Padding(
                    padding: const EdgeInsets.only(right: AppTheme.spacingMd),
                    child: _HistoryFilterChip(
                      filter: filter,
                      selected: selectedFilter == filter,
                      onPressed: () => ref
                          .read(selectedFilterProvider.notifier)
                          .setFilter(filter),
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

/// A filter pill for the history timeline, drawn in the **home track-button
/// language** (B29).
///
/// Until now the two controls that both answer « which type of event am I looking
/// at? » lived in two design languages: the home grid used a custom decoration
/// (2px border in the type's accent, tinted fill, soft accent shadow), the history
/// row used stock `FilterChip`s. The owner asked for the pills to look like the
/// buttons — the visible difference being the darker border.
///
/// The two jobs are deliberately split, because a home button has no selected
/// state to copy: the **border** says which type this pill is (the accent, at the
/// same 2px and the same alpha as the grid), and the **fill** says whether it is on
/// (a flat tint where the grid uses a gradient — a chip is not a container we can
/// paint a `LinearGradient` into without abandoning `FilterChip`, which B29's
/// "Do not" forbids replacing with `TrackButton`: these are toggles).
///
/// `all` stays neutral on purpose: it has no type accent at home either, so giving
/// it a colour would invent one.
class _HistoryFilterChip extends StatelessWidget {
  const _HistoryFilterChip({
    required this.filter,
    required this.selected,
    required this.onPressed,
  });

  final HistoryFilter filter;
  final bool selected;
  final VoidCallback onPressed;

  /// The accent of a tracking type — the same constants the home grid paints with.
  /// `null` means neutral, which is what `all` is.
  static Color? accentOf(BuildContext context, HistoryFilter filter) =>
      switch (filter) {
        HistoryFilter.miam => AppTheme.miam,
        HistoryFilter.dodo => AppTheme.dodo,
        HistoryFilter.caca => AppTheme.caca,
        HistoryFilter.sante => AppTheme.sante,
        HistoryFilter.all => null,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // A neutral chip borrows the outline colour rather than a type accent; the
    // selected fill borrows `onSurface` so it stays visible in both themes.
    final accent = accentOf(context, filter) ?? scheme.outline;
    final fill = accent == scheme.outline
        ? scheme.onSurface.withValues(alpha: selected ? 0.16 : 0.04)
        : accent.withValues(alpha: selected ? 0.28 : 0.06);

    return FilterChip(
      label: Text(getHistoryFilterLabel(context, filter)),
      selected: selected,
      onSelected: (_) => onPressed(),
      backgroundColor: fill,
      selectedColor: fill,
      // The accent shadow replaces the elevation shadow the chip would otherwise
      // paint: a grey drop under a tinted pill is the look we are leaving behind.
      elevation: 0,
      pressElevation: 0,
      shadowColor: accent.withValues(alpha: 0.15),
      side: BorderSide(
        color: accent.withValues(alpha: selected ? 0.9 : 0.6),
        width: 2,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.all(Radius.circular(AppTheme.shapeCardRadius)),
      ),
    );
  }
}
