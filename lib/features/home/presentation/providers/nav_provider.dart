import 'package:riverpod/legacy.dart';

final navIndexProvider = StateNotifierProvider<NavIndexNotifier, int>(
  (ref) => NavIndexNotifier(),
);

class NavIndexNotifier extends StateNotifier<int> {
  NavIndexNotifier() : super(0);

  void setIndex(int index) => state = index;
}
