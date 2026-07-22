// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reminders_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ReminderStatus {
  ReminderItem get item;
  DateTime? get lastDismissedAt;
  DateTime? get lastEventAt;

  /// Create a copy of ReminderStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ReminderStatusCopyWith<ReminderStatus> get copyWith =>
      _$ReminderStatusCopyWithImpl<ReminderStatus>(
          this as ReminderStatus, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ReminderStatus &&
            (identical(other.item, item) || other.item == item) &&
            (identical(other.lastDismissedAt, lastDismissedAt) ||
                other.lastDismissedAt == lastDismissedAt) &&
            (identical(other.lastEventAt, lastEventAt) ||
                other.lastEventAt == lastEventAt));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, item, lastDismissedAt, lastEventAt);

  @override
  String toString() {
    return 'ReminderStatus(item: $item, lastDismissedAt: $lastDismissedAt, lastEventAt: $lastEventAt)';
  }
}

/// @nodoc
abstract mixin class $ReminderStatusCopyWith<$Res> {
  factory $ReminderStatusCopyWith(
          ReminderStatus value, $Res Function(ReminderStatus) _then) =
      _$ReminderStatusCopyWithImpl;
  @useResult
  $Res call(
      {ReminderItem item, DateTime? lastDismissedAt, DateTime? lastEventAt});

  $ReminderItemCopyWith<$Res> get item;
}

