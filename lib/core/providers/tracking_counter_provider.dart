import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Counter that increments each time a tracking event is successfully recorded.
/// Used to trigger reminder re-evaluation when tracking occurs.
class TrackingCounterNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void increment() {
    state = state + 1;
  }
}

final trackingCounterProvider = NotifierProvider<TrackingCounterNotifier, int>(
  TrackingCounterNotifier.new,
);
