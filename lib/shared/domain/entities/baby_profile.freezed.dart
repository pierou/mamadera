// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'baby_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BabyProfile {
  String get id;
  String get name;
  DateTime get birthDate;
  bool get isActive;

  /// Create a copy of BabyProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BabyProfileCopyWith<BabyProfile> get copyWith =>
      _$BabyProfileCopyWithImpl<BabyProfile>(this as BabyProfile, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BabyProfile &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.birthDate, birthDate) ||
                other.birthDate == birthDate) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, name, birthDate, isActive);

  @override
  String toString() {
    return 'BabyProfile(id: $id, name: $name, birthDate: $birthDate, isActive: $isActive)';
  }
}

/// @nodoc
abstract mixin class $BabyProfileCopyWith<$Res> {
  factory $BabyProfileCopyWith(
          BabyProfile value, $Res Function(BabyProfile) _then) =
      _$BabyProfileCopyWithImpl;
  @useResult
  $Res call({String id, String name, DateTime birthDate, bool isActive});
}

/// @nodoc
class _$BabyProfileCopyWithImpl<$Res> implements $BabyProfileCopyWith<$Res> {
  _$BabyProfileCopyWithImpl(this._self, this._then);

  final BabyProfile _self;
  final $Res Function(BabyProfile) _then;

  /// Create a copy of BabyProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? birthDate = null,
    Object? isActive = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      birthDate: null == birthDate
          ? _self.birthDate
          : birthDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isActive: null == isActive
          ? _self.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// Adds pattern-matching-related methods to [BabyProfile].
extension BabyProfilePatterns on BabyProfile {
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
    TResult Function(_BabyProfile value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _BabyProfile() when $default != null:
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
    TResult Function(_BabyProfile value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BabyProfile():
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
    TResult? Function(_BabyProfile value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BabyProfile() when $default != null:
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
    TResult Function(String id, String name, DateTime birthDate, bool isActive)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _BabyProfile() when $default != null:
        return $default(_that.id, _that.name, _that.birthDate, _that.isActive);
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
    TResult Function(String id, String name, DateTime birthDate, bool isActive)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BabyProfile():
        return $default(_that.id, _that.name, _that.birthDate, _that.isActive);
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
            String id, String name, DateTime birthDate, bool isActive)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BabyProfile() when $default != null:
        return $default(_that.id, _that.name, _that.birthDate, _that.isActive);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _BabyProfile implements BabyProfile {
  const _BabyProfile(
      {required this.id,
      required this.name,
      required this.birthDate,
      this.isActive = true});

  @override
  final String id;
  @override
  final String name;
  @override
  final DateTime birthDate;
  @override
  @JsonKey()
  final bool isActive;

  /// Create a copy of BabyProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$BabyProfileCopyWith<_BabyProfile> get copyWith =>
      __$BabyProfileCopyWithImpl<_BabyProfile>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _BabyProfile &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.birthDate, birthDate) ||
                other.birthDate == birthDate) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, name, birthDate, isActive);

  @override
  String toString() {
    return 'BabyProfile(id: $id, name: $name, birthDate: $birthDate, isActive: $isActive)';
  }
}

/// @nodoc
abstract mixin class _$BabyProfileCopyWith<$Res>
    implements $BabyProfileCopyWith<$Res> {
  factory _$BabyProfileCopyWith(
          _BabyProfile value, $Res Function(_BabyProfile) _then) =
      __$BabyProfileCopyWithImpl;
  @override
  @useResult
  $Res call({String id, String name, DateTime birthDate, bool isActive});
}

/// @nodoc
class __$BabyProfileCopyWithImpl<$Res> implements _$BabyProfileCopyWith<$Res> {
  __$BabyProfileCopyWithImpl(this._self, this._then);

  final _BabyProfile _self;
  final $Res Function(_BabyProfile) _then;

  /// Create a copy of BabyProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? birthDate = null,
    Object? isActive = null,
  }) {
    return _then(_BabyProfile(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      birthDate: null == birthDate
          ? _self.birthDate
          : birthDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isActive: null == isActive
          ? _self.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

// dart format on
