import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../reminders/presentation/providers/reminder_providers.dart';

final navIndexProvider = NotifierProvider<NavIndexNotifier, int>(
  NavIndexNotifier.new,
);

class NavIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) {
    if (index == 0) {
      // Invalidate baby profile to rebuild dynamic reminder items (e.g., after baby profile changes in Menu)
      ref.invalidate(babyProfileProvider);
      // Force immediate recalculation of reminder statuses against fresh DB data
      ref.read(reminderNotifierProvider.notifier).refresh();
    }
    state = index;
  }
}
