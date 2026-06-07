import 'package:flutter/material.dart';

class HistoryTile extends StatelessWidget {

  const HistoryTile({
    required this.type, required this.time, super.key,
    this.notes,
    this.duration,
  });
  final String type;
  final String time;
  final String? notes;
  final double? duration;

  IconData _getIcon() {
    switch (type) {
      case 'miam':
        return Icons.lunch_dining;
      case 'dodo':
        return Icons.nightlight;
      case 'caca':
        return Icons.water_drop;
      case 'sante':
        return Icons.favorite;
      default:
        return Icons.circle;
    }
  }

  String _getTypeLabel() {
    if (type == 'sante' && notes != null && notes!.isNotEmpty) {
      switch (notes) {
        case 'nettoyage_yeux':
          return 'Nettoyage des yeux';
        case 'nettoyage_nombril':
          return 'Nettoyage du nombril';
        case 'nettoyage_visage':
          return 'Nettoyage du visage';
        case 'nettoyage_nez':
          return 'Nettoyage du nez';
        case 'vitamine_d':
          return 'Vitamine D';
        case 'vitamine_k':
          return 'Vitamine K';
        default:
          return notes!;
      }
    }

    switch (type) {
      case 'miam':
        return 'Miam';
      case 'dodo':
        return 'Sommeil';
      case 'caca':
        return 'Caca';
      case 'sante':
        return 'Santé';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(_getIcon(), color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(_getTypeLabel()),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (duration != null) Text('Durée: ${duration!.toInt()} min'),
            if (type != 'sante' && notes != null && notes!.isNotEmpty)
              Text(notes!),
          ],
        ),
        trailing: Text(time),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
