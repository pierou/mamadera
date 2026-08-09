// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reminder_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ReminderItem {
  String get id;
  String get labelKey;
  ReminderFrequency get frequency;
  TrackingType get trackingType;
  String? get subtypeValue;

  /// Create a copy of ReminderItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ReminderItemCopyWith<ReminderItem> get copyWith =>
      _$ReminderItemCopyWithImpl<ReminderItem>(
          this as ReminderItem, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ReminderItem &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.labelKey, labelKey) ||
                other.labelKey == labelKey) &&
            (identical(other.frequency, frequency) ||
                other.frequency == frequency) &&
            (identical(other.trackingType, trackingType) ||
                other.trackingType == trackingType) &&
            (identical(other.subtypeValue, subtypeValue) ||
                other.subtypeValue == subtypeValue));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, id, labelKey, frequency, trackingType, subtypeValue);

  @override
  String toString() {
    return 'ReminderItem(id: $id, labelKey: $labelKey, frequency: $frequency, trackingType: $trackingType, subtypeValue: $subtypeValue)';
  }
}

/// @nodoc
abstract mixin class $ReminderItemCopyWith<$Res> {
  factory $ReminderItemCopyWith(
          ReminderItem value, $Res Function(ReminderItem) _then) =
      _$ReminderItemCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String labelKey,
      ReminderFrequency frequency,
      TrackingType trackingType,
      String? subtypeValue});

  $ReminderFrequencyCopyWith<$Res> get frequency;
}

/// @nodoc
class _$ReminderItemCopyWithImpl<$Res> implements $ReminderItemCopyWith<$Res> {
  _$ReminderItemCopyWithImpl(this._self, this._then);

  final ReminderItem _self;
  final $Res Function(ReminderItem) _then;

  /// Create a copy of ReminderItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? labelKey = null,
    Object? frequency = null,
    Object? trackingType = null,
    Object? subtypeValue = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      labelKey: null == labelKey
          ? _self.labelKey
          : labelKey // ignore: cast_nullable_to_non_nullable
              as String,
      frequency: null == frequency
          ? _self.frequency
          : frequency // ignore: cast_nullable_to_non_nullable
              as ReminderFrequency,
      trackingType: null == trackingType
          ? _self.trackingType
          : trackingType // ignore: cast_nullable_to_non_nullable
              as TrackingType,
      subtypeValue: freezed == subtypeValue
          ? _self.subtypeValue
          : subtypeValue // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }

  /// Create a copy of ReminderItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ReminderFrequencyCopyWith<$Res> get frequency {
    return $ReminderFrequencyCopyWith<$Res>(_self.frequency, (value) {
      return _then(_self.copyWith(frequency: value));
    });
  }
}

/// Adds pattern-matching-related methods to [ReminderItem].
extension ReminderItemPatterns on ReminderItem {
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
    TResult Function(_ReminderItem value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ReminderItem() when $default != null:
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
    TResult Function(_ReminderItem value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ReminderItem():
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
    TResult? Function(_ReminderItem value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ReminderItem() when $default != null:
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
    TResult Function(String id, String labelKey, ReminderFrequency frequency,
            TrackingType trackingType, String? subtypeValue)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ReminderItem() when $default != null:
        return $default(_that.id, _that.labelKey, _that.frequency,
            _that.trackingType, _that.subtypeValue);
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
    TResult Function(String id, String labelKey, ReminderFrequency frequency,
            TrackingType trackingType, String? subtypeValue)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ReminderItem():
        return $default(_that.id, _that.labelKey, _that.frequency,
            _that.trackingType, _that.subtypeValue);
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
    TResult? Function(String id, String labelKey, ReminderFrequency frequency,
            TrackingType trackingType, String? subtypeValue)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ReminderItem() when $default != null:
        return $default(_that.id, _that.labelKey, _that.frequency,
            _that.trackingType, _that.subtypeValue);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _ReminderItem implements ReminderItem {
  const _ReminderItem(
      {required this.id,
      required this.labelKey,
      required this.frequency,
      required this.trackingType,
      this.subtypeValue});

  @override
  final String id;
  @override
  final String labelKey;
  @override
  final ReminderFrequency frequency;
  @override
  final TrackingType trackingType;
  @override
  final String? subtypeValue;

  /// Create a copy of ReminderItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ReminderItemCopyWith<_ReminderItem> get copyWith =>
      __$ReminderItemCopyWithImpl<_ReminderItem>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ReminderItem &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.labelKey, labelKey) ||
                other.labelKey == labelKey) &&
            (identical(other.frequency, frequency) ||
                other.frequency == frequency) &&
            (identical(other.trackingType, trackingType) ||
                other.trackingType == trackingType) &&
            (identical(other.subtypeValue, subtypeValue) ||
                other.subtypeValue == subtypeValue));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, id, labelKey, frequency, trackingType, subtypeValue);

  @override
  String toString() {
    return 'ReminderItem(id: $id, labelKey: $labelKey, frequency: $frequency, trackingType: $trackingType, subtypeValue: $subtypeValue)';
  }
}

/// @nodoc
abstract mixin class _$ReminderItemCopyWith<$Res>
    implements $ReminderItemCopyWith<$Res> {
  factory _$ReminderItemCopyWith(
          _ReminderItem value, $Res Function(_ReminderItem) _then) =
      __$ReminderItemCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String labelKey,
      ReminderFrequency frequency,
      TrackingType trackingType,
      String? subtypeValue});

  @override
  $ReminderFrequencyCopyWith<$Res> get frequency;
}

/// @nodoc
class __$ReminderItemCopyWithImpl<$Res>
    implements _$ReminderItemCopyWith<$Res> {
  __$ReminderItemCopyWithImpl(this._self, this._then);

  final _ReminderItem _self;
  final $Res Function(_ReminderItem) _then;

  /// Create a copy of ReminderItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? labelKey = null,
    Object? frequency = null,
    Object? trackingType = null,
    Object? subtypeValue = freezed,
  }) {
    return _then(_ReminderItem(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      labelKey: null == labelKey
          ? _self.labelKey
          : labelKey // ignore: cast_nullable_to_non_nullable
              as String,
      frequency: null == frequency
          ? _self.frequency
          : frequency // ignore: cast_nullable_to_non_nullable
              as ReminderFrequency,
      trackingType: null == trackingType
          ? _self.trackingType
          : trackingType // ignore: cast_nullable_to_non_nullable
              as TrackingType,
      subtypeValue: freezed == subtypeValue
          ? _self.subtypeValue
          : subtypeValue // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }

  /// Create a copy of ReminderItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ReminderFrequencyCopyWith<$Res> get frequency {
    return $ReminderFrequencyCopyWith<$Res>(_self.frequency, (value) {
      return _then(_self.copyWith(frequency: value));
    });
  }
}

// dart format on
