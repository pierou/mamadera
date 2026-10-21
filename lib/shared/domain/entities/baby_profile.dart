/// Baby profile: information used to identify a newborn being tracked within the application.
///
/// Used as a source of truth for:
/// - Monthly reminders based on the date of birth (e.g., Vitamin K administered on the same day each month).
/// - Age calculation and statistics by postnatal period.
/// - Future support for multiple babies (isActive allows selection of the active baby).

library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'baby_profile.freezed.dart';

/// @freezed BabyProfile model
@freezed
abstract class BabyProfile with _$BabyProfile {
  const factory BabyProfile({
    required String id,
    required String name,
    required DateTime birthDate,
    @Default(true) bool isActive,
  }) = _BabyProfile;
}

/// Clone this profile with updated fields.
BabyProfile babyProfileUpdated(
  BabyProfile profile, {
  String? name,
  DateTime? birthDate,
  bool? isActive,
}) {
  return BabyProfile(
    id: profile.id,
    name: name ?? profile.name,
    birthDate: birthDate ?? profile.birthDate,
    isActive: isActive ?? profile.isActive,
  );
}
