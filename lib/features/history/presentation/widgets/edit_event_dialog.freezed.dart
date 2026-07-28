// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'edit_event_dialog.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EditResult {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is EditResult);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'EditResult()';
  }
}

/// @nodoc
class $EditResultCopyWith<$Res> {
  $EditResultCopyWith(EditResult _, $Res Function(EditResult) __);
}

/// Adds pattern-matching-related methods to [EditResult].
extension EditResultPatterns on EditResult {
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
    TResult Function(UpdateResult value)? update,
    TResult Function(DeleteResult value)? delete,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case UpdateResult() when update != null:
        return update(_that);
      case DeleteResult() when delete != null:
        return delete(_that);
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
    required TResult Function(UpdateResult value) update,
    required TResult Function(DeleteResult value) delete,
  }) {
    final _that = this;
    switch (_that) {
      case UpdateResult():
        return update(_that);
      case DeleteResult():
        return delete(_that);
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
    TResult? Function(UpdateResult value)? update,
    TResult? Function(DeleteResult value)? delete,
  }) {
    final _that = this;
    switch (_that) {
      case UpdateResult() when update != null:
        return update(_that);
      case DeleteResult() when delete != null:
        return delete(_that);
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
    TResult Function(
            DateTime? timestamp,
            double? duration,
            double? quantity,
            String? notes,
            FeedingSubtype? subtype,
            WasteType? wasteType,
            PipiColor? pipiColor,
            CacaColor? cacaColor)?
        update,
    TResult Function()? delete,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case UpdateResult() when update != null:
        return update(
            _that.timestamp,
            _that.duration,
            _that.quantity,
            _that.notes,
            _that.subtype,
            _that.wasteType,
            _that.pipiColor,
            _that.cacaColor);
      case DeleteResult() when delete != null:
        return delete();
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
    required TResult Function(
            DateTime? timestamp,
            double? duration,
            double? quantity,
            String? notes,
            FeedingSubtype? subtype,
            WasteType? wasteType,
            PipiColor? pipiColor,
            CacaColor? cacaColor)
        update,
    required TResult Function() delete,
  }) {
    final _that = this;
    switch (_that) {
      case UpdateResult():
        return update(
            _that.timestamp,
            _that.duration,
            _that.quantity,
            _that.notes,
            _that.subtype,
            _that.wasteType,
            _that.pipiColor,
            _that.cacaColor);
      case DeleteResult():
        return delete();
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
    TResult? Function(
            DateTime? timestamp,
            double? duration,
            double? quantity,
            String? notes,
            FeedingSubtype? subtype,
            WasteType? wasteType,
            PipiColor? pipiColor,
            CacaColor? cacaColor)?
        update,
    TResult? Function()? delete,
  }) {
    final _that = this;
    switch (_that) {
      case UpdateResult() when update != null:
        return update(
            _that.timestamp,
            _that.duration,
            _that.quantity,
            _that.notes,
            _that.subtype,
            _that.wasteType,
            _that.pipiColor,
            _that.cacaColor);
      case DeleteResult() when delete != null:
        return delete();
      case _:
        return null;
    }
  }
}

/// @nodoc

class UpdateResult implements EditResult {
  const UpdateResult(
      {this.timestamp,
      this.duration,
      this.quantity,
      this.notes,
      this.subtype,
      this.wasteType,
      this.pipiColor,
      this.cacaColor});

  final DateTime? timestamp;
  final double? duration;
  final double? quantity;
  final String? notes;
  final FeedingSubtype? subtype;
  final WasteType? wasteType;
  final PipiColor? pipiColor;
  final CacaColor? cacaColor;

  /// Create a copy of EditResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $UpdateResultCopyWith<UpdateResult> get copyWith =>
      _$UpdateResultCopyWithImpl<UpdateResult>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is UpdateResult &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.subtype, subtype) || other.subtype == subtype) &&
            (identical(other.wasteType, wasteType) ||
                other.wasteType == wasteType) &&
            (identical(other.pipiColor, pipiColor) ||
                other.pipiColor == pipiColor) &&
            (identical(other.cacaColor, cacaColor) ||
                other.cacaColor == cacaColor));
  }

  @override
  int get hashCode => Object.hash(runtimeType, timestamp, duration, quantity,
      notes, subtype, wasteType, pipiColor, cacaColor);

  @override
  String toString() {
    return 'EditResult.update(timestamp: $timestamp, duration: $duration, quantity: $quantity, notes: $notes, subtype: $subtype, wasteType: $wasteType, pipiColor: $pipiColor, cacaColor: $cacaColor)';
  }
}

/// @nodoc
abstract mixin class $UpdateResultCopyWith<$Res>
    implements $EditResultCopyWith<$Res> {
  factory $UpdateResultCopyWith(
          UpdateResult value, $Res Function(UpdateResult) _then) =
      _$UpdateResultCopyWithImpl;
  @useResult
  $Res call(
      {DateTime? timestamp,
      double? duration,
      double? quantity,
      String? notes,
      FeedingSubtype? subtype,
      WasteType? wasteType,
      PipiColor? pipiColor,
      CacaColor? cacaColor});

  $PipiColorCopyWith<$Res>? get pipiColor;
  $CacaColorCopyWith<$Res>? get cacaColor;
}

/// @nodoc
class _$UpdateResultCopyWithImpl<$Res> implements $UpdateResultCopyWith<$Res> {
  _$UpdateResultCopyWithImpl(this._self, this._then);

  final UpdateResult _self;
  final $Res Function(UpdateResult) _then;

  /// Create a copy of EditResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? timestamp = freezed,
    Object? duration = freezed,
    Object? quantity = freezed,
    Object? notes = freezed,
    Object? subtype = freezed,
    Object? wasteType = freezed,
    Object? pipiColor = freezed,
    Object? cacaColor = freezed,
  }) {
    return _then(UpdateResult(
      timestamp: freezed == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      duration: freezed == duration
          ? _self.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as double?,
      quantity: freezed == quantity
          ? _self.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as double?,
      notes: freezed == notes
          ? _self.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      subtype: freezed == subtype
          ? _self.subtype
          : subtype // ignore: cast_nullable_to_non_nullable
              as FeedingSubtype?,
      wasteType: freezed == wasteType
          ? _self.wasteType
          : wasteType // ignore: cast_nullable_to_non_nullable
              as WasteType?,
      pipiColor: freezed == pipiColor
          ? _self.pipiColor
          : pipiColor // ignore: cast_nullable_to_non_nullable
              as PipiColor?,
      cacaColor: freezed == cacaColor
          ? _self.cacaColor
          : cacaColor // ignore: cast_nullable_to_non_nullable
              as CacaColor?,
    ));
  }

  /// Create a copy of EditResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PipiColorCopyWith<$Res>? get pipiColor {
    if (_self.pipiColor == null) {
      return null;
    }

    return $PipiColorCopyWith<$Res>(_self.pipiColor!, (value) {
      return _then(_self.copyWith(pipiColor: value));
    });
  }

  /// Create a copy of EditResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CacaColorCopyWith<$Res>? get cacaColor {
    if (_self.cacaColor == null) {
      return null;
    }

    return $CacaColorCopyWith<$Res>(_self.cacaColor!, (value) {
      return _then(_self.copyWith(cacaColor: value));
    });
  }
}

/// @nodoc

class DeleteResult implements EditResult {
  const DeleteResult();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is DeleteResult);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'EditResult.delete()';
  }
}

// dart format on
