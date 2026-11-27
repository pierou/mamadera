// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reminder_item_setting.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ReminderItemSetting {
  /// The switch. Once a row exists it means exactly what it says; absence is
  /// what `enabledByDefault` is for (B6).
  bool get enabled;

  /// Per-reminder notification hour, `'HH:mm'` (B30).
  ///
  /// `null` means **inherit the global hour**
  /// (`app_settings.notification_time_of_day`), not "has no hour". Read lax:
  /// a stored string that is not a valid `HH:mm` is treated as "inherit" by
  /// the scheduler rather than falling back to the app default — the global
  /// hour is the closer promise, and it is the one the parent can still see
  /// and fix. Written strict (`isValidNotificationTime` at the picker; the
  /// importer refuses the same value outright): the split documented in
  /// `notification_time.dart`.
  String? get timeOfDay;

  /// End of the series, `'yyyy-MM-dd'` (D-R5 form 2). `null` = no stored date.
  ///
  /// One of the two ways a reminder can end; **at most one** of
  /// [endDate]/[endAgeMonths] is ever set (D-R5's mutual exclusivity, enforced
  /// at write and at import — the schema only has the columns). Read it through
  /// `reminderEndFor`, never by parsing this field in place: the age form has
  /// to be resolved against the baby's birthdate, and a row that somehow holds
  /// both has to resolve to one answer.
  String? get endDate;

  /// End of the series as the baby's age in whole months, 0-180 (D-R5 form 3).
  ///
  /// Stored as *months*, never as the date it implies: a corrected birthdate
  /// then moves the end by itself, because the date is computed at read time
  /// (`reminderEndFor`) and there is no stored value to go stale.
  int? get endAgeMonths;

  /// Preset label override, the parent's wording (B33/D-R6). `null` = the
  /// preset's localized name. Never written for a custom reminder — its label
  /// lives in `custom_reminders.label`, and this row must not become a second
  /// source of truth for the same name.
  String? get label;

  /// Frequency override, a `db_constants` code (B33). `null` = the preset's own
  /// frequency, which is also how "back to the default rhythm" is written.
  ///
  /// [frequencyDate] is meaningful **only** when this is `one_time` — the
  /// resolution order D-R8 spells out, and the one that keeps Vitamin K at one
  /// month instead of at birth.
  String? get frequency;

  /// `interval_days` for a `frequency` of `every_n_days`.
  int? get intervalDays;

  /// `frequency_date` for a `frequency` of `one_time`: the occurrence day,
  /// `'yyyy-MM-dd'`.
  String? get frequencyDate;

  /// The third state (D-R2): hidden from the lists and from the schedule, but
  /// **not deleted** — a removed preset stays restorable (D-R4), and its
  /// [enabled] value is kept as stored, moot until a restore.
  bool get removed;

  /// Create a copy of ReminderItemSetting
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ReminderItemSettingCopyWith<ReminderItemSetting> get copyWith =>
      _$ReminderItemSettingCopyWithImpl<ReminderItemSetting>(
          this as ReminderItemSetting, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ReminderItemSetting &&
            (identical(other.enabled, enabled) || other.enabled == enabled) &&
            (identical(other.timeOfDay, timeOfDay) ||
                other.timeOfDay == timeOfDay) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(other.endAgeMonths, endAgeMonths) ||
                other.endAgeMonths == endAgeMonths) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.frequency, frequency) ||
                other.frequency == frequency) &&
            (identical(other.intervalDays, intervalDays) ||
                other.intervalDays == intervalDays) &&
            (identical(other.frequencyDate, frequencyDate) ||
                other.frequencyDate == frequencyDate) &&
            (identical(other.removed, removed) || other.removed == removed));
  }

  @override
  int get hashCode => Object.hash(runtimeType, enabled, timeOfDay, endDate,
      endAgeMonths, label, frequency, intervalDays, frequencyDate, removed);

  @override
  String toString() {
    return 'ReminderItemSetting(enabled: $enabled, timeOfDay: $timeOfDay, endDate: $endDate, endAgeMonths: $endAgeMonths, label: $label, frequency: $frequency, intervalDays: $intervalDays, frequencyDate: $frequencyDate, removed: $removed)';
  }
}

/// @nodoc
abstract mixin class $ReminderItemSettingCopyWith<$Res> {
  factory $ReminderItemSettingCopyWith(
          ReminderItemSetting value, $Res Function(ReminderItemSetting) _then) =
      _$ReminderItemSettingCopyWithImpl;
  @useResult
  $Res call(
      {bool enabled,
      String? timeOfDay,
      String? endDate,
      int? endAgeMonths,
      String? label,
      String? frequency,
      int? intervalDays,
      String? frequencyDate,
      bool removed});
}

