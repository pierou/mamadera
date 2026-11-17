import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/domain/entities/tracking_enums.dart';

/// A reminder whose **care sheet** the parent asked for by tapping a notification
/// (B15, D-R9), or `null` when nothing is pending.
///
/// Why a provider and not a direct `showModalBottomSheet`: a tap arrives from the
/// notification service, which owns no `BuildContext`, and the sheet belongs to
/// Home, which owns the care flow (and its tracking write, its feedback toast, the
/// reminder refresh). So the tap leaves a request here and Home consumes it — the
/// same one-decision-per-screen shape as the rest of the app, and it is what makes
/// the branch testable without a navigator.
///
/// [subtype] is what to pre-select; [itemId] is kept for the log line and for the
/// screen's own "this came from a reminder" behaviour, never to decide what to
/// write: the parent still confirms through the existing care flow (D-R9), and a
/// sheet dismissed without confirming writes nothing.
class PendingCareSheet {
  const PendingCareSheet({required this.subtype, required this.itemId});

  final HealthSubtype subtype;
  final String itemId;
}

/// Where a notification tap leaves its request for the care sheet. Consumed by
/// `HomeScreen`, which clears it as it opens the sheet (see
/// `PendingCareSheetNotifier.take`).
final pendingCareSheetProvider =
    NotifierProvider<PendingCareSheetNotifier, PendingCareSheet?>(
  PendingCareSheetNotifier.new,
);

class PendingCareSheetNotifier extends Notifier<PendingCareSheet?> {
  @override
  PendingCareSheet? build() => null;

  /// Ask Home to open the care sheet for [request].
  void request(PendingCareSheet request) => state = request;

  /// Read and clear in one step.
  ///
  /// The clear is part of the read because there are two entry points on Home —
  /// the first build after a tap that navigated here, and the listener for a tap
  /// that arrived while Home was already on screen. Without an atomic take, both
  /// could fire and stack two sheets for one tap.
  PendingCareSheet? take() {
    final pending = state;
    if (pending != null) state = null;
    return pending;
  }
}
