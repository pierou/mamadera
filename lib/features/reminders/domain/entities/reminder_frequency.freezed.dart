// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reminder_frequency.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ReminderFrequency {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is ReminderFrequency);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'ReminderFrequency()';
  }
}

/// @nodoc
class $ReminderFrequencyCopyWith<$Res> {
  $ReminderFrequencyCopyWith(
      ReminderFrequency _, $Res Function(ReminderFrequency) __);
}

/// Adds pattern-matching-related methods to [ReminderFrequency].
extension ReminderFrequencyPatterns on ReminderFrequency {
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
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Daily value)? daily,
    TResult Function(Weekly value)? weekly,
    TResult Function(Monthly value)? monthly,
    TResult Function(CustomInterval value)? customInterval,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case Daily() when daily != null:
        return daily(_that);
      case Weekly() when weekly != null:
        return weekly(_that);
      case Monthly() when monthly != null:
        return monthly(_that);
      case CustomInterval() when customInterval != null:
        return customInterval(_that);
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
  TResult map<TResult extends Object?>({
    required TResult Function(Daily value) daily,
    required TResult Function(Weekly value) weekly,
    required TResult Function(Monthly value) monthly,
    required TResult Function(CustomInterval value) customInterval,
  }) {
    final _that = this;
    switch (_that) {
      case Daily():
        return daily(_that);
      case Weekly():
        return weekly(_that);
      case Monthly():
        return monthly(_that);
      case CustomInterval():
        return customInterval(_that);
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
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Daily value)? daily,
    TResult? Function(Weekly value)? weekly,
    TResult? Function(Monthly value)? monthly,
    TResult? Function(CustomInterval value)? customInterval,
  }) {
    final _that = this;
    switch (_that) {
      case Daily() when daily != null:
        return daily(_that);
      case Weekly() when weekly != null:
        return weekly(_that);
      case Monthly() when monthly != null:
        return monthly(_that);
      case CustomInterval() when customInterval != null:
        return customInterval(_that);
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
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? daily,
    TResult Function(int dayOfWeek)? weekly,
    TResult Function(int dayOfMonth)? monthly,
    TResult Function(int days)? customInterval,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case Daily() when daily != null:
        return daily();
      case Weekly() when weekly != null:
        return weekly(_that.dayOfWeek);
      case Monthly() when monthly != null:
        return monthly(_that.dayOfMonth);
      case CustomInterval() when customInterval != null:
        return customInterval(_that.days);
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
  TResult when<TResult extends Object?>({
    required TResult Function() daily,
    required TResult Function(int dayOfWeek) weekly,
    required TResult Function(int dayOfMonth) monthly,
    required TResult Function(int days) customInterval,
  }) {
    final _that = this;
    switch (_that) {
      case Daily():
        return daily();
      case Weekly():
        return weekly(_that.dayOfWeek);
      case Monthly():
        return monthly(_that.dayOfMonth);
      case CustomInterval():
        return customInterval(_that.days);
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
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? daily,
    TResult? Function(int dayOfWeek)? weekly,
    TResult? Function(int dayOfMonth)? monthly,
    TResult? Function(int days)? customInterval,
  }) {
    final _that = this;
    switch (_that) {
      case Daily() when daily != null:
        return daily();
      case Weekly() when weekly != null:
        return weekly(_that.dayOfWeek);
      case Monthly() when monthly != null:
        return monthly(_that.dayOfMonth);
      case CustomInterval() when customInterval != null:
        return customInterval(_that.days);
      case _:
        return null;
    }
  }
}

/// @nodoc

class Daily implements ReminderFrequency {
  const Daily();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is Daily);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'ReminderFrequency.daily()';
  }
}

/// @nodoc

class Weekly implements ReminderFrequency {
  const Weekly({required this.dayOfWeek});

  final int dayOfWeek;