/// @nodoc
class _$ReminderItemSettingCopyWithImpl<$Res>
    implements $ReminderItemSettingCopyWith<$Res> {
  _$ReminderItemSettingCopyWithImpl(this._self, this._then);

  final ReminderItemSetting _self;
  final $Res Function(ReminderItemSetting) _then;

  /// Create a copy of ReminderItemSetting
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? enabled = null,
    Object? timeOfDay = freezed,
    Object? endDate = freezed,
    Object? endAgeMonths = freezed,
    Object? label = freezed,
    Object? frequency = freezed,
    Object? intervalDays = freezed,
    Object? frequencyDate = freezed,
    Object? removed = null,
  }) {
    return _then(_self.copyWith(
      enabled: null == enabled
          ? _self.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      timeOfDay: freezed == timeOfDay
          ? _self.timeOfDay
          : timeOfDay // ignore: cast_nullable_to_non_nullable
              as String?,
      endDate: freezed == endDate
          ? _self.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as String?,
      endAgeMonths: freezed == endAgeMonths
          ? _self.endAgeMonths
          : endAgeMonths // ignore: cast_nullable_to_non_nullable
              as int?,
      label: freezed == label
          ? _self.label
          : label // ignore: cast_nullable_to_non_nullable
              as String?,
      frequency: freezed == frequency
          ? _self.frequency
          : frequency // ignore: cast_nullable_to_non_nullable
              as String?,
      intervalDays: freezed == intervalDays
          ? _self.intervalDays
          : intervalDays // ignore: cast_nullable_to_non_nullable
              as int?,
      frequencyDate: freezed == frequencyDate
          ? _self.frequencyDate
          : frequencyDate // ignore: cast_nullable_to_non_nullable
              as String?,
      removed: null == removed
          ? _self.removed
          : removed // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// Adds pattern-matching-related methods to [ReminderItemSetting].
extension ReminderItemSettingPatterns on ReminderItemSetting {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_ReminderItemSetting value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ReminderItemSetting() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_ReminderItemSetting value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ReminderItemSetting():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_ReminderItemSetting value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ReminderItemSetting() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            bool enabled,
            String? timeOfDay,
            String? endDate,
            int? endAgeMonths,
            String? label,
            String? frequency,
            int? intervalDays,
            String? frequencyDate,
            bool removed)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ReminderItemSetting() when $default != null:
        return $default(
            _that.enabled,
            _that.timeOfDay,
            _that.endDate,
            _that.endAgeMonths,
            _that.label,
            _that.frequency,
            _that.intervalDays,
            _that.frequencyDate,
            _that.removed);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            bool enabled,
            String? timeOfDay,
            String? endDate,
            int? endAgeMonths,
            String? label,
            String? frequency,
            int? intervalDays,
            String? frequencyDate,
            bool removed)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ReminderItemSetting():
        return $default(
            _that.enabled,
            _that.timeOfDay,
            _that.endDate,
            _that.endAgeMonths,
            _that.label,
            _that.frequency,
            _that.intervalDays,
            _that.frequencyDate,
            _that.removed);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            bool enabled,
            String? timeOfDay,
            String? endDate,
            int? endAgeMonths,
            String? label,
            String? frequency,
            int? intervalDays,
            String? frequencyDate,
            bool removed)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ReminderItemSetting() when $default != null:
        return $default(
            _that.enabled,
            _that.timeOfDay,
            _that.endDate,
            _that.endAgeMonths,
            _that.label,
            _that.frequency,
            _that.intervalDays,
            _that.frequencyDate,
            _that.removed);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _ReminderItemSetting implements ReminderItemSetting {
  const _ReminderItemSetting(
      {required this.enabled,
      this.timeOfDay,
      this.endDate,
      this.endAgeMonths,
      this.label,
      this.frequency,
      this.intervalDays,
      this.frequencyDate,
      this.removed = false});

  /// The switch. Once a row exists it means exactly what it says; absence is
  /// what `enabledByDefault` is for (B6).
  @override
  final bool enabled;

  /// Per-reminder notification hour, `'HH:mm'` (B30).
  ///
  /// `null` means **inherit the global hour**
  /// (`app_settings.notification_time_of_day`), not "has no hour". Read lax:
  /// a stored string that is not a valid `HH:mm` is treated as "inherit" by
  /// the scheduler rather than falling back to the app default — the global
  /// hour is the closer promise, and it is the one the parent can still see
  /// and fix. Written strict (`isValidNotificationTime` at the picker; the
  /// importer refuses the same value outright): the split documented in
  /// `notification_time.dart`.
  @override
  final String? timeOfDay;

  /// End of the series, `'yyyy-MM-dd'` (D-R5 form 2). `null` = no stored date.
  ///
  /// One of the two ways a reminder can end; **at most one** of
  /// [endDate]/[endAgeMonths] is ever set (D-R5's mutual exclusivity, enforced
  /// at write and at import — the schema only has the columns). Read it through
  /// `reminderEndFor`, never by parsing this field in place: the age form has
  /// to be resolved against the baby's birthdate, and a row that somehow holds
  /// both has to resolve to one answer.
  @override
  final String? endDate;

  /// End of the series as the baby's age in whole months, 0-180 (D-R5 form 3).
  ///
  /// Stored as *months*, never as the date it implies: a corrected birthdate
  /// then moves the end by itself, because the date is computed at read time
  /// (`reminderEndFor`) and there is no stored value to go stale.
  @override
  final int? endAgeMonths;

  /// Preset label override, the parent's wording (B33/D-R6). `null` = the
  /// preset's localized name. Never written for a custom reminder — its label
  /// lives in `custom_reminders.label`, and this row must not become a second
  /// source of truth for the same name.
  @override
  final String? label;

  /// Frequency override, a `db_constants` code (B33). `null` = the preset's own
  /// frequency, which is also how "back to the default rhythm" is written.
  ///
  /// [frequencyDate] is meaningful **only** when this is `one_time` — the
  /// resolution order D-R8 spells out, and the one that keeps Vitamin K at one
  /// month instead of at birth.
  @override
  final String? frequency;

  /// `interval_days` for a `frequency` of `every_n_days`.
  @override
  final int? intervalDays;

  /// `frequency_date` for a `frequency` of `one_time`: the occurrence day,
  /// `'yyyy-MM-dd'`.
  @override
  final String? frequencyDate;

  /// The third state (D-R2): hidden from the lists and from the schedule, but
  /// **not deleted** — a removed preset stays restorable (D-R4), and its
  /// [enabled] value is kept as stored, moot until a restore.
  @override
  @JsonKey()
  final bool removed;

  /// Create a copy of ReminderItemSetting
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ReminderItemSettingCopyWith<_ReminderItemSetting> get copyWith =>
      __$ReminderItemSettingCopyWithImpl<_ReminderItemSetting>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ReminderItemSetting &&
            (identical(other.enabled, enabled) || other.enabled == enabled) &&
            (identical(other.timeOfDay, timeOfDay) ||
                other.timeOfDay == timeOfDay) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(other.endAgeMonths, endAgeMonths) ||
                other.endAgeMonths == endAgeMonths) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.frequency, frequency) ||
                other.frequency == frequency) &&
            (identical(other.intervalDays, intervalDays) ||
                other.intervalDays == intervalDays) &&
            (identical(other.frequencyDate, frequencyDate) ||
                other.frequencyDate == frequencyDate) &&
            (identical(other.removed, removed) || other.removed == removed));
  }

  @override
  int get hashCode => Object.hash(runtimeType, enabled, timeOfDay, endDate,
      endAgeMonths, label, frequency, intervalDays, frequencyDate, removed);

  @override
  String toString() {
    return 'ReminderItemSetting(enabled: $enabled, timeOfDay: $timeOfDay, endDate: $endDate, endAgeMonths: $endAgeMonths, label: $label, frequency: $frequency, intervalDays: $intervalDays, frequencyDate: $frequencyDate, removed: $removed)';
  }
}

