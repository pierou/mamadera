// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tracking_enums.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PipiColor {
  String get value;
  String get label;
  int get colorHex;
  String get labelKey;

  /// Create a copy of PipiColor
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PipiColorCopyWith<PipiColor> get copyWith =>
      _$PipiColorCopyWithImpl<PipiColor>(this as PipiColor, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PipiColor &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.colorHex, colorHex) ||
                other.colorHex == colorHex) &&
            (identical(other.labelKey, labelKey) ||
                other.labelKey == labelKey));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, value, label, colorHex, labelKey);

  @override
  String toString() {
    return 'PipiColor(value: $value, label: $label, colorHex: $colorHex, labelKey: $labelKey)';
  }
}

/// @nodoc
abstract mixin class $PipiColorCopyWith<$Res> {
  factory $PipiColorCopyWith(PipiColor value, $Res Function(PipiColor) _then) =
      _$PipiColorCopyWithImpl;
  @useResult
  $Res call({String value, String label, int colorHex, String labelKey});
}

/// @nodoc
class _$PipiColorCopyWithImpl<$Res> implements $PipiColorCopyWith<$Res> {
  _$PipiColorCopyWithImpl(this._self, this._then);

  final PipiColor _self;
  final $Res Function(PipiColor) _then;

  /// Create a copy of PipiColor
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? value = null,
    Object? label = null,
    Object? colorHex = null,
    Object? labelKey = null,
  }) {
    return _then(_self.copyWith(
      value: null == value
          ? _self.value
          : value // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _self.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      colorHex: null == colorHex
          ? _self.colorHex
          : colorHex // ignore: cast_nullable_to_non_nullable
              as int,
      labelKey: null == labelKey
          ? _self.labelKey
          : labelKey // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// Adds pattern-matching-related methods to [PipiColor].
extension PipiColorPatterns on PipiColor {
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
    TResult Function(_PipiColor value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PipiColor() when $default != null:
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
    TResult Function(_PipiColor value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PipiColor():
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
    TResult? Function(_PipiColor value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PipiColor() when $default != null:
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
    TResult Function(String value, String label, int colorHex, String labelKey)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PipiColor() when $default != null:
        return $default(
            _that.value, _that.label, _that.colorHex, _that.labelKey);
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
    TResult Function(String value, String label, int colorHex, String labelKey)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PipiColor():
        return $default(
            _that.value, _that.label, _that.colorHex, _that.labelKey);
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
            String value, String label, int colorHex, String labelKey)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PipiColor() when $default != null:
        return $default(
            _that.value, _that.label, _that.colorHex, _that.labelKey);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _PipiColor implements PipiColor {
  const _PipiColor(
      {required this.value,
      required this.label,
      required this.colorHex,
      required this.labelKey});

  @override
  final String value;
  @override
  final String label;
  @override
  final int colorHex;
  @override
  final String labelKey;

  /// Create a copy of PipiColor
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PipiColorCopyWith<_PipiColor> get copyWith =>
      __$PipiColorCopyWithImpl<_PipiColor>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PipiColor &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.colorHex, colorHex) ||
                other.colorHex == colorHex) &&
            (identical(other.labelKey, labelKey) ||
                other.labelKey == labelKey));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, value, label, colorHex, labelKey);

  @override
  String toString() {
    return 'PipiColor(value: $value, label: $label, colorHex: $colorHex, labelKey: $labelKey)';
  }
}

/// @nodoc
abstract mixin class _$PipiColorCopyWith<$Res>
    implements $PipiColorCopyWith<$Res> {
  factory _$PipiColorCopyWith(
          _PipiColor value, $Res Function(_PipiColor) _then) =
      __$PipiColorCopyWithImpl;
  @override
  @useResult
  $Res call({String value, String label, int colorHex, String labelKey});
}

/// @nodoc
class __$PipiColorCopyWithImpl<$Res> implements _$PipiColorCopyWith<$Res> {
  __$PipiColorCopyWithImpl(this._self, this._then);

  final _PipiColor _self;
  final $Res Function(_PipiColor) _then;

  /// Create a copy of PipiColor
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? value = null,
    Object? label = null,
    Object? colorHex = null,
    Object? labelKey = null,
  }) {
    return _then(_PipiColor(
      value: null == value
          ? _self.value
          : value // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _self.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      colorHex: null == colorHex
          ? _self.colorHex
          : colorHex // ignore: cast_nullable_to_non_nullable
              as int,
      labelKey: null == labelKey
          ? _self.labelKey
          : labelKey // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
mixin _$CacaColor {
  String get value;
  String get label;
  int get colorHex;
  String get labelKey;

  /// Create a copy of CacaColor
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CacaColorCopyWith<CacaColor> get copyWith =>
      _$CacaColorCopyWithImpl<CacaColor>(this as CacaColor, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CacaColor &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.colorHex, colorHex) ||
                other.colorHex == colorHex) &&
            (identical(other.labelKey, labelKey) ||
                other.labelKey == labelKey));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, value, label, colorHex, labelKey);

  @override
  String toString() {
    return 'CacaColor(value: $value, label: $label, colorHex: $colorHex, labelKey: $labelKey)';
  }
}

/// @nodoc
abstract mixin class $CacaColorCopyWith<$Res> {
  factory $CacaColorCopyWith(CacaColor value, $Res Function(CacaColor) _then) =
      _$CacaColorCopyWithImpl;
  @useResult
  $Res call({String value, String label, int colorHex, String labelKey});
}

/// @nodoc
class _$CacaColorCopyWithImpl<$Res> implements $CacaColorCopyWith<$Res> {
  _$CacaColorCopyWithImpl(this._self, this._then);

  final CacaColor _self;
  final $Res Function(CacaColor) _then;

  /// Create a copy of CacaColor
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? value = null,
    Object? label = null,
    Object? colorHex = null,
    Object? labelKey = null,
  }) {
    return _then(_self.copyWith(
      value: null == value
          ? _self.value
          : value // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _self.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      colorHex: null == colorHex
          ? _self.colorHex
          : colorHex // ignore: cast_nullable_to_non_nullable
              as int,
      labelKey: null == labelKey
          ? _self.labelKey
          : labelKey // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// Adds pattern-matching-related methods to [CacaColor].
extension CacaColorPatterns on CacaColor {
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
    TResult Function(_CacaColor value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CacaColor() when $default != null:
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
    TResult Function(_CacaColor value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CacaColor():
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
    TResult? Function(_CacaColor value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CacaColor() when $default != null:
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
    TResult Function(String value, String label, int colorHex, String labelKey)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CacaColor() when $default != null:
        return $default(
            _that.value, _that.label, _that.colorHex, _that.labelKey);
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
    TResult Function(String value, String label, int colorHex, String labelKey)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CacaColor():
        return $default(
            _that.value, _that.label, _that.colorHex, _that.labelKey);
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
            String value, String label, int colorHex, String labelKey)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CacaColor() when $default != null:
        return $default(
            _that.value, _that.label, _that.colorHex, _that.labelKey);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _CacaColor implements CacaColor {
  const _CacaColor(
      {required this.value,
      required this.label,
      required this.colorHex,
      required this.labelKey});

  @override
  final String value;
  @override
  final String label;
  @override
  final int colorHex;
  @override
  final String labelKey;

  /// Create a copy of CacaColor
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$CacaColorCopyWith<_CacaColor> get copyWith =>
      __$CacaColorCopyWithImpl<_CacaColor>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _CacaColor &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.colorHex, colorHex) ||
                other.colorHex == colorHex) &&
            (identical(other.labelKey, labelKey) ||
                other.labelKey == labelKey));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, value, label, colorHex, labelKey);

  @override
  String toString() {
    return 'CacaColor(value: $value, label: $label, colorHex: $colorHex, labelKey: $labelKey)';
  }
}

/// @nodoc
abstract mixin class _$CacaColorCopyWith<$Res>
    implements $CacaColorCopyWith<$Res> {
  factory _$CacaColorCopyWith(
          _CacaColor value, $Res Function(_CacaColor) _then) =
      __$CacaColorCopyWithImpl;
  @override
  @useResult
  $Res call({String value, String label, int colorHex, String labelKey});
}

/// @nodoc
class __$CacaColorCopyWithImpl<$Res> implements _$CacaColorCopyWith<$Res> {
  __$CacaColorCopyWithImpl(this._self, this._then);

  final _CacaColor _self;
  final $Res Function(_CacaColor) _then;

  /// Create a copy of CacaColor
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? value = null,
    Object? label = null,
    Object? colorHex = null,
    Object? labelKey = null,
  }) {
    return _then(_CacaColor(
      value: null == value
          ? _self.value
          : value // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _self.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      colorHex: null == colorHex
          ? _self.colorHex
          : colorHex // ignore: cast_nullable_to_non_nullable
              as int,
      labelKey: null == labelKey
          ? _self.labelKey
          : labelKey // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
mixin _$HealthSubtype {
  String get value;
  String get label;
  String get labelKey;

  /// Create a copy of HealthSubtype
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $HealthSubtypeCopyWith<HealthSubtype> get copyWith =>
      _$HealthSubtypeCopyWithImpl<HealthSubtype>(
          this as HealthSubtype, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is HealthSubtype &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.labelKey, labelKey) ||
                other.labelKey == labelKey));
  }

  @override
  int get hashCode => Object.hash(runtimeType, value, label, labelKey);

  @override
  String toString() {
    return 'HealthSubtype(value: $value, label: $label, labelKey: $labelKey)';
  }
}

/// @nodoc
abstract mixin class $HealthSubtypeCopyWith<$Res> {
  factory $HealthSubtypeCopyWith(
          HealthSubtype value, $Res Function(HealthSubtype) _then) =
      _$HealthSubtypeCopyWithImpl;
  @useResult
  $Res call({String value, String label, String labelKey});
}

/// @nodoc
class _$HealthSubtypeCopyWithImpl<$Res>
    implements $HealthSubtypeCopyWith<$Res> {
  _$HealthSubtypeCopyWithImpl(this._self, this._then);

  final HealthSubtype _self;
  final $Res Function(HealthSubtype) _then;

  /// Create a copy of HealthSubtype
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? value = null,
    Object? label = null,
    Object? labelKey = null,
  }) {
    return _then(_self.copyWith(
      value: null == value
          ? _self.value
          : value // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _self.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      labelKey: null == labelKey
          ? _self.labelKey
          : labelKey // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// Adds pattern-matching-related methods to [HealthSubtype].
extension HealthSubtypePatterns on HealthSubtype {
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
    TResult Function(_HealthSubtype value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _HealthSubtype() when $default != null:
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
    TResult Function(_HealthSubtype value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HealthSubtype():
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
    TResult? Function(_HealthSubtype value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HealthSubtype() when $default != null:
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
    TResult Function(String value, String label, String labelKey)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _HealthSubtype() when $default != null:
        return $default(_that.value, _that.label, _that.labelKey);
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
    TResult Function(String value, String label, String labelKey) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HealthSubtype():
        return $default(_that.value, _that.label, _that.labelKey);
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
    TResult? Function(String value, String label, String labelKey)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HealthSubtype() when $default != null:
        return $default(_that.value, _that.label, _that.labelKey);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _HealthSubtype implements HealthSubtype {
  const _HealthSubtype(
      {required this.value, required this.label, required this.labelKey});

  @override
  final String value;
  @override
  final String label;
  @override
  final String labelKey;

  /// Create a copy of HealthSubtype
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$HealthSubtypeCopyWith<_HealthSubtype> get copyWith =>
      __$HealthSubtypeCopyWithImpl<_HealthSubtype>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _HealthSubtype &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.labelKey, labelKey) ||
                other.labelKey == labelKey));
  }

  @override
  int get hashCode => Object.hash(runtimeType, value, label, labelKey);

  @override
  String toString() {
    return 'HealthSubtype(value: $value, label: $label, labelKey: $labelKey)';
  }
}

/// @nodoc
abstract mixin class _$HealthSubtypeCopyWith<$Res>
    implements $HealthSubtypeCopyWith<$Res> {
  factory _$HealthSubtypeCopyWith(
          _HealthSubtype value, $Res Function(_HealthSubtype) _then) =
      __$HealthSubtypeCopyWithImpl;
  @override
  @useResult
  $Res call({String value, String label, String labelKey});
}

/// @nodoc
class __$HealthSubtypeCopyWithImpl<$Res>
    implements _$HealthSubtypeCopyWith<$Res> {
  __$HealthSubtypeCopyWithImpl(this._self, this._then);

  final _HealthSubtype _self;
  final $Res Function(_HealthSubtype) _then;

  /// Create a copy of HealthSubtype
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? value = null,
    Object? label = null,
    Object? labelKey = null,
  }) {
    return _then(_HealthSubtype(
      value: null == value
          ? _self.value
          : value // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _self.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      labelKey: null == labelKey
          ? _self.labelKey
          : labelKey // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
