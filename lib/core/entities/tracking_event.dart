/// Entity pure pour un événement de suivi
class TrackingEvent {
  final int? id;
  final String type;
  final DateTime timestamp;
  final double? duration;
  final String? notes;

  TrackingEvent({
    this.id,
    required this.type,
    required this.timestamp,
    this.duration,
    this.notes,
  });
}