/// @nodoc
class _$ReminderStatusCopyWithImpl<$Res>
    implements $ReminderStatusCopyWith<$Res> {
  _$ReminderStatusCopyWithImpl(this._self, this._then);

  final ReminderStatus _self;
  final $Res Function(ReminderStatus) _then;

  /// Create a copy of ReminderStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? item = null,
    Object? lastDismissedAt = freezed,
    Object? lastEventAt = freezed,
  }) {
    return _then(_self.copyWith(
      item: null == item
          ? _self.item
          : item // ignore: cast_nullable_to_non_nullable
              as ReminderItem,
      lastDismissedAt: freezed == lastDismissedAt
          ? _self.lastDismissedAt
          : lastDismissedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastEventAt: freezed == lastEventAt
          ? _self.lastEventAt
          : lastEventAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }

  /// Create a copy of ReminderStatus
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ReminderItemCopyWith<$Res> get item {
    return $ReminderItemCopyWith<$Res>(_self.item, (value) {
      return _then(_self.copyWith(item: value));
    });
  }
}

/// Adds pattern-matching-related methods to [ReminderStatus].
extension ReminderStatusPatterns on ReminderStatus {
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
    TResult Function(_ReminderStatus value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ReminderStatus() when $default != null:
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
    TResult Function(_ReminderStatus value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ReminderStatus():
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
    TResult? Function(_ReminderStatus value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ReminderStatus() when $default != null:
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
    TResult Function(ReminderItem item, DateTime? lastDismissedAt,
            DateTime? lastEventAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ReminderStatus() when $default != null:
        return $default(_that.item, _that.lastDismissedAt, _that.lastEventAt);
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
            ReminderItem item, DateTime? lastDismissedAt, DateTime? lastEventAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ReminderStatus():
        return $default(_that.item, _that.lastDismissedAt, _that.lastEventAt);
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
    TResult? Function(ReminderItem item, DateTime? lastDismissedAt,
            DateTime? lastEventAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ReminderStatus() when $default != null:
        return $default(_that.item, _that.lastDismissedAt, _that.lastEventAt);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _ReminderStatus implements ReminderStatus {
  const _ReminderStatus(
      {required this.item, this.lastDismissedAt, this.lastEventAt});

  @override
  final ReminderItem item;
  @override
  final DateTime? lastDismissedAt;
  @override
  final DateTime? lastEventAt;

  /// Create a copy of ReminderStatus
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ReminderStatusCopyWith<_ReminderStatus> get copyWith =>
      __$ReminderStatusCopyWithImpl<_ReminderStatus>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ReminderStatus &&
            (identical(other.item, item) || other.item == item) &&
            (identical(other.lastDismissedAt, lastDismissedAt) ||
                other.lastDismissedAt == lastDismissedAt) &&
            (identical(other.lastEventAt, lastEventAt) ||
                other.lastEventAt == lastEventAt));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, item, lastDismissedAt, lastEventAt);

  @override
  String toString() {
    return 'ReminderStatus(item: $item, lastDismissedAt: $lastDismissedAt, lastEventAt: $lastEventAt)';
  }
}

/// @nodoc
abstract mixin class _$ReminderStatusCopyWith<$Res>
    implements $ReminderStatusCopyWith<$Res> {
  factory _$ReminderStatusCopyWith(
          _ReminderStatus value, $Res Function(_ReminderStatus) _then) =
      __$ReminderStatusCopyWithImpl;
  @override
  @useResult
  $Res call(
      {ReminderItem item, DateTime? lastDismissedAt, DateTime? lastEventAt});

  @override
  $ReminderItemCopyWith<$Res> get item;
}

/// @nodoc
class __$ReminderStatusCopyWithImpl<$Res>
    implements _$ReminderStatusCopyWith<$Res> {
  __$ReminderStatusCopyWithImpl(this._self, this._then);

  final _ReminderStatus _self;
  final $Res Function(_ReminderStatus) _then;

  /// Create a copy of ReminderStatus
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? item = null,
    Object? lastDismissedAt = freezed,
    Object? lastEventAt = freezed,
  }) {
    return _then(_ReminderStatus(
      item: null == item
          ? _self.item
          : item // ignore: cast_nullable_to_non_nullable
              as ReminderItem,
      lastDismissedAt: freezed == lastDismissedAt
          ? _self.lastDismissedAt
          : lastDismissedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastEventAt: freezed == lastEventAt
          ? _self.lastEventAt
          : lastEventAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }

  /// Create a copy of ReminderStatus
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ReminderItemCopyWith<$Res> get item {
    return $ReminderItemCopyWith<$Res>(_self.item, (value) {
      return _then(_self.copyWith(item: value));
    });
  }
}

/// @nodoc
mixin _$RemindersState {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is RemindersState);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'RemindersState()';
  }
}

/// @nodoc
class $RemindersStateCopyWith<$Res> {
  $RemindersStateCopyWith(RemindersState _, $Res Function(RemindersState) __);
}

/// Adds pattern-matching-related methods to [RemindersState].
extension RemindersStatePatterns on RemindersState {
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
    TResult Function(RemindersDue value)? due,
    TResult Function(RemindersAllCompleted value)? allCompleted,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case RemindersDue() when due != null:
        return due(_that);
      case RemindersAllCompleted() when allCompleted != null:
        return allCompleted(_that);
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
    required TResult Function(RemindersDue value) due,
    required TResult Function(RemindersAllCompleted value) allCompleted,
  }) {
    final _that = this;
    switch (_that) {
      case RemindersDue():
        return due(_that);
      case RemindersAllCompleted():
        return allCompleted(_that);
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
    TResult? Function(RemindersDue value)? due,
    TResult? Function(RemindersAllCompleted value)? allCompleted,
  }) {
    final _that = this;
    switch (_that) {
      case RemindersDue() when due != null:
        return due(_that);
      case RemindersAllCompleted() when allCompleted != null:
        return allCompleted(_that);
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
    TResult Function(List<ReminderStatus> items)? due,
    TResult Function()? allCompleted,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case RemindersDue() when due != null:
        return due(_that.items);
      case RemindersAllCompleted() when allCompleted != null:
        return allCompleted();
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
    required TResult Function(List<ReminderStatus> items) due,
    required TResult Function() allCompleted,
  }) {
    final _that = this;
    switch (_that) {
      case RemindersDue():
        return due(_that.items);
      case RemindersAllCompleted():
        return allCompleted();
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
    TResult? Function(List<ReminderStatus> items)? due,
    TResult? Function()? allCompleted,
  }) {
    final _that = this;
    switch (_that) {
      case RemindersDue() when due != null:
        return due(_that.items);
      case RemindersAllCompleted() when allCompleted != null:
        return allCompleted();
      case _:
        return null;
    }
  }
}

/// @nodoc

class RemindersDue implements RemindersState {
  const RemindersDue({required final List<ReminderStatus> items})
      : _items = items;

  final List<ReminderStatus> _items;
  List<ReminderStatus> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  /// Create a copy of RemindersState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RemindersDueCopyWith<RemindersDue> get copyWith =>
      _$RemindersDueCopyWithImpl<RemindersDue>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RemindersDue &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_items));

  @override
  String toString() {
    return 'RemindersState.due(items: $items)';
  }
}

/// @nodoc
abstract mixin class $RemindersDueCopyWith<$Res>
    implements $RemindersStateCopyWith<$Res> {
  factory $RemindersDueCopyWith(
          RemindersDue value, $Res Function(RemindersDue) _then) =
      _$RemindersDueCopyWithImpl;
  @useResult
  $Res call({List<ReminderStatus> items});
}

/// @nodoc
class _$RemindersDueCopyWithImpl<$Res> implements $RemindersDueCopyWith<$Res> {
  _$RemindersDueCopyWithImpl(this._self, this._then);

  final RemindersDue _self;
  final $Res Function(RemindersDue) _then;

  /// Create a copy of RemindersState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? items = null,
  }) {
    return _then(RemindersDue(
      items: null == items
          ? _self._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<ReminderStatus>,
    ));
  }
}

/// @nodoc

class RemindersAllCompleted implements RemindersState {
  const RemindersAllCompleted();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is RemindersAllCompleted);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'RemindersState.allCompleted()';
  }
}

// dart format on
