// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'growth_measurement.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GrowthMeasurement {
  int get id;
  MeasureKind get kind;
  String get unit;
  DateTime get recordedAt;
  String? get babyId;
  double? get value;
  String? get notes;

  /// Create a copy of GrowthMeasurement
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $GrowthMeasurementCopyWith<GrowthMeasurement> get copyWith =>
      _$GrowthMeasurementCopyWithImpl<GrowthMeasurement>(
          this as GrowthMeasurement, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is GrowthMeasurement &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            (identical(other.recordedAt, recordedAt) ||
                other.recordedAt == recordedAt) &&
            (identical(other.babyId, babyId) || other.babyId == babyId) &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, id, kind, unit, recordedAt, babyId, value, notes);

  @override
  String toString() {
    return 'GrowthMeasurement(id: $id, kind: $kind, unit: $unit, recordedAt: $recordedAt, babyId: $babyId, value: $value, notes: $notes)';
  }
}

/// @nodoc
abstract mixin class $GrowthMeasurementCopyWith<$Res> {
  factory $GrowthMeasurementCopyWith(
          GrowthMeasurement value, $Res Function(GrowthMeasurement) _then) =
      _$GrowthMeasurementCopyWithImpl;
  @useResult
  $Res call(
      {int id,
      MeasureKind kind,
      String unit,
      DateTime recordedAt,
      String? babyId,
      double? value,
      String? notes});
}

/// @nodoc
class _$GrowthMeasurementCopyWithImpl<$Res>
    implements $GrowthMeasurementCopyWith<$Res> {
  _$GrowthMeasurementCopyWithImpl(this._self, this._then);

  final GrowthMeasurement _self;
  final $Res Function(GrowthMeasurement) _then;

  /// Create a copy of GrowthMeasurement
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? kind = null,
    Object? unit = null,
    Object? recordedAt = null,
    Object? babyId = freezed,
    Object? value = freezed,
    Object? notes = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      kind: null == kind
          ? _self.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as MeasureKind,
      unit: null == unit
          ? _self.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String,
      recordedAt: null == recordedAt
          ? _self.recordedAt
          : recordedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      babyId: freezed == babyId
          ? _self.babyId
          : babyId // ignore: cast_nullable_to_non_nullable
              as String?,
      value: freezed == value
          ? _self.value
          : value // ignore: cast_nullable_to_non_nullable
              as double?,
      notes: freezed == notes
          ? _self.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [GrowthMeasurement].
extension GrowthMeasurementPatterns on GrowthMeasurement {
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
    TResult Function(_GrowthMeasurement value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _GrowthMeasurement() when $default != null:
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
    TResult Function(_GrowthMeasurement value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GrowthMeasurement():
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
    TResult? Function(_GrowthMeasurement value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GrowthMeasurement() when $default != null:
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
    TResult Function(int id, MeasureKind kind, String unit, DateTime recordedAt,
            String? babyId, double? value, String? notes)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _GrowthMeasurement() when $default != null:
        return $default(_that.id, _that.kind, _that.unit, _that.recordedAt,
            _that.babyId, _that.value, _that.notes);
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
    TResult Function(int id, MeasureKind kind, String unit, DateTime recordedAt,
            String? babyId, double? value, String? notes)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GrowthMeasurement():
        return $default(_that.id, _that.kind, _that.unit, _that.recordedAt,
            _that.babyId, _that.value, _that.notes);
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
    TResult? Function(int id, MeasureKind kind, String unit,
            DateTime recordedAt, String? babyId, double? value, String? notes)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GrowthMeasurement() when $default != null:
        return $default(_that.id, _that.kind, _that.unit, _that.recordedAt,
            _that.babyId, _that.value, _that.notes);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _GrowthMeasurement implements GrowthMeasurement {
  const _GrowthMeasurement(
      {required this.id,
      required this.kind,
      required this.unit,
      required this.recordedAt,
      this.babyId,
      this.value,
      this.notes});

  @override
  final int id;
  @override
  final MeasureKind kind;
  @override
  final String unit;
  @override
  final DateTime recordedAt;
  @override
  final String? babyId;
  @override
  final double? value;
  @override
  final String? notes;

  /// Create a copy of GrowthMeasurement
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$GrowthMeasurementCopyWith<_GrowthMeasurement> get copyWith =>
      __$GrowthMeasurementCopyWithImpl<_GrowthMeasurement>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _GrowthMeasurement &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            (identical(other.recordedAt, recordedAt) ||
                other.recordedAt == recordedAt) &&
            (identical(other.babyId, babyId) || other.babyId == babyId) &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, id, kind, unit, recordedAt, babyId, value, notes);

  @override
  String toString() {
    return 'GrowthMeasurement(id: $id, kind: $kind, unit: $unit, recordedAt: $recordedAt, babyId: $babyId, value: $value, notes: $notes)';
  }
}

/// @nodoc
abstract mixin class _$GrowthMeasurementCopyWith<$Res>
    implements $GrowthMeasurementCopyWith<$Res> {
  factory _$GrowthMeasurementCopyWith(
          _GrowthMeasurement value, $Res Function(_GrowthMeasurement) _then) =
      __$GrowthMeasurementCopyWithImpl;
  @override
  @useResult
  $Res call(
      {int id,
      MeasureKind kind,
      String unit,
      DateTime recordedAt,
      String? babyId,
      double? value,
      String? notes});
}

/// @nodoc
class __$GrowthMeasurementCopyWithImpl<$Res>
    implements _$GrowthMeasurementCopyWith<$Res> {
  __$GrowthMeasurementCopyWithImpl(this._self, this._then);

  final _GrowthMeasurement _self;
  final $Res Function(_GrowthMeasurement) _then;

  /// Create a copy of GrowthMeasurement
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? kind = null,
    Object? unit = null,
    Object? recordedAt = null,
    Object? babyId = freezed,
    Object? value = freezed,
    Object? notes = freezed,
  }) {
    return _then(_GrowthMeasurement(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      kind: null == kind
          ? _self.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as MeasureKind,
      unit: null == unit
          ? _self.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String,
      recordedAt: null == recordedAt
          ? _self.recordedAt
          : recordedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      babyId: freezed == babyId
          ? _self.babyId
          : babyId // ignore: cast_nullable_to_non_nullable
              as String?,
      value: freezed == value
          ? _self.value
          : value // ignore: cast_nullable_to_non_nullable
              as double?,
      notes: freezed == notes
          ? _self.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
