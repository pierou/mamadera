import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/l10n/unit_localization.dart';
import '../../../../core/theme.dart';
import '../../../../shared/domain/entities/quantity_unit.dart';
import '../../../../shared/domain/entities/tracking_enums.dart';
import '../../../../shared/domain/entities/tracking_event.dart';
import '../../../../shared/domain/entities/tracking_type.dart';
import '../../../../shared/utils/stool_texture_label_resolver.dart';
import '../../../../shared/widgets/tracking_icons.dart';

/// Tile displaying an event in the history.
class HistoryTile extends StatelessWidget {
  const HistoryTile({
    required this.event,
    required this.time,
    super.key,
    this.onTap,
  });

  final TrackingEvent event;
  final String time;   // formatted as dd/MM/yyyy HH:mm.
  final VoidCallback? onTap;

  String _typeLabel(BuildContext context) {
    return event.map(
      (_) => '',
      feeding: (_) => context.l.typeLabelMiam,
      sleep: (_) => context.l.typeLabelSommeil,
      diaper: (e) {
        switch (e.wasteType) {
          case WasteType.pipi:
            return context.l.typeLabelPipi;
          case WasteType.lesDeux:
            return context.l.typeLabelPipiEtCaca;
          default:
            return context.l.typeLabelCaca;
        }
      },
      health: (e) => _resolveLabelKey(context, e.subtype.labelKey),
    );
  }

  String _resolveLabelKey(BuildContext context, String labelKey) {
    switch (labelKey) {
      case 'pipiColorIncolore':
        return context.l.pipiColorIncolore;
      case 'pipiColorJauneClair':
        return context.l.pipiColorJauneClair;
      case 'pipiColorJauneFonce':
        return context.l.pipiColorJauneFonce;
      case 'pipiColorRoseUrates':
        return context.l.pipiColorRoseUrates;
      case 'cacaColorMeconium':
        return context.l.cacaColorMeconium;
      case 'cacaColorVertOlive':
        return context.l.cacaColorVertOlive;
      case 'cacaColorJauneMoutarde':
        return context.l.cacaColorJauneMoutarde;
      case 'cacaColorJauneClair':
        return context.l.cacaColorJauneClair;
      case 'healthNettoyageYeux':
        return context.l.healthNettoyageYeux;
      case 'healthNettoyageNombril':
        return context.l.healthNettoyageNombril;
      case 'healthNettoyageVisage':
        return context.l.healthNettoyageVisage;
      case 'healthNettoyageNez':
        return context.l.healthNettoyageNez;
      case 'healthVitamineD':
        return context.l.healthVitamineD;
      case 'healthVitamineK':
        return context.l.healthVitamineK;
      default:
        return labelKey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: HistoryTileLeading(event: event, context: context),
        title: Text(_typeLabel(context)),
        subtitle: HistoryTileSubtitle(event: event, context: context),
        trailing:
            HistoryTileTrailing(time: time, onTap: onTap, context: context),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: onTap,
      ),
    );
  }
}

/// Leading icon widget for HistoryTile.
class HistoryTileLeading extends StatelessWidget {
  const HistoryTileLeading(
      {required this.event, required this.context, super.key});

  final TrackingEvent event;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    final icon = event.map(
      (_) => Icons.help,
      feeding: (_) => TrackingType.miam.icon,
      sleep: (_) => TrackingType.dodo.icon,
      diaper: (e) => e.wasteType?.icon ?? WasteType.caca.icon,
      health: (_) => TrackingType.sante.icon,
    );

    return CircleAvatar(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      child: Icon(icon, color: Theme.of(context).colorScheme.primary),
    );
  }
}

/// Subtitle widget showing duration, color indicators, and notes.
class HistoryTileSubtitle extends StatelessWidget {
  const HistoryTileSubtitle(
      {required this.event, required this.context, super.key});

