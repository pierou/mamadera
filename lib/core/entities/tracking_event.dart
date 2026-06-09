import 'package:equatable/equatable.dart';

/// Entity pure pour un événement de suivi
class TrackingEvent extends Equatable {
  const TrackingEvent({
    required this.type,
    required this.timestamp,
    this.id,
    this.duration,
    this.notes,
  });

  final int? id;
  final String type;
  final DateTime timestamp;
  final double? duration;
  final String? notes;

  @override
  List<Object?> get props => [id, type, timestamp, duration, notes];

  @override
  String toString() =>
      'TrackingEvent(id: $id, type: $type, timestamp: $timestamp, duration: $duration, notes: $notes)';
}
