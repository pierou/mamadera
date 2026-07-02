// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_db.dart';

// ignore_for_file: type=lint
class $BabyProfilesTable extends BabyProfiles
    with TableInfo<$BabyProfilesTable, BabyProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BabyProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _birthDateMeta =
      const VerificationMeta('birthDate');
  @override
  late final GeneratedColumn<int> birthDate = GeneratedColumn<int>(
      'birth_date', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns => [id, name, birthDate, isActive];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'baby_profiles';
  @override
  VerificationContext validateIntegrity(Insertable<BabyProfile> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('birth_date')) {
      context.handle(_birthDateMeta,
          birthDate.isAcceptableOrUnknown(data['birth_date']!, _birthDateMeta));
    } else if (isInserting) {
      context.missing(_birthDateMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BabyProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BabyProfile(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      birthDate: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}birth_date'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
    );
  }

  @override
  $BabyProfilesTable createAlias(String alias) {
    return $BabyProfilesTable(attachedDatabase, alias);
  }
}

class BabyProfile extends DataClass implements Insertable<BabyProfile> {
  final String id;
  final String name;
  final int birthDate;
  final bool isActive;
  const BabyProfile(
      {required this.id,
      required this.name,
      required this.birthDate,
      required this.isActive});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['birth_date'] = Variable<int>(birthDate);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  BabyProfilesCompanion toCompanion(bool nullToAbsent) {
    return BabyProfilesCompanion(
      id: Value(id),
      name: Value(name),
      birthDate: Value(birthDate),
      isActive: Value(isActive),
    );
  }