/// @nodoc
abstract mixin class _$ReminderItemSettingCopyWith<$Res>
    implements $ReminderItemSettingCopyWith<$Res> {
  factory _$ReminderItemSettingCopyWith(_ReminderItemSetting value,
          $Res Function(_ReminderItemSetting) _then) =
      __$ReminderItemSettingCopyWithImpl;
  @override
  @useResult
  $Res call(
      {bool enabled,
      String? timeOfDay,
      String? endDate,
      int? endAgeMonths,
      String? label,
      String? frequency,
      int? intervalDays,
      String? frequencyDate,
      bool removed});
}

/// @nodoc
class __$ReminderItemSettingCopyWithImpl<$Res>
    implements _$ReminderItemSettingCopyWith<$Res> {
  __$ReminderItemSettingCopyWithImpl(this._self, this._then);

  final _ReminderItemSetting _self;
  final $Res Function(_ReminderItemSetting) _then;

  /// Create a copy of ReminderItemSetting
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? enabled = null,
    Object? timeOfDay = freezed,
    Object? endDate = freezed,
    Object? endAgeMonths = freezed,
    Object? label = freezed,
    Object? frequency = freezed,
    Object? intervalDays = freezed,
    Object? frequencyDate = freezed,
    Object? removed = null,
  }) {
    return _then(_ReminderItemSetting(
      enabled: null == enabled
          ? _self.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      timeOfDay: freezed == timeOfDay
          ? _self.timeOfDay
          : timeOfDay // ignore: cast_nullable_to_non_nullable
              as String?,
      endDate: freezed == endDate
          ? _self.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as String?,
      endAgeMonths: freezed == endAgeMonths
          ? _self.endAgeMonths
          : endAgeMonths // ignore: cast_nullable_to_non_nullable
              as int?,
      label: freezed == label
          ? _self.label
          : label // ignore: cast_nullable_to_non_nullable
              as String?,
      frequency: freezed == frequency
          ? _self.frequency
          : frequency // ignore: cast_nullable_to_non_nullable
              as String?,
      intervalDays: freezed == intervalDays
          ? _self.intervalDays
          : intervalDays // ignore: cast_nullable_to_non_nullable
              as int?,
      frequencyDate: freezed == frequencyDate
          ? _self.frequencyDate
          : frequencyDate // ignore: cast_nullable_to_non_nullable
              as String?,
      removed: null == removed
          ? _self.removed
          : removed // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

// dart format on
