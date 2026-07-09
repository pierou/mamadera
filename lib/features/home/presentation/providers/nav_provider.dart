import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/active_baby_provider.dart';
import '../../../reminders/presentation/providers/reminder_providers.dart';

final navIndexProvider = NotifierProvider<NavIndexNotifier, int>(
  NavIndexNotifier.new,
);

class NavIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) {
    if (index == 0) {
      // Refresh active baby when navigating home
      ref.read(activeBabyProvider.notifier).refresh();
      // Force immediate recalculation of reminder statuses
      ref.read(reminderNotifierProvider.notifier).refresh();
    }
    state = index;
  }
}