  final TrackingEvent event;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (event is FeedingEvent) ..._buildFeedingSubtypeRow(),
        if (_quantityRowData() != null)
          Text(context.l.quantityPrefix(
            _quantityRowData()!.$1.toInt(),
            quantityUnitLabel(context, _quantityRowData()!.$2),
          )),
        if (_getDuration(event) != null)
          Text(context.l.durationPrefix(_getDuration(event)!.toInt())),
        if (_hasWasteDetails) ...[
          _buildColors(context),
        ],
        _buildTexture(context),
        if (event is! HealthEvent &&
            _getNotes(event) != null &&
            _getNotes(event)!.isNotEmpty)
          Text(_getNotes(event)!),
      ],
    );
  }

  /// The number and unit of the line, both read **from the line**.
  ///
  /// `null` = no quantity (layer, care, **sleep**). The unit is derived from...
  /// `event.unit` (v12) and not a literal value from the widget: this is the default behavior.
  /// This version removes the display of "ml" next to a feeding session that lasts 20 minutes.
  ///
  /// Sleep tracking doesn't generate any data points here; the app only records the minutes of sleep.
  /// The nap duration is specified in both **`quantity`** and **`duration`** (they have the same value, see the home screen).
  /// and the "Duration" field already displays this information. Also, show "Quantity: 45 min".
  /// It repeated the same number under two different labels; "Duration" is the label.
  /// naturel d'une sieste.
  (double, QuantityUnit)? _quantityRowData() {
    final event = this.event;
    if (event is FeedingEvent && event.quantity != null) {
      return (event.quantity!, event.unit);
    }
    return null;
  }

  double? _getDuration(TrackingEvent event) {
    return event.map(
      (_) => null,
      feeding: (_) => null,
      sleep: (e) => e.duration,
      diaper: (_) => null,
      health: (_) => null,
    );
  }

  String? _getNotes(TrackingEvent event) {
    return event.map(
      (_) => null,
      feeding: (e) => e.notes,
      sleep: (e) => e.notes,
      diaper: (e) => e.notes,
      health: (e) => e.notes,
    );
  }

  bool get _hasWasteDetails =>
      event is DiaperEvent && (event as DiaperEvent).wasteType != null;

  List<Widget> _buildFeedingSubtypeRow() {
    if (event is! FeedingEvent) return const [];
    final feeding = event as FeedingEvent;
    return [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(feeding.subtype.icon,
              size: 16, color: _getSubtypeColor(feeding.subtype)),
          const SizedBox(width: 4),
          Text(
            switch (feeding.subtype) {
              FeedingSubtype.natural => context.l.feedingSubtypeNatural,
              FeedingSubtype.artificial => context.l.feedingSubtypeArtificial,
              FeedingSubtype.solid => context.l.feedingSolid,
            },
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ];
  }

  Color _getSubtypeColor(FeedingSubtype subtype) {
    return subtype == FeedingSubtype.natural
        ? AppTheme.miam
        : Theme.of(context).colorScheme.secondary;
  }

  String _resolveLabelKey(BuildContext context, String labelKey) {
    switch (labelKey) {
      // PipiColor labels
      case 'pipiColorIncolore':
        return context.l.pipiColorIncolore;
      case 'pipiColorJauneClair':
        return context.l.pipiColorJauneClair;
      case 'pipiColorJauneFonce':
        return context.l.pipiColorJauneFonce;
      case 'pipiColorRoseUrates':
        return context.l.pipiColorRoseUrates;
      // CacaColor labels
      case 'cacaColorMeconium':
        return context.l.cacaColorMeconium;
      case 'cacaColorVertOlive':
        return context.l.cacaColorVertOlive;
      case 'cacaColorJauneMoutarde':
        return context.l.cacaColorJauneMoutarde;
      case 'cacaColorJauneClair':
        return context.l.cacaColorJauneClair;
      default:
        return labelKey;
    }
  }

  /// Consistency line, displayed only if the layer has one (plural).
  /// Changes made before this option was enabled are not affected by it and will not be affected in the future.
  /// by default).
  Widget _buildTexture(BuildContext context) {
    final event = this.event;
    if (event is! DiaperEvent || event.stoolTexture == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        resolveStoolTextureLabel(context, event.stoolTexture!),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  Widget _buildColors(BuildContext context) {
    if (event is! DiaperEvent) return const SizedBox.shrink();
    final diaper = event as DiaperEvent;

    final colors = <MapEntry<String, Color>>[];
    if (diaper.pipiColor != null) {
      colors.add(MapEntry(
        _resolveLabelKey(context, diaper.pipiColor!.labelKey),
        Color(diaper.pipiColor!.colorHex),
      ));
    }
    if (diaper.cacaColor != null) {
      colors.add(MapEntry(
        _resolveLabelKey(context, diaper.cacaColor!.labelKey),
        Color(diaper.cacaColor!.colorHex),
      ));
    }
    if (colors.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: colors
          .map((entry) => _ColorChip(label: entry.key, color: entry.value))
          .toList(),
    );
  }
}

/// Small colored chip showing a waste color.
class _ColorChip extends StatelessWidget {
  const _ColorChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppTheme.spacingSm),
      child: Tooltip(
        message: label,
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border:
                Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
        ),
      ),
    );
  }
}

/// Trailing widget showing time and edit indicator.
class HistoryTileTrailing extends StatelessWidget {
  const HistoryTileTrailing(
      {required this.time,
      required this.onTap,
      required this.context,
      super.key});

  final String time;
  final VoidCallback? onTap;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    // Date format (two lines): The `formatDate` function always separates the date and time.
    // using a **single** space (in `MM/dd/yyyy hh:mm a` format, for French/Spanish).
    // `dd/MM/yyyy HH:mm`), and the date token never contains any spaces.
    // Therefore, the first element is the date, and the rest represents the time.
    //
    // Version 1.2.1 has restored the minutes to the English date format ("09:32 PM," etc.).
    // (instead of "09:PM"): on the smallest target (Small_Phone, 360 dp) in...
    // English: The date, displayed on a single line, was too wide for the available space.
    // The remaining text was cut off, and the title line extended beyond the visible area by 12 pixels ("Feedin…"). Two.
    // These settings adjust the width of the block to match the width of the date alone.
    final parts = time.split(' ');
    final datePart = parts.first;
    final timePart = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    final small = Theme.of(context).textTheme.bodySmall;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(datePart, style: small),
            if (timePart.isNotEmpty) Text(timePart, style: small),
          ],
        ),
        if (onTap != null) ...[
          const SizedBox(width: 8),
          Icon(Icons.edit_outlined,
              size: 16, color: Theme.of(context).colorScheme.secondary),
        ],
      ],
    );
  }
}