  /// Create a copy of ReminderFrequency
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $WeeklyCopyWith<Weekly> get copyWith =>
      _$WeeklyCopyWithImpl<Weekly>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Weekly &&
            (identical(other.dayOfWeek, dayOfWeek) ||
                other.dayOfWeek == dayOfWeek));
  }

  @override
  int get hashCode => Object.hash(runtimeType, dayOfWeek);

  @override
  String toString() {
    return 'ReminderFrequency.weekly(dayOfWeek: $dayOfWeek)';
  }
}

/// @nodoc
abstract mixin class $WeeklyCopyWith<$Res>
    implements $ReminderFrequencyCopyWith<$Res> {
  factory $WeeklyCopyWith(Weekly value, $Res Function(Weekly) _then) =
      _$WeeklyCopyWithImpl;
  @useResult
  $Res call({int dayOfWeek});
}

/// @nodoc
class _$WeeklyCopyWithImpl<$Res> implements $WeeklyCopyWith<$Res> {
  _$WeeklyCopyWithImpl(this._self, this._then);

  final Weekly _self;
  final $Res Function(Weekly) _then;

  /// Create a copy of ReminderFrequency
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? dayOfWeek = null,
  }) {
    return _then(Weekly(
      dayOfWeek: null == dayOfWeek
          ? _self.dayOfWeek
          : dayOfWeek // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class Monthly implements ReminderFrequency {
  const Monthly({required this.dayOfMonth});

  final int dayOfMonth;

  /// Create a copy of ReminderFrequency
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $MonthlyCopyWith<Monthly> get copyWith =>
      _$MonthlyCopyWithImpl<Monthly>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Monthly &&
            (identical(other.dayOfMonth, dayOfMonth) ||
                other.dayOfMonth == dayOfMonth));
  }

  @override
  int get hashCode => Object.hash(runtimeType, dayOfMonth);

  @override
  String toString() {
    return 'ReminderFrequency.monthly(dayOfMonth: $dayOfMonth)';
  }
}

/// @nodoc
abstract mixin class $MonthlyCopyWith<$Res>
    implements $ReminderFrequencyCopyWith<$Res> {
  factory $MonthlyCopyWith(Monthly value, $Res Function(Monthly) _then) =
      _$MonthlyCopyWithImpl;
  @useResult
  $Res call({int dayOfMonth});
}

/// @nodoc
class _$MonthlyCopyWithImpl<$Res> implements $MonthlyCopyWith<$Res> {
  _$MonthlyCopyWithImpl(this._self, this._then);

  final Monthly _self;
  final $Res Function(Monthly) _then;

  /// Create a copy of ReminderFrequency
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? dayOfMonth = null,
  }) {
    return _then(Monthly(
      dayOfMonth: null == dayOfMonth
          ? _self.dayOfMonth
          : dayOfMonth // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class CustomInterval implements ReminderFrequency {
  const CustomInterval({this.days = 7});

  @JsonKey()
  final int days;

  /// Create a copy of ReminderFrequency
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CustomIntervalCopyWith<CustomInterval> get copyWith =>
      _$CustomIntervalCopyWithImpl<CustomInterval>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CustomInterval &&
            (identical(other.days, days) || other.days == days));
  }

  @override
  int get hashCode => Object.hash(runtimeType, days);

  @override
  String toString() {
    return 'ReminderFrequency.customInterval(days: $days)';
  }
}

/// @nodoc
abstract mixin class $CustomIntervalCopyWith<$Res>
    implements $ReminderFrequencyCopyWith<$Res> {
  factory $CustomIntervalCopyWith(
          CustomInterval value, $Res Function(CustomInterval) _then) =
      _$CustomIntervalCopyWithImpl;
  @useResult
  $Res call({int days});
}

/// @nodoc
class _$CustomIntervalCopyWithImpl<$Res>
    implements $CustomIntervalCopyWith<$Res> {
  _$CustomIntervalCopyWithImpl(this._self, this._then);

  final CustomInterval _self;
  final $Res Function(CustomInterval) _then;

  /// Create a copy of ReminderFrequency
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? days = null,
  }) {
    return _then(CustomInterval(
      days: null == days
          ? _self.days
          : days // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

// dart format on
