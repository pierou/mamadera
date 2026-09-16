// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'custom_reminder.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CustomReminder {
  /// Saisie libre du parent, affichée telle quelle (jamais traduite).
  String get label;

  /// Valeur de `HealthSubtype` dont l'absence rend le rappel dû.
  String get subtypeValue;

  /// Rythme demandé. [ReminderFrequency.monthly] est stocké sans jour
  /// précis : le jour est celui de naissance du bébé actif, lu au moment de
  /// construire la liste — comme pour la vitamine K.
  ReminderFrequency get frequency;

  /// Clé de `custom_reminders`, `null` tant que le rappel n'est pas écrit.
  int? get id;

  /// Create a copy of CustomReminder
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CustomReminderCopyWith<CustomReminder> get copyWith =>
      _$CustomReminderCopyWithImpl<CustomReminder>(
          this as CustomReminder, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CustomReminder &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.subtypeValue, subtypeValue) ||
                other.subtypeValue == subtypeValue) &&
            (identical(other.frequency, frequency) ||
                other.frequency == frequency) &&
            (identical(other.id, id) || other.id == id));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, label, subtypeValue, frequency, id);

  @override
  String toString() {
    return 'CustomReminder(label: $label, subtypeValue: $subtypeValue, frequency: $frequency, id: $id)';
  }
}

/// @nodoc
abstract mixin class $CustomReminderCopyWith<$Res> {
  factory $CustomReminderCopyWith(
          CustomReminder value, $Res Function(CustomReminder) _then) =
      _$CustomReminderCopyWithImpl;
  @useResult
  $Res call(
      {String label,
      String subtypeValue,
      ReminderFrequency frequency,
      int? id});

  $ReminderFrequencyCopyWith<$Res> get frequency;
}

/// @nodoc
class _$CustomReminderCopyWithImpl<$Res>
    implements $CustomReminderCopyWith<$Res> {
  _$CustomReminderCopyWithImpl(this._self, this._then);

  final CustomReminder _self;
  final $Res Function(CustomReminder) _then;

  /// Create a copy of CustomReminder
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? label = null,
    Object? subtypeValue = null,
    Object? frequency = null,
    Object? id = freezed,
  }) {
    return _then(_self.copyWith(
      label: null == label
          ? _self.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      subtypeValue: null == subtypeValue
          ? _self.subtypeValue
          : subtypeValue // ignore: cast_nullable_to_non_nullable
              as String,
      frequency: null == frequency
          ? _self.frequency
          : frequency // ignore: cast_nullable_to_non_nullable
              as ReminderFrequency,
      id: freezed == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }

  /// Create a copy of CustomReminder
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ReminderFrequencyCopyWith<$Res> get frequency {
    return $ReminderFrequencyCopyWith<$Res>(_self.frequency, (value) {
      return _then(_self.copyWith(frequency: value));
    });
  }
}

/// Adds pattern-matching-related methods to [CustomReminder].
extension CustomReminderPatterns on CustomReminder {
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
    TResult Function(_CustomReminder value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CustomReminder() when $default != null:
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
    TResult Function(_CustomReminder value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CustomReminder():
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
    TResult? Function(_CustomReminder value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CustomReminder() when $default != null:
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
    TResult Function(String label, String subtypeValue,
            ReminderFrequency frequency, int? id)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CustomReminder() when $default != null:
        return $default(
            _that.label, _that.subtypeValue, _that.frequency, _that.id);
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
    TResult Function(String label, String subtypeValue,
            ReminderFrequency frequency, int? id)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CustomReminder():
        return $default(
            _that.label, _that.subtypeValue, _that.frequency, _that.id);
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
    TResult? Function(String label, String subtypeValue,
            ReminderFrequency frequency, int? id)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CustomReminder() when $default != null:
        return $default(
            _that.label, _that.subtypeValue, _that.frequency, _that.id);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _CustomReminder implements CustomReminder {
  const _CustomReminder(
      {required this.label,
      required this.subtypeValue,
      required this.frequency,
      this.id});

  /// Saisie libre du parent, affichée telle quelle (jamais traduite).
  @override
  final String label;

  /// Valeur de `HealthSubtype` dont l'absence rend le rappel dû.
  @override
  final String subtypeValue;

  /// Rythme demandé. [ReminderFrequency.monthly] est stocké sans jour
  /// précis : le jour est celui de naissance du bébé actif, lu au moment de
  /// construire la liste — comme pour la vitamine K.
  @override
  final ReminderFrequency frequency;

  /// Clé de `custom_reminders`, `null` tant que le rappel n'est pas écrit.
  @override
  final int? id;

  /// Create a copy of CustomReminder
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$CustomReminderCopyWith<_CustomReminder> get copyWith =>
      __$CustomReminderCopyWithImpl<_CustomReminder>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _CustomReminder &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.subtypeValue, subtypeValue) ||
                other.subtypeValue == subtypeValue) &&
            (identical(other.frequency, frequency) ||
                other.frequency == frequency) &&
            (identical(other.id, id) || other.id == id));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, label, subtypeValue, frequency, id);

  @override
  String toString() {
    return 'CustomReminder(label: $label, subtypeValue: $subtypeValue, frequency: $frequency, id: $id)';
  }
}

/// @nodoc
abstract mixin class _$CustomReminderCopyWith<$Res>
    implements $CustomReminderCopyWith<$Res> {
  factory _$CustomReminderCopyWith(
          _CustomReminder value, $Res Function(_CustomReminder) _then) =
      __$CustomReminderCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String label,
      String subtypeValue,
      ReminderFrequency frequency,
      int? id});

  @override
  $ReminderFrequencyCopyWith<$Res> get frequency;
}

/// @nodoc
class __$CustomReminderCopyWithImpl<$Res>
    implements _$CustomReminderCopyWith<$Res> {
  __$CustomReminderCopyWithImpl(this._self, this._then);

  final _CustomReminder _self;
  final $Res Function(_CustomReminder) _then;

  /// Create a copy of CustomReminder
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? label = null,
    Object? subtypeValue = null,
    Object? frequency = null,
    Object? id = freezed,
  }) {
    return _then(_CustomReminder(
      label: null == label
          ? _self.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      subtypeValue: null == subtypeValue
          ? _self.subtypeValue
          : subtypeValue // ignore: cast_nullable_to_non_nullable
              as String,
      frequency: null == frequency
          ? _self.frequency
          : frequency // ignore: cast_nullable_to_non_nullable
              as ReminderFrequency,
      id: freezed == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }

  /// Create a copy of CustomReminder
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
