import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/database_provider.dart';
import '../../data/repositories/reminders_repository_impl.dart';
import '../../domain/entities/reminder_item.dart';
import '../../domain/services/reminders_service.dart';

/// Provider for the reminders repository implementation.
final remindersRepositoryProvider = FutureProvider((ref) async {
  final database = await ref.watch(databaseProvider.future);
  return RemindersRepositoryImpl(database: database);
});

/// Static list of registered reminder items — starts with Vitamin D only, extensible later.
// ignore: non_constant_identifier_names
List<ReminderItem> get registeredReminders => [
      ReminderItem.vitaminD(),
    ];

/// Provider for the reminders service (pure business logic layer).
final remindersServiceProvider = FutureProvider((ref) async {
  final repository = await ref.watch(remindersRepositoryProvider.future);
  return RemindersService(items: registeredReminders, repository: repository);
});