  factory BabyProfile.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BabyProfile(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      birthDate: serializer.fromJson<int>(json['birthDate']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'birthDate': serializer.toJson<int>(birthDate),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  BabyProfile copyWith(
          {String? id, String? name, int? birthDate, bool? isActive}) =>
      BabyProfile(
        id: id ?? this.id,
        name: name ?? this.name,
        birthDate: birthDate ?? this.birthDate,
        isActive: isActive ?? this.isActive,
      );
  BabyProfile copyWithCompanion(BabyProfilesCompanion data) {
    return BabyProfile(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      birthDate: data.birthDate.present ? data.birthDate.value : this.birthDate,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BabyProfile(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('birthDate: $birthDate, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, birthDate, isActive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BabyProfile &&
          other.id == this.id &&
          other.name == this.name &&
          other.birthDate == this.birthDate &&
          other.isActive == this.isActive);
}

class BabyProfilesCompanion extends UpdateCompanion<BabyProfile> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> birthDate;
  final Value<bool> isActive;
  final Value<int> rowid;
  const BabyProfilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.birthDate = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BabyProfilesCompanion.insert({
    required String id,
    required String name,
    required int birthDate,
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        birthDate = Value(birthDate);
  static Insertable<BabyProfile> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? birthDate,
    Expression<bool>? isActive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (birthDate != null) 'birth_date': birthDate,
      if (isActive != null) 'is_active': isActive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BabyProfilesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<int>? birthDate,
      Value<bool>? isActive,
      Value<int>? rowid}) {
    return BabyProfilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      isActive: isActive ?? this.isActive,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (birthDate.present) {
      map['birth_date'] = Variable<int>(birthDate.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BabyProfilesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('birthDate: $birthDate, ')
          ..write('isActive: $isActive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TrackingEventsTable extends TrackingEvents
    with TableInfo<$TrackingEventsTable, TrackingEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrackingEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _durationMeta =
      const VerificationMeta('duration');
  @override
  late final GeneratedColumn<double> duration = GeneratedColumn<double>(
      'duration', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _wasteTypeMeta =
      const VerificationMeta('wasteType');
  @override
  late final GeneratedColumn<String> wasteType = GeneratedColumn<String>(
      'waste_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
      'color', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _babyIdMeta = const VerificationMeta('babyId');
  @override
  late final GeneratedColumn<String> babyId = GeneratedColumn<String>(
      'baby_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, type, timestamp, duration, notes, wasteType, color, babyId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tracking_events';
  @override
  VerificationContext validateIntegrity(Insertable<TrackingEvent> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('duration')) {
      context.handle(_durationMeta,
          duration.isAcceptableOrUnknown(data['duration']!, _durationMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('waste_type')) {
      context.handle(_wasteTypeMeta,
          wasteType.isAcceptableOrUnknown(data['waste_type']!, _wasteTypeMeta));
    }
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    }
    if (data.containsKey('baby_id')) {
      context.handle(_babyIdMeta,
          babyId.isAcceptableOrUnknown(data['baby_id']!, _babyIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TrackingEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrackingEvent(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}timestamp'])!,
      duration: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}duration']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      wasteType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}waste_type']),
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color']),
      babyId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}baby_id']),
    );
  }

  @override
  $TrackingEventsTable createAlias(String alias) {
    return $TrackingEventsTable(attachedDatabase, alias);
  }
}

class TrackingEvent extends DataClass implements Insertable<TrackingEvent> {
  final int id;
  final String type;
  final DateTime timestamp;
  final double? duration;
  final String? notes;
  final String? wasteType;
  final String? color;
  final String? babyId;
  const TrackingEvent(
      {required this.id,
      required this.type,
      required this.timestamp,
      this.duration,
      this.notes,
      this.wasteType,
      this.color,
      this.babyId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['type'] = Variable<String>(type);
    map['timestamp'] = Variable<DateTime>(timestamp);
    if (!nullToAbsent || duration != null) {
      map['duration'] = Variable<double>(duration);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || wasteType != null) {
      map['waste_type'] = Variable<String>(wasteType);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    if (!nullToAbsent || babyId != null) {
      map['baby_id'] = Variable<String>(babyId);
    }
    return map;
  }

  TrackingEventsCompanion toCompanion(bool nullToAbsent) {
    return TrackingEventsCompanion(
      id: Value(id),
      type: Value(type),
      timestamp: Value(timestamp),
      duration: duration == null && nullToAbsent
          ? const Value.absent()
          : Value(duration),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      wasteType: wasteType == null && nullToAbsent
          ? const Value.absent()
          : Value(wasteType),
      color:
          color == null && nullToAbsent ? const Value.absent() : Value(color),
      babyId:
          babyId == null && nullToAbsent ? const Value.absent() : Value(babyId),
    );
  }

  factory TrackingEvent.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrackingEvent(
      id: serializer.fromJson<int>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      duration: serializer.fromJson<double?>(json['duration']),
      notes: serializer.fromJson<String?>(json['notes']),
      wasteType: serializer.fromJson<String?>(json['wasteType']),
      color: serializer.fromJson<String?>(json['color']),
      babyId: serializer.fromJson<String?>(json['babyId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'type': serializer.toJson<String>(type),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'duration': serializer.toJson<double?>(duration),
      'notes': serializer.toJson<String?>(notes),
      'wasteType': serializer.toJson<String?>(wasteType),
      'color': serializer.toJson<String?>(color),
      'babyId': serializer.toJson<String?>(babyId),
    };
  }

  TrackingEvent copyWith(
          {int? id,
          String? type,
          DateTime? timestamp,
          Value<double?> duration = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          Value<String?> wasteType = const Value.absent(),
          Value<String?> color = const Value.absent(),
          Value<String?> babyId = const Value.absent()}) =>
      TrackingEvent(
        id: id ?? this.id,
        type: type ?? this.type,
        timestamp: timestamp ?? this.timestamp,
        duration: duration.present ? duration.value : this.duration,
        notes: notes.present ? notes.value : this.notes,
        wasteType: wasteType.present ? wasteType.value : this.wasteType,
        color: color.present ? color.value : this.color,
        babyId: babyId.present ? babyId.value : this.babyId,
      );
  TrackingEvent copyWithCompanion(TrackingEventsCompanion data) {
    return TrackingEvent(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      duration: data.duration.present ? data.duration.value : this.duration,
      notes: data.notes.present ? data.notes.value : this.notes,
      wasteType: data.wasteType.present ? data.wasteType.value : this.wasteType,
      color: data.color.present ? data.color.value : this.color,
      babyId: data.babyId.present ? data.babyId.value : this.babyId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrackingEvent(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('timestamp: $timestamp, ')
          ..write('duration: $duration, ')
          ..write('notes: $notes, ')
          ..write('wasteType: $wasteType, ')
          ..write('color: $color, ')
          ..write('babyId: $babyId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, type, timestamp, duration, notes, wasteType, color, babyId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrackingEvent &&
          other.id == this.id &&
          other.type == this.type &&
          other.timestamp == this.timestamp &&
          other.duration == this.duration &&
          other.notes == this.notes &&
          other.wasteType == this.wasteType &&
          other.color == this.color &&
          other.babyId == this.babyId);
}

class TrackingEventsCompanion extends UpdateCompanion<TrackingEvent> {
  final Value<int> id;
  final Value<String> type;
  final Value<DateTime> timestamp;
  final Value<double?> duration;
  final Value<String?> notes;
  final Value<String?> wasteType;
  final Value<String?> color;
  final Value<String?> babyId;
  const TrackingEventsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.duration = const Value.absent(),
    this.notes = const Value.absent(),
    this.wasteType = const Value.absent(),
    this.color = const Value.absent(),
    this.babyId = const Value.absent(),
  });
  TrackingEventsCompanion.insert({
    this.id = const Value.absent(),
    required String type,
    required DateTime timestamp,
    this.duration = const Value.absent(),
    this.notes = const Value.absent(),
    this.wasteType = const Value.absent(),
    this.color = const Value.absent(),
    this.babyId = const Value.absent(),
  })  : type = Value(type),
        timestamp = Value(timestamp);
  static Insertable<TrackingEvent> custom({
    Expression<int>? id,
    Expression<String>? type,
    Expression<DateTime>? timestamp,
    Expression<double>? duration,
    Expression<String>? notes,
    Expression<String>? wasteType,
    Expression<String>? color,
    Expression<String>? babyId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (timestamp != null) 'timestamp': timestamp,
      if (duration != null) 'duration': duration,
      if (notes != null) 'notes': notes,
      if (wasteType != null) 'waste_type': wasteType,
      if (color != null) 'color': color,
      if (babyId != null) 'baby_id': babyId,
    });
  }

  TrackingEventsCompanion copyWith(
      {Value<int>? id,
      Value<String>? type,
      Value<DateTime>? timestamp,
      Value<double?>? duration,
      Value<String?>? notes,
      Value<String?>? wasteType,
      Value<String?>? color,
      Value<String?>? babyId}) {
    return TrackingEventsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      duration: duration ?? this.duration,
      notes: notes ?? this.notes,
      wasteType: wasteType ?? this.wasteType,
      color: color ?? this.color,
      babyId: babyId ?? this.babyId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (duration.present) {
      map['duration'] = Variable<double>(duration.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (wasteType.present) {
      map['waste_type'] = Variable<String>(wasteType.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (babyId.present) {
      map['baby_id'] = Variable<String>(babyId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrackingEventsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('timestamp: $timestamp, ')
          ..write('duration: $duration, ')
          ..write('notes: $notes, ')
          ..write('wasteType: $wasteType, ')
          ..write('color: $color, ')
          ..write('babyId: $babyId')
          ..write(')'))
        .toString();
  }
}

class $ReminderDismissalsTable extends ReminderDismissals
    with TableInfo<$ReminderDismissalsTable, ReminderDismissal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReminderDismissalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
      'item_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _dismissedAtMeta =
      const VerificationMeta('dismissedAt');
  @override
  late final GeneratedColumn<DateTime> dismissedAt = GeneratedColumn<DateTime>(
      'dismissed_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [itemId, dismissedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminder_dismissals';
  @override
  VerificationContext validateIntegrity(Insertable<ReminderDismissal> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('item_id')) {
      context.handle(_itemIdMeta,
          itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta));
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('dismissed_at')) {
      context.handle(
          _dismissedAtMeta,
          dismissedAt.isAcceptableOrUnknown(
              data['dismissed_at']!, _dismissedAtMeta));
    } else if (isInserting) {
      context.missing(_dismissedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  ReminderDismissal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReminderDismissal(
      itemId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}item_id'])!,
      dismissedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}dismissed_at'])!,
    );
  }

  @override
  $ReminderDismissalsTable createAlias(String alias) {
    return $ReminderDismissalsTable(attachedDatabase, alias);
  }
}

class ReminderDismissal extends DataClass
    implements Insertable<ReminderDismissal> {
  final String itemId;
  final DateTime dismissedAt;
  const ReminderDismissal({required this.itemId, required this.dismissedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['item_id'] = Variable<String>(itemId);
    map['dismissed_at'] = Variable<DateTime>(dismissedAt);
    return map;
  }

  ReminderDismissalsCompanion toCompanion(bool nullToAbsent) {
    return ReminderDismissalsCompanion(
      itemId: Value(itemId),
      dismissedAt: Value(dismissedAt),
    );
  }

  factory ReminderDismissal.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReminderDismissal(
      itemId: serializer.fromJson<String>(json['itemId']),
      dismissedAt: serializer.fromJson<DateTime>(json['dismissedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'itemId': serializer.toJson<String>(itemId),
      'dismissedAt': serializer.toJson<DateTime>(dismissedAt),
    };
  }

  ReminderDismissal copyWith({String? itemId, DateTime? dismissedAt}) =>
      ReminderDismissal(
        itemId: itemId ?? this.itemId,
        dismissedAt: dismissedAt ?? this.dismissedAt,
      );
  ReminderDismissal copyWithCompanion(ReminderDismissalsCompanion data) {
    return ReminderDismissal(
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      dismissedAt:
          data.dismissedAt.present ? data.dismissedAt.value : this.dismissedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReminderDismissal(')
          ..write('itemId: $itemId, ')
          ..write('dismissedAt: $dismissedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(itemId, dismissedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReminderDismissal &&
          other.itemId == this.itemId &&
          other.dismissedAt == this.dismissedAt);
}

class ReminderDismissalsCompanion extends UpdateCompanion<ReminderDismissal> {
  final Value<String> itemId;
  final Value<DateTime> dismissedAt;
  final Value<int> rowid;
  const ReminderDismissalsCompanion({
    this.itemId = const Value.absent(),
    this.dismissedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReminderDismissalsCompanion.insert({
    required String itemId,
    required DateTime dismissedAt,
    this.rowid = const Value.absent(),
  })  : itemId = Value(itemId),
        dismissedAt = Value(dismissedAt);
  static Insertable<ReminderDismissal> custom({
    Expression<String>? itemId,
    Expression<DateTime>? dismissedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (itemId != null) 'item_id': itemId,
      if (dismissedAt != null) 'dismissed_at': dismissedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReminderDismissalsCompanion copyWith(
      {Value<String>? itemId,
      Value<DateTime>? dismissedAt,
      Value<int>? rowid}) {
    return ReminderDismissalsCompanion(
      itemId: itemId ?? this.itemId,
      dismissedAt: dismissedAt ?? this.dismissedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (dismissedAt.present) {
      map['dismissed_at'] = Variable<DateTime>(dismissedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReminderDismissalsCompanion(')
          ..write('itemId: $itemId, ')
          ..write('dismissedAt: $dismissedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $BabyProfilesTable babyProfiles = $BabyProfilesTable(this);
  late final $TrackingEventsTable trackingEvents = $TrackingEventsTable(this);
  late final $ReminderDismissalsTable reminderDismissals =
      $ReminderDismissalsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [babyProfiles, trackingEvents, reminderDismissals];
}

typedef $$BabyProfilesTableCreateCompanionBuilder = BabyProfilesCompanion
    Function({
  required String id,
  required String name,
  required int birthDate,
  Value<bool> isActive,
  Value<int> rowid,
});
typedef $$BabyProfilesTableUpdateCompanionBuilder = BabyProfilesCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<int> birthDate,
  Value<bool> isActive,
  Value<int> rowid,
});

class $$BabyProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $BabyProfilesTable> {
  $$BabyProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get birthDate => $composableBuilder(
      column: $table.birthDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));
}

class $$BabyProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $BabyProfilesTable> {
  $$BabyProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get birthDate => $composableBuilder(
      column: $table.birthDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));
}

class $$BabyProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BabyProfilesTable> {
  $$BabyProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get birthDate =>
      $composableBuilder(column: $table.birthDate, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);
}

class $$BabyProfilesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BabyProfilesTable,
    BabyProfile,
    $$BabyProfilesTableFilterComposer,
    $$BabyProfilesTableOrderingComposer,
    $$BabyProfilesTableAnnotationComposer,
    $$BabyProfilesTableCreateCompanionBuilder,
    $$BabyProfilesTableUpdateCompanionBuilder,
    (
      BabyProfile,
      BaseReferences<_$AppDatabase, $BabyProfilesTable, BabyProfile>
    ),
    BabyProfile,
    PrefetchHooks Function()> {
  $$BabyProfilesTableTableManager(_$AppDatabase db, $BabyProfilesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BabyProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BabyProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BabyProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> birthDate = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BabyProfilesCompanion(
            id: id,
            name: name,
            birthDate: birthDate,
            isActive: isActive,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required int birthDate,
            Value<bool> isActive = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BabyProfilesCompanion.insert(
            id: id,
            name: name,
            birthDate: birthDate,
            isActive: isActive,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$BabyProfilesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BabyProfilesTable,
    BabyProfile,
    $$BabyProfilesTableFilterComposer,
    $$BabyProfilesTableOrderingComposer,
    $$BabyProfilesTableAnnotationComposer,
    $$BabyProfilesTableCreateCompanionBuilder,
    $$BabyProfilesTableUpdateCompanionBuilder,
    (
      BabyProfile,
      BaseReferences<_$AppDatabase, $BabyProfilesTable, BabyProfile>
    ),
    BabyProfile,
    PrefetchHooks Function()>;
typedef $$TrackingEventsTableCreateCompanionBuilder = TrackingEventsCompanion
    Function({
  Value<int> id,
  required String type,
  required DateTime timestamp,
  Value<double?> duration,
  Value<String?> notes,
  Value<String?> wasteType,
  Value<String?> color,
  Value<String?> babyId,
});
typedef $$TrackingEventsTableUpdateCompanionBuilder = TrackingEventsCompanion
    Function({
  Value<int> id,
  Value<String> type,
  Value<DateTime> timestamp,
  Value<double?> duration,
  Value<String?> notes,
  Value<String?> wasteType,
  Value<String?> color,
  Value<String?> babyId,
});

class $$TrackingEventsTableFilterComposer
    extends Composer<_$AppDatabase, $TrackingEventsTable> {
  $$TrackingEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get duration => $composableBuilder(
      column: $table.duration, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get wasteType => $composableBuilder(
      column: $table.wasteType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get babyId => $composableBuilder(
      column: $table.babyId, builder: (column) => ColumnFilters(column));
}

class $$TrackingEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $TrackingEventsTable> {
  $$TrackingEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get duration => $composableBuilder(
      column: $table.duration, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get wasteType => $composableBuilder(
      column: $table.wasteType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get babyId => $composableBuilder(
      column: $table.babyId, builder: (column) => ColumnOrderings(column));
}

class $$TrackingEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrackingEventsTable> {
  $$TrackingEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<double> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get wasteType =>
      $composableBuilder(column: $table.wasteType, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get babyId =>
      $composableBuilder(column: $table.babyId, builder: (column) => column);
}

class $$TrackingEventsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TrackingEventsTable,
    TrackingEvent,
    $$TrackingEventsTableFilterComposer,
    $$TrackingEventsTableOrderingComposer,
    $$TrackingEventsTableAnnotationComposer,
    $$TrackingEventsTableCreateCompanionBuilder,
    $$TrackingEventsTableUpdateCompanionBuilder,
    (
      TrackingEvent,
      BaseReferences<_$AppDatabase, $TrackingEventsTable, TrackingEvent>
    ),
    TrackingEvent,
    PrefetchHooks Function()> {
  $$TrackingEventsTableTableManager(
      _$AppDatabase db, $TrackingEventsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrackingEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrackingEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrackingEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<DateTime> timestamp = const Value.absent(),
            Value<double?> duration = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String?> wasteType = const Value.absent(),
            Value<String?> color = const Value.absent(),
            Value<String?> babyId = const Value.absent(),
          }) =>
              TrackingEventsCompanion(
            id: id,
            type: type,
            timestamp: timestamp,
            duration: duration,
            notes: notes,
            wasteType: wasteType,
            color: color,
            babyId: babyId,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String type,
            required DateTime timestamp,
            Value<double?> duration = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String?> wasteType = const Value.absent(),
            Value<String?> color = const Value.absent(),
            Value<String?> babyId = const Value.absent(),
          }) =>
              TrackingEventsCompanion.insert(
            id: id,
            type: type,
            timestamp: timestamp,
            duration: duration,
            notes: notes,
            wasteType: wasteType,
            color: color,
            babyId: babyId,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TrackingEventsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TrackingEventsTable,
    TrackingEvent,
    $$TrackingEventsTableFilterComposer,
    $$TrackingEventsTableOrderingComposer,
    $$TrackingEventsTableAnnotationComposer,
    $$TrackingEventsTableCreateCompanionBuilder,
    $$TrackingEventsTableUpdateCompanionBuilder,
    (
      TrackingEvent,
      BaseReferences<_$AppDatabase, $TrackingEventsTable, TrackingEvent>
    ),
    TrackingEvent,
    PrefetchHooks Function()>;
typedef $$ReminderDismissalsTableCreateCompanionBuilder
    = ReminderDismissalsCompanion Function({
  required String itemId,
  required DateTime dismissedAt,
  Value<int> rowid,
});
typedef $$ReminderDismissalsTableUpdateCompanionBuilder
    = ReminderDismissalsCompanion Function({
  Value<String> itemId,
  Value<DateTime> dismissedAt,
  Value<int> rowid,
});

class $$ReminderDismissalsTableFilterComposer
    extends Composer<_$AppDatabase, $ReminderDismissalsTable> {
  $$ReminderDismissalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get itemId => $composableBuilder(
      column: $table.itemId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dismissedAt => $composableBuilder(
      column: $table.dismissedAt, builder: (column) => ColumnFilters(column));
}

class $$ReminderDismissalsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReminderDismissalsTable> {
  $$ReminderDismissalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get itemId => $composableBuilder(
      column: $table.itemId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dismissedAt => $composableBuilder(
      column: $table.dismissedAt, builder: (column) => ColumnOrderings(column));
}

class $$ReminderDismissalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReminderDismissalsTable> {
  $$ReminderDismissalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<DateTime> get dismissedAt => $composableBuilder(
      column: $table.dismissedAt, builder: (column) => column);
}

class $$ReminderDismissalsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ReminderDismissalsTable,
    ReminderDismissal,
    $$ReminderDismissalsTableFilterComposer,
    $$ReminderDismissalsTableOrderingComposer,
    $$ReminderDismissalsTableAnnotationComposer,
    $$ReminderDismissalsTableCreateCompanionBuilder,
    $$ReminderDismissalsTableUpdateCompanionBuilder,
    (
      ReminderDismissal,
      BaseReferences<_$AppDatabase, $ReminderDismissalsTable, ReminderDismissal>
    ),
    ReminderDismissal,
    PrefetchHooks Function()> {
  $$ReminderDismissalsTableTableManager(
      _$AppDatabase db, $ReminderDismissalsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReminderDismissalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReminderDismissalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReminderDismissalsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> itemId = const Value.absent(),
            Value<DateTime> dismissedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ReminderDismissalsCompanion(
            itemId: itemId,
            dismissedAt: dismissedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String itemId,
            required DateTime dismissedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ReminderDismissalsCompanion.insert(
            itemId: itemId,
            dismissedAt: dismissedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ReminderDismissalsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ReminderDismissalsTable,
    ReminderDismissal,
    $$ReminderDismissalsTableFilterComposer,
    $$ReminderDismissalsTableOrderingComposer,
    $$ReminderDismissalsTableAnnotationComposer,
    $$ReminderDismissalsTableCreateCompanionBuilder,
    $$ReminderDismissalsTableUpdateCompanionBuilder,
    (
      ReminderDismissal,
      BaseReferences<_$AppDatabase, $ReminderDismissalsTable, ReminderDismissal>
    ),
    ReminderDismissal,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$BabyProfilesTableTableManager get babyProfiles =>
      $$BabyProfilesTableTableManager(_db, _db.babyProfiles);
  $$TrackingEventsTableTableManager get trackingEvents =>
      $$TrackingEventsTableTableManager(_db, _db.trackingEvents);
  $$ReminderDismissalsTableTableManager get reminderDismissals =>
      $$ReminderDismissalsTableTableManager(_db, _db.reminderDismissals);
}
