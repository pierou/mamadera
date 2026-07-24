// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tracking_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TrackingEvent {
  DateTime get timestamp;
  int? get id;
  String? get babyId;

  /// Create a copy of TrackingEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TrackingEventCopyWith<TrackingEvent> get copyWith =>
      _$TrackingEventCopyWithImpl<TrackingEvent>(
          this as TrackingEvent, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TrackingEvent &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.babyId, babyId) || other.babyId == babyId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, timestamp, id, babyId);

  @override
  String toString() {
    return 'TrackingEvent(timestamp: $timestamp, id: $id, babyId: $babyId)';
  }
}

/// @nodoc
abstract mixin class $TrackingEventCopyWith<$Res> {
  factory $TrackingEventCopyWith(
          TrackingEvent value, $Res Function(TrackingEvent) _then) =
      _$TrackingEventCopyWithImpl;
  @useResult
  $Res call({DateTime timestamp, int? id, String? babyId});
}

/// @nodoc
class _$TrackingEventCopyWithImpl<$Res>
    implements $TrackingEventCopyWith<$Res> {
  _$TrackingEventCopyWithImpl(this._self, this._then);

  final TrackingEvent _self;
  final $Res Function(TrackingEvent) _then;

  /// Create a copy of TrackingEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? timestamp = null,
    Object? id = freezed,
    Object? babyId = freezed,
  }) {
    return _then(_self.copyWith(
      timestamp: null == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      id: freezed == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      babyId: freezed == babyId
          ? _self.babyId
          : babyId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [TrackingEvent].
extension TrackingEventPatterns on TrackingEvent {
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
    TResult Function(_TrackingEvent value)? $default, {
    TResult Function(FeedingEvent value)? feeding,
    TResult Function(SleepEvent value)? sleep,
    TResult Function(DiaperEvent value)? diaper,
    TResult Function(HealthEvent value)? health,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TrackingEvent() when $default != null:
        return $default(_that);
      case FeedingEvent() when feeding != null:
        return feeding(_that);
      case SleepEvent() when sleep != null:
        return sleep(_that);
      case DiaperEvent() when diaper != null:
        return diaper(_that);
      case HealthEvent() when health != null:
        return health(_that);
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
    TResult Function(_TrackingEvent value) $default, {
    required TResult Function(FeedingEvent value) feeding,
    required TResult Function(SleepEvent value) sleep,
    required TResult Function(DiaperEvent value) diaper,
    required TResult Function(HealthEvent value) health,
  }) {
    final _that = this;
    switch (_that) {
      case _TrackingEvent():
        return $default(_that);
      case FeedingEvent():
        return feeding(_that);
      case SleepEvent():
        return sleep(_that);
      case DiaperEvent():
        return diaper(_that);
      case HealthEvent():
        return health(_that);
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
    TResult? Function(_TrackingEvent value)? $default, {
    TResult? Function(FeedingEvent value)? feeding,
    TResult? Function(SleepEvent value)? sleep,
    TResult? Function(DiaperEvent value)? diaper,
    TResult? Function(HealthEvent value)? health,
  }) {
    final _that = this;
    switch (_that) {
      case _TrackingEvent() when $default != null:
        return $default(_that);
      case FeedingEvent() when feeding != null:
        return feeding(_that);
      case SleepEvent() when sleep != null:
        return sleep(_that);
      case DiaperEvent() when diaper != null:
        return diaper(_that);
      case HealthEvent() when health != null:
        return health(_that);
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
    TResult Function(DateTime timestamp, int? id, String? babyId)? $default, {
    TResult Function(FeedingSubtype subtype, double duration, double? quantity,
            DateTime timestamp, int? id, String? babyId, String? notes)?
        feeding,
    TResult Function(double duration, double? quantity, DateTime timestamp,
            int? id, String? babyId, String? notes)?
        sleep,
    TResult Function(
            DateTime timestamp,
            int? id,
            String? babyId,
            WasteType? wasteType,
            PipiColor? pipiColor,
            CacaColor? cacaColor,
            String? notes)?
        diaper,
    TResult Function(HealthSubtype subtype, DateTime timestamp, int? id,
            String? babyId, String? notes)?
        health,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TrackingEvent() when $default != null:
        return $default(_that.timestamp, _that.id, _that.babyId);
      case FeedingEvent() when feeding != null:
        return feeding(_that.subtype, _that.duration, _that.quantity,
            _that.timestamp, _that.id, _that.babyId, _that.notes);
      case SleepEvent() when sleep != null:
        return sleep(_that.duration, _that.quantity, _that.timestamp, _that.id,
            _that.babyId, _that.notes);
      case DiaperEvent() when diaper != null:
        return diaper(_that.timestamp, _that.id, _that.babyId, _that.wasteType,
            _that.pipiColor, _that.cacaColor, _that.notes);
      case HealthEvent() when health != null:
        return health(_that.subtype, _that.timestamp, _that.id, _that.babyId,
            _that.notes);
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
    TResult Function(DateTime timestamp, int? id, String? babyId) $default, {
    required TResult Function(
            FeedingSubtype subtype,
            double duration,
            double? quantity,
            DateTime timestamp,
            int? id,
            String? babyId,
            String? notes)
        feeding,
    required TResult Function(double duration, double? quantity,
            DateTime timestamp, int? id, String? babyId, String? notes)
        sleep,
    required TResult Function(
            DateTime timestamp,
            int? id,
            String? babyId,
            WasteType? wasteType,
            PipiColor? pipiColor,
            CacaColor? cacaColor,
            String? notes)
        diaper,
    required TResult Function(HealthSubtype subtype, DateTime timestamp,
            int? id, String? babyId, String? notes)
        health,
  }) {
    final _that = this;
    switch (_that) {
      case _TrackingEvent():
        return $default(_that.timestamp, _that.id, _that.babyId);
      case FeedingEvent():
        return feeding(_that.subtype, _that.duration, _that.quantity,
            _that.timestamp, _that.id, _that.babyId, _that.notes);
      case SleepEvent():
        return sleep(_that.duration, _that.quantity, _that.timestamp, _that.id,
            _that.babyId, _that.notes);
      case DiaperEvent():
        return diaper(_that.timestamp, _that.id, _that.babyId, _that.wasteType,
            _that.pipiColor, _that.cacaColor, _that.notes);
      case HealthEvent():
        return health(_that.subtype, _that.timestamp, _that.id, _that.babyId,
            _that.notes);
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
    TResult? Function(DateTime timestamp, int? id, String? babyId)? $default, {
    TResult? Function(FeedingSubtype subtype, double duration, double? quantity,
            DateTime timestamp, int? id, String? babyId, String? notes)?
        feeding,
    TResult? Function(double duration, double? quantity, DateTime timestamp,
            int? id, String? babyId, String? notes)?
        sleep,
    TResult? Function(
            DateTime timestamp,
            int? id,
            String? babyId,
            WasteType? wasteType,
            PipiColor? pipiColor,
            CacaColor? cacaColor,
            String? notes)?
        diaper,
    TResult? Function(HealthSubtype subtype, DateTime timestamp, int? id,
            String? babyId, String? notes)?
        health,
  }) {
    final _that = this;
    switch (_that) {
      case _TrackingEvent() when $default != null:
        return $default(_that.timestamp, _that.id, _that.babyId);
      case FeedingEvent() when feeding != null:
        return feeding(_that.subtype, _that.duration, _that.quantity,
            _that.timestamp, _that.id, _that.babyId, _that.notes);
      case SleepEvent() when sleep != null:
        return sleep(_that.duration, _that.quantity, _that.timestamp, _that.id,
            _that.babyId, _that.notes);
      case DiaperEvent() when diaper != null:
        return diaper(_that.timestamp, _that.id, _that.babyId, _that.wasteType,
            _that.pipiColor, _that.cacaColor, _that.notes);
      case HealthEvent() when health != null:
        return health(_that.subtype, _that.timestamp, _that.id, _that.babyId,
            _that.notes);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _TrackingEvent implements TrackingEvent {
  const _TrackingEvent({required this.timestamp, this.id, this.babyId});

  @override
  final DateTime timestamp;
  @override
  final int? id;
  @override
  final String? babyId;

  /// Create a copy of TrackingEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$TrackingEventCopyWith<_TrackingEvent> get copyWith =>
      __$TrackingEventCopyWithImpl<_TrackingEvent>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _TrackingEvent &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.babyId, babyId) || other.babyId == babyId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, timestamp, id, babyId);

  @override
  String toString() {
    return 'TrackingEvent(timestamp: $timestamp, id: $id, babyId: $babyId)';
  }
}

/// @nodoc
abstract mixin class _$TrackingEventCopyWith<$Res>
    implements $TrackingEventCopyWith<$Res> {
  factory _$TrackingEventCopyWith(
          _TrackingEvent value, $Res Function(_TrackingEvent) _then) =
      __$TrackingEventCopyWithImpl;
  @override
  @useResult
  $Res call({DateTime timestamp, int? id, String? babyId});
}

/// @nodoc
class __$TrackingEventCopyWithImpl<$Res>
    implements _$TrackingEventCopyWith<$Res> {
  __$TrackingEventCopyWithImpl(this._self, this._then);

  final _TrackingEvent _self;
  final $Res Function(_TrackingEvent) _then;

  /// Create a copy of TrackingEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? timestamp = null,
    Object? id = freezed,
    Object? babyId = freezed,
  }) {
    return _then(_TrackingEvent(
      timestamp: null == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      id: freezed == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      babyId: freezed == babyId
          ? _self.babyId
          : babyId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class FeedingEvent implements TrackingEvent {
  const FeedingEvent(
      {required this.subtype,
      required this.duration,
      this.quantity,
      required this.timestamp,
      this.id,
      this.babyId,
      this.notes});

  final FeedingSubtype subtype;
  final double duration;
  final double? quantity;
  @override
  final DateTime timestamp;
  @override
  final int? id;
  @override
  final String? babyId;
  final String? notes;

  /// Create a copy of TrackingEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FeedingEventCopyWith<FeedingEvent> get copyWith =>
      _$FeedingEventCopyWithImpl<FeedingEvent>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FeedingEvent &&
            (identical(other.subtype, subtype) || other.subtype == subtype) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.babyId, babyId) || other.babyId == babyId) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, subtype, duration, quantity, timestamp, id, babyId, notes);

  @override
  String toString() {
    return 'TrackingEvent.feeding(subtype: $subtype, duration: $duration, quantity: $quantity, timestamp: $timestamp, id: $id, babyId: $babyId, notes: $notes)';
  }
}

/// @nodoc
abstract mixin class $FeedingEventCopyWith<$Res>
    implements $TrackingEventCopyWith<$Res> {
  factory $FeedingEventCopyWith(
          FeedingEvent value, $Res Function(FeedingEvent) _then) =
      _$FeedingEventCopyWithImpl;
  @override
  @useResult
  $Res call(
      {FeedingSubtype subtype,
      double duration,
      double? quantity,
      DateTime timestamp,
      int? id,
      String? babyId,
      String? notes});
}

/// @nodoc
class _$FeedingEventCopyWithImpl<$Res> implements $FeedingEventCopyWith<$Res> {
  _$FeedingEventCopyWithImpl(this._self, this._then);

  final FeedingEvent _self;
  final $Res Function(FeedingEvent) _then;

  /// Create a copy of TrackingEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? subtype = null,
    Object? duration = null,
    Object? quantity = freezed,
    Object? timestamp = null,
    Object? id = freezed,
    Object? babyId = freezed,
    Object? notes = freezed,
  }) {
    return _then(FeedingEvent(
      subtype: null == subtype
          ? _self.subtype
          : subtype // ignore: cast_nullable_to_non_nullable
              as FeedingSubtype,
      duration: null == duration
          ? _self.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as double,
      quantity: freezed == quantity
          ? _self.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as double?,
      timestamp: null == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      id: freezed == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      babyId: freezed == babyId
          ? _self.babyId
          : babyId // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _self.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class SleepEvent implements TrackingEvent {
  const SleepEvent(
      {required this.duration,
      this.quantity,
      required this.timestamp,
      this.id,
      this.babyId,
      this.notes});

  final double duration;
  final double? quantity;
  @override
  final DateTime timestamp;
  @override
  final int? id;
  @override
  final String? babyId;
  final String? notes;

  /// Create a copy of TrackingEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SleepEventCopyWith<SleepEvent> get copyWith =>
      _$SleepEventCopyWithImpl<SleepEvent>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SleepEvent &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.babyId, babyId) || other.babyId == babyId) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, duration, quantity, timestamp, id, babyId, notes);

  @override
  String toString() {
    return 'TrackingEvent.sleep(duration: $duration, quantity: $quantity, timestamp: $timestamp, id: $id, babyId: $babyId, notes: $notes)';
  }
}

/// @nodoc
abstract mixin class $SleepEventCopyWith<$Res>
    implements $TrackingEventCopyWith<$Res> {
  factory $SleepEventCopyWith(
          SleepEvent value, $Res Function(SleepEvent) _then) =
      _$SleepEventCopyWithImpl;
  @override
  @useResult
  $Res call(
      {double duration,
      double? quantity,
      DateTime timestamp,
      int? id,
      String? babyId,
      String? notes});
}

/// @nodoc
class _$SleepEventCopyWithImpl<$Res> implements $SleepEventCopyWith<$Res> {
  _$SleepEventCopyWithImpl(this._self, this._then);

  final SleepEvent _self;
  final $Res Function(SleepEvent) _then;

  /// Create a copy of TrackingEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? duration = null,
    Object? quantity = freezed,
    Object? timestamp = null,
    Object? id = freezed,
    Object? babyId = freezed,
    Object? notes = freezed,
  }) {
    return _then(SleepEvent(
      duration: null == duration
          ? _self.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as double,
      quantity: freezed == quantity
          ? _self.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as double?,
      timestamp: null == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      id: freezed == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      babyId: freezed == babyId
          ? _self.babyId
          : babyId // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _self.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class DiaperEvent implements TrackingEvent {
  const DiaperEvent(
      {required this.timestamp,
      this.id,
      this.babyId,
      this.wasteType,
      this.pipiColor,
      this.cacaColor,
      this.notes});

  @override
  final DateTime timestamp;
  @override
  final int? id;
  @override
  final String? babyId;
  final WasteType? wasteType;
  final PipiColor? pipiColor;
  final CacaColor? cacaColor;
  final String? notes;

  /// Create a copy of TrackingEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $DiaperEventCopyWith<DiaperEvent> get copyWith =>
      _$DiaperEventCopyWithImpl<DiaperEvent>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is DiaperEvent &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.babyId, babyId) || other.babyId == babyId) &&
            (identical(other.wasteType, wasteType) ||
                other.wasteType == wasteType) &&
            (identical(other.pipiColor, pipiColor) ||
                other.pipiColor == pipiColor) &&
            (identical(other.cacaColor, cacaColor) ||
                other.cacaColor == cacaColor) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @override
  int get hashCode => Object.hash(runtimeType, timestamp, id, babyId, wasteType,
      pipiColor, cacaColor, notes);

  @override
  String toString() {
    return 'TrackingEvent.diaper(timestamp: $timestamp, id: $id, babyId: $babyId, wasteType: $wasteType, pipiColor: $pipiColor, cacaColor: $cacaColor, notes: $notes)';
  }
}

/// @nodoc
abstract mixin class $DiaperEventCopyWith<$Res>
    implements $TrackingEventCopyWith<$Res> {
  factory $DiaperEventCopyWith(
          DiaperEvent value, $Res Function(DiaperEvent) _then) =
      _$DiaperEventCopyWithImpl;
  @override
  @useResult
  $Res call(
      {DateTime timestamp,
      int? id,
      String? babyId,
      WasteType? wasteType,
      PipiColor? pipiColor,
      CacaColor? cacaColor,
      String? notes});

  $PipiColorCopyWith<$Res>? get pipiColor;
  $CacaColorCopyWith<$Res>? get cacaColor;
}

/// @nodoc
class _$DiaperEventCopyWithImpl<$Res> implements $DiaperEventCopyWith<$Res> {
  _$DiaperEventCopyWithImpl(this._self, this._then);

  final DiaperEvent _self;
  final $Res Function(DiaperEvent) _then;

  /// Create a copy of TrackingEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? timestamp = null,
    Object? id = freezed,
    Object? babyId = freezed,
    Object? wasteType = freezed,
    Object? pipiColor = freezed,
    Object? cacaColor = freezed,
    Object? notes = freezed,
  }) {
    return _then(DiaperEvent(
      timestamp: null == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      id: freezed == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      babyId: freezed == babyId
          ? _self.babyId
          : babyId // ignore: cast_nullable_to_non_nullable
              as String?,
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
      notes: freezed == notes
          ? _self.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }

  /// Create a copy of TrackingEvent
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

  /// Create a copy of TrackingEvent
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

class HealthEvent implements TrackingEvent {
  const HealthEvent(
      {required this.subtype,
      required this.timestamp,
      this.id,
      this.babyId,
      this.notes});

  final HealthSubtype subtype;
  @override
  final DateTime timestamp;
  @override
  final int? id;
  @override
  final String? babyId;
  final String? notes;

  /// Create a copy of TrackingEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $HealthEventCopyWith<HealthEvent> get copyWith =>
      _$HealthEventCopyWithImpl<HealthEvent>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is HealthEvent &&
            (identical(other.subtype, subtype) || other.subtype == subtype) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.babyId, babyId) || other.babyId == babyId) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, subtype, timestamp, id, babyId, notes);

  @override
  String toString() {
    return 'TrackingEvent.health(subtype: $subtype, timestamp: $timestamp, id: $id, babyId: $babyId, notes: $notes)';
  }
}

/// @nodoc
abstract mixin class $HealthEventCopyWith<$Res>
    implements $TrackingEventCopyWith<$Res> {
  factory $HealthEventCopyWith(
          HealthEvent value, $Res Function(HealthEvent) _then) =
      _$HealthEventCopyWithImpl;
  @override
  @useResult
  $Res call(
      {HealthSubtype subtype,
      DateTime timestamp,
      int? id,
      String? babyId,
      String? notes});

  $HealthSubtypeCopyWith<$Res> get subtype;
}

/// @nodoc
class _$HealthEventCopyWithImpl<$Res> implements $HealthEventCopyWith<$Res> {
  _$HealthEventCopyWithImpl(this._self, this._then);

  final HealthEvent _self;
  final $Res Function(HealthEvent) _then;

  /// Create a copy of TrackingEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? subtype = null,
    Object? timestamp = null,
    Object? id = freezed,
    Object? babyId = freezed,
    Object? notes = freezed,
  }) {
    return _then(HealthEvent(
      subtype: null == subtype
          ? _self.subtype
          : subtype // ignore: cast_nullable_to_non_nullable
              as HealthSubtype,
      timestamp: null == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      id: freezed == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      babyId: freezed == babyId
          ? _self.babyId
          : babyId // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _self.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }

  /// Create a copy of TrackingEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $HealthSubtypeCopyWith<$Res> get subtype {
    return $HealthSubtypeCopyWith<$Res>(_self.subtype, (value) {
      return _then(_self.copyWith(subtype: value));
    });
  }
}

// dart format on
