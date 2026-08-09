import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/theme.dart';
import '../../../../shared/domain/entities/tracking_enums.dart';
import '../../../../shared/domain/entities/tracking_event.dart';
import '../../../../shared/domain/entities/tracking_icons.dart';
import '../../../../shared/domain/entities/tracking_type.dart';

/// Tile affichant un événement dans l'historique.
class HistoryTile extends StatelessWidget {
  const HistoryTile({
    required this.event,
    required this.time,
    super.key,
    this.onTap,
  });

  final TrackingEvent event;
  final String time; // formaté en dd/MM/yyyy HH:mm
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
        trailing: HistoryTileTrailing(time: time, onTap: onTap, context: context),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: onTap,
      ),
    );
  }
}

/// Leading icon widget for HistoryTile.
class HistoryTileLeading extends StatelessWidget {
  const HistoryTileLeading({required this.event, required this.context, super.key});

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
  const HistoryTileSubtitle({required this.event, required this.context, super.key});

  final TrackingEvent event;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (event is FeedingEvent) ..._buildFeedingSubtypeRow(),
        if (_getQuantity(event) != null)
          Text(context.l.quantityPrefix(_getQuantity(event)!.toInt(), event.map(
            (_) => '',
            feeding: (_) => 'ml',
            sleep: (_) => context.l.minuteSuffix,
            diaper: (_) => '',
            health: (_) => '',
          ))),
        if (_getDuration(event) != null)
          Text(context.l.durationPrefix(_getDuration(event)!.toInt())),
        if (_hasWasteDetails) ...[
          _buildColors(context),
        ],
        if (event is! HealthEvent && _getNotes(event) != null && _getNotes(event)!.isNotEmpty)
          Text(_getNotes(event)!),
      ],
    );
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

  double? _getQuantity(TrackingEvent event) {
    return event.map(
      (_) => null,
      feeding: (e) => e.quantity,
      sleep: (e) => e.quantity,
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

  bool get _hasWasteDetails => event is DiaperEvent && (event as DiaperEvent).wasteType != null;

  List<Widget> _buildFeedingSubtypeRow() {
    if (event is! FeedingEvent) return const [];
    final feeding = event as FeedingEvent;
    return [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(feeding.subtype.icon, size: 16, color: _getSubtypeColor(feeding.subtype)),
          const SizedBox(width: 4),
          Text(
            feeding.subtype == FeedingSubtype.natural
                ? context.l.feedingSubtypeNatural
                : context.l.feedingSubtypeArtificial,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ];
  }

  Color _getSubtypeColor(FeedingSubtype subtype) {
    return subtype == FeedingSubtype.natural ? AppTheme.miam : Theme.of(context).colorScheme.secondary;
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
      children: colors.map((entry) => _ColorChip(label: entry.key, color: entry.value)).toList(),
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
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
        ),
      ),
    );
  }
}

/// Trailing widget showing time and edit indicator.
class HistoryTileTrailing extends StatelessWidget {
  const HistoryTileTrailing({required this.time, required this.onTap, required this.context, super.key});

  final String time;
  final VoidCallback? onTap;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(time),
        if (onTap != null) ...[
          const SizedBox(width: 8),
          Icon(Icons.edit_outlined, size: 16, color: Theme.of(context).colorScheme.secondary),
        ],
      ],
    );
  }
}
