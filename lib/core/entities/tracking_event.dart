/// Entity pure pour un événement de suivi
class TrackingEvent {

  TrackingEvent({
    required this.type, required this.timestamp, this.id,
    this.duration,
    this.notes,
  });
  final int? id;
  final String type;
  final DateTime timestamp;
  final double? duration;
  final String? notes;
}
