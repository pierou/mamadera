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
  static const VerificationMeta _subtypeMeta =
      const VerificationMeta('subtype');
  @override
  late final GeneratedColumn<String> subtype = GeneratedColumn<String>(
      'subtype', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
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
  static const VerificationMeta _textureMeta =
      const VerificationMeta('texture');
  @override
  late final GeneratedColumn<String> texture = GeneratedColumn<String>(
      'texture', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _babyIdMeta = const VerificationMeta('babyId');
  @override
  late final GeneratedColumn<String> babyId = GeneratedColumn<String>(
      'baby_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
      'quantity', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        type,
        timestamp,
        duration,
        subtype,
        notes,
        wasteType,
        color,
        texture,
        babyId,
        quantity
      ];
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
    if (data.containsKey('subtype')) {
      context.handle(_subtypeMeta,
          subtype.isAcceptableOrUnknown(data['subtype']!, _subtypeMeta));
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
    if (data.containsKey('texture')) {
      context.handle(_textureMeta,
          texture.isAcceptableOrUnknown(data['texture']!, _textureMeta));
    }
    if (data.containsKey('baby_id')) {
      context.handle(_babyIdMeta,
          babyId.isAcceptableOrUnknown(data['baby_id']!, _babyIdMeta));
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
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
      subtype: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subtype']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      wasteType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}waste_type']),
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color']),
      texture: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}texture']),
      babyId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}baby_id']),
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}quantity']),
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
  final String? subtype;
  final String? notes;
  final String? wasteType;
  final String? color;
  final String? texture;
  final String? babyId;
  final double? quantity;
  const TrackingEvent(
      {required this.id,
      required this.type,
      required this.timestamp,
      this.duration,
      this.subtype,
      this.notes,
      this.wasteType,
      this.color,
      this.texture,
      this.babyId,
      this.quantity});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['type'] = Variable<String>(type);
    map['timestamp'] = Variable<DateTime>(timestamp);
    if (!nullToAbsent || duration != null) {
      map['duration'] = Variable<double>(duration);
    }
    if (!nullToAbsent || subtype != null) {
      map['subtype'] = Variable<String>(subtype);
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
    if (!nullToAbsent || texture != null) {
      map['texture'] = Variable<String>(texture);
    }
    if (!nullToAbsent || babyId != null) {
      map['baby_id'] = Variable<String>(babyId);
    }
    if (!nullToAbsent || quantity != null) {
      map['quantity'] = Variable<double>(quantity);
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
      subtype: subtype == null && nullToAbsent
          ? const Value.absent()
          : Value(subtype),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      wasteType: wasteType == null && nullToAbsent
          ? const Value.absent()
          : Value(wasteType),
      color:
          color == null && nullToAbsent ? const Value.absent() : Value(color),
      texture: texture == null && nullToAbsent
          ? const Value.absent()
          : Value(texture),
      babyId:
          babyId == null && nullToAbsent ? const Value.absent() : Value(babyId),
      quantity: quantity == null && nullToAbsent
          ? const Value.absent()
          : Value(quantity),
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
      subtype: serializer.fromJson<String?>(json['subtype']),
      notes: serializer.fromJson<String?>(json['notes']),
      wasteType: serializer.fromJson<String?>(json['wasteType']),
      color: serializer.fromJson<String?>(json['color']),
      texture: serializer.fromJson<String?>(json['texture']),
      babyId: serializer.fromJson<String?>(json['babyId']),
      quantity: serializer.fromJson<double?>(json['quantity']),
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
      'subtype': serializer.toJson<String?>(subtype),
      'notes': serializer.toJson<String?>(notes),
      'wasteType': serializer.toJson<String?>(wasteType),
      'color': serializer.toJson<String?>(color),
      'texture': serializer.toJson<String?>(texture),
      'babyId': serializer.toJson<String?>(babyId),
      'quantity': serializer.toJson<double?>(quantity),
    };
  }

  TrackingEvent copyWith(
          {int? id,
          String? type,
          DateTime? timestamp,
          Value<double?> duration = const Value.absent(),
          Value<String?> subtype = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          Value<String?> wasteType = const Value.absent(),
          Value<String?> color = const Value.absent(),
          Value<String?> texture = const Value.absent(),
          Value<String?> babyId = const Value.absent(),
          Value<double?> quantity = const Value.absent()}) =>
      TrackingEvent(
        id: id ?? this.id,
        type: type ?? this.type,
        timestamp: timestamp ?? this.timestamp,
        duration: duration.present ? duration.value : this.duration,
        subtype: subtype.present ? subtype.value : this.subtype,
        notes: notes.present ? notes.value : this.notes,
        wasteType: wasteType.present ? wasteType.value : this.wasteType,
        color: color.present ? color.value : this.color,
        texture: texture.present ? texture.value : this.texture,
        babyId: babyId.present ? babyId.value : this.babyId,
        quantity: quantity.present ? quantity.value : this.quantity,
      );
  TrackingEvent copyWithCompanion(TrackingEventsCompanion data) {
    return TrackingEvent(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      duration: data.duration.present ? data.duration.value : this.duration,
      subtype: data.subtype.present ? data.subtype.value : this.subtype,
      notes: data.notes.present ? data.notes.value : this.notes,
      wasteType: data.wasteType.present ? data.wasteType.value : this.wasteType,
      color: data.color.present ? data.color.value : this.color,
      texture: data.texture.present ? data.texture.value : this.texture,
      babyId: data.babyId.present ? data.babyId.value : this.babyId,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrackingEvent(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('timestamp: $timestamp, ')
          ..write('duration: $duration, ')
          ..write('subtype: $subtype, ')
          ..write('notes: $notes, ')
          ..write('wasteType: $wasteType, ')
          ..write('color: $color, ')
          ..write('texture: $texture, ')
          ..write('babyId: $babyId, ')
          ..write('quantity: $quantity')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, type, timestamp, duration, subtype, notes,
      wasteType, color, texture, babyId, quantity);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrackingEvent &&
          other.id == this.id &&
          other.type == this.type &&
          other.timestamp == this.timestamp &&
          other.duration == this.duration &&
          other.subtype == this.subtype &&
          other.notes == this.notes &&
          other.wasteType == this.wasteType &&
          other.color == this.color &&
          other.texture == this.texture &&
          other.babyId == this.babyId &&
          other.quantity == this.quantity);
}

class TrackingEventsCompanion extends UpdateCompanion<TrackingEvent> {
  final Value<int> id;
  final Value<String> type;
  final Value<DateTime> timestamp;
  final Value<double?> duration;
  final Value<String?> subtype;
  final Value<String?> notes;
  final Value<String?> wasteType;
  final Value<String?> color;
  final Value<String?> texture;
  final Value<String?> babyId;
  final Value<double?> quantity;
  const TrackingEventsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.duration = const Value.absent(),
    this.subtype = const Value.absent(),
    this.notes = const Value.absent(),
    this.wasteType = const Value.absent(),
    this.color = const Value.absent(),
    this.texture = const Value.absent(),
    this.babyId = const Value.absent(),
    this.quantity = const Value.absent(),
  });
  TrackingEventsCompanion.insert({
    this.id = const Value.absent(),
    required String type,
    required DateTime timestamp,
    this.duration = const Value.absent(),
    this.subtype = const Value.absent(),
    this.notes = const Value.absent(),
    this.wasteType = const Value.absent(),
    this.color = const Value.absent(),
    this.texture = const Value.absent(),
    this.babyId = const Value.absent(),
    this.quantity = const Value.absent(),
  })  : type = Value(type),
        timestamp = Value(timestamp);
  static Insertable<TrackingEvent> custom({
    Expression<int>? id,
    Expression<String>? type,
    Expression<DateTime>? timestamp,
    Expression<double>? duration,
    Expression<String>? subtype,
    Expression<String>? notes,
    Expression<String>? wasteType,
    Expression<String>? color,
    Expression<String>? texture,
    Expression<String>? babyId,
    Expression<double>? quantity,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (timestamp != null) 'timestamp': timestamp,
      if (duration != null) 'duration': duration,
      if (subtype != null) 'subtype': subtype,
      if (notes != null) 'notes': notes,
      if (wasteType != null) 'waste_type': wasteType,
      if (color != null) 'color': color,
      if (texture != null) 'texture': texture,
      if (babyId != null) 'baby_id': babyId,
      if (quantity != null) 'quantity': quantity,
    });
  }

  TrackingEventsCompanion copyWith(
      {Value<int>? id,
      Value<String>? type,
      Value<DateTime>? timestamp,
      Value<double?>? duration,
      Value<String?>? subtype,
      Value<String?>? notes,
      Value<String?>? wasteType,
      Value<String?>? color,
      Value<String?>? texture,
      Value<String?>? babyId,
      Value<double?>? quantity}) {
    return TrackingEventsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      duration: duration ?? this.duration,
      subtype: subtype ?? this.subtype,
      notes: notes ?? this.notes,
      wasteType: wasteType ?? this.wasteType,
      color: color ?? this.color,
      texture: texture ?? this.texture,
      babyId: babyId ?? this.babyId,
      quantity: quantity ?? this.quantity,
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
    if (subtype.present) {
      map['subtype'] = Variable<String>(subtype.value);
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
    if (texture.present) {
      map['texture'] = Variable<String>(texture.value);
    }
    if (babyId.present) {
      map['baby_id'] = Variable<String>(babyId.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
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
          ..write('subtype: $subtype, ')
          ..write('notes: $notes, ')
          ..write('wasteType: $wasteType, ')
          ..write('color: $color, ')
          ..write('texture: $texture, ')
          ..write('babyId: $babyId, ')
          ..write('quantity: $quantity')
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
  static const VerificationMeta _babyIdMeta = const VerificationMeta('babyId');
  @override
  late final GeneratedColumn<String> babyId = GeneratedColumn<String>(
      'baby_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(db_const.sharedBabyId));
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
      'item_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dismissedAtMeta =
      const VerificationMeta('dismissedAt');
  @override
  late final GeneratedColumn<DateTime> dismissedAt = GeneratedColumn<DateTime>(
      'dismissed_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [babyId, itemId, dismissedAt];
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
    if (data.containsKey('baby_id')) {
      context.handle(_babyIdMeta,
          babyId.isAcceptableOrUnknown(data['baby_id']!, _babyIdMeta));
    }
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
  Set<GeneratedColumn> get $primaryKey => {babyId, itemId};
  @override
  ReminderDismissal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReminderDismissal(
      babyId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}baby_id'])!,
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
  /// NOT NULL, `''` = partagé entre tous les bébés (sentinelle [db_const.sharedBabyId]).
  final String babyId;
  final String itemId;
  final DateTime dismissedAt;
  const ReminderDismissal(
      {required this.babyId, required this.itemId, required this.dismissedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['baby_id'] = Variable<String>(babyId);
    map['item_id'] = Variable<String>(itemId);
    map['dismissed_at'] = Variable<DateTime>(dismissedAt);
    return map;
  }

  ReminderDismissalsCompanion toCompanion(bool nullToAbsent) {
    return ReminderDismissalsCompanion(
      babyId: Value(babyId),
      itemId: Value(itemId),
      dismissedAt: Value(dismissedAt),
    );
  }

  factory ReminderDismissal.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReminderDismissal(
      babyId: serializer.fromJson<String>(json['babyId']),
      itemId: serializer.fromJson<String>(json['itemId']),
      dismissedAt: serializer.fromJson<DateTime>(json['dismissedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'babyId': serializer.toJson<String>(babyId),
      'itemId': serializer.toJson<String>(itemId),
      'dismissedAt': serializer.toJson<DateTime>(dismissedAt),
    };
  }

  ReminderDismissal copyWith(
          {String? babyId, String? itemId, DateTime? dismissedAt}) =>
      ReminderDismissal(
        babyId: babyId ?? this.babyId,
        itemId: itemId ?? this.itemId,
        dismissedAt: dismissedAt ?? this.dismissedAt,
      );
  ReminderDismissal copyWithCompanion(ReminderDismissalsCompanion data) {
    return ReminderDismissal(
      babyId: data.babyId.present ? data.babyId.value : this.babyId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      dismissedAt:
          data.dismissedAt.present ? data.dismissedAt.value : this.dismissedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReminderDismissal(')
          ..write('babyId: $babyId, ')
          ..write('itemId: $itemId, ')
          ..write('dismissedAt: $dismissedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(babyId, itemId, dismissedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReminderDismissal &&
          other.babyId == this.babyId &&
          other.itemId == this.itemId &&
          other.dismissedAt == this.dismissedAt);
}

class ReminderDismissalsCompanion extends UpdateCompanion<ReminderDismissal> {
  final Value<String> babyId;
  final Value<String> itemId;
  final Value<DateTime> dismissedAt;
  final Value<int> rowid;
  const ReminderDismissalsCompanion({
    this.babyId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.dismissedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReminderDismissalsCompanion.insert({
    this.babyId = const Value.absent(),
    required String itemId,
    required DateTime dismissedAt,
    this.rowid = const Value.absent(),
  })  : itemId = Value(itemId),
        dismissedAt = Value(dismissedAt);
  static Insertable<ReminderDismissal> custom({
    Expression<String>? babyId,
    Expression<String>? itemId,
    Expression<DateTime>? dismissedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (babyId != null) 'baby_id': babyId,
      if (itemId != null) 'item_id': itemId,
      if (dismissedAt != null) 'dismissed_at': dismissedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReminderDismissalsCompanion copyWith(
      {Value<String>? babyId,
      Value<String>? itemId,
      Value<DateTime>? dismissedAt,
      Value<int>? rowid}) {
    return ReminderDismissalsCompanion(
      babyId: babyId ?? this.babyId,
      itemId: itemId ?? this.itemId,
      dismissedAt: dismissedAt ?? this.dismissedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (babyId.present) {
      map['baby_id'] = Variable<String>(babyId.value);
    }
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
          ..write('babyId: $babyId, ')
          ..write('itemId: $itemId, ')
          ..write('dismissedAt: $dismissedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReminderSettingsTable extends ReminderSettings
    with TableInfo<$ReminderSettingsTable, ReminderSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReminderSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _babyIdMeta = const VerificationMeta('babyId');
  @override
  late final GeneratedColumn<String> babyId = GeneratedColumn<String>(
      'baby_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(db_const.sharedBabyId));
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
      'item_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _enabledMeta =
      const VerificationMeta('enabled');
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
      'enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("enabled" IN (0, 1))'));
  @override
  List<GeneratedColumn> get $columns => [babyId, itemId, enabled];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminder_settings';
  @override
  VerificationContext validateIntegrity(Insertable<ReminderSetting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('baby_id')) {
      context.handle(_babyIdMeta,
          babyId.isAcceptableOrUnknown(data['baby_id']!, _babyIdMeta));
    }
    if (data.containsKey('item_id')) {
      context.handle(_itemIdMeta,
          itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta));
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('enabled')) {
      context.handle(_enabledMeta,
          enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta));
    } else if (isInserting) {
      context.missing(_enabledMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {babyId, itemId};
  @override
  ReminderSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReminderSetting(
      babyId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}baby_id'])!,
      itemId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}item_id'])!,
      enabled: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}enabled'])!,
    );
  }

  @override
  $ReminderSettingsTable createAlias(String alias) {
    return $ReminderSettingsTable(attachedDatabase, alias);
  }
}

class ReminderSetting extends DataClass implements Insertable<ReminderSetting> {
  /// NOT NULL, `''` = partagé entre tous les bébés (sentinelle [db_const.sharedBabyId]).
  final String babyId;
  final String itemId;
  final bool enabled;
  const ReminderSetting(
      {required this.babyId, required this.itemId, required this.enabled});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['baby_id'] = Variable<String>(babyId);
    map['item_id'] = Variable<String>(itemId);
    map['enabled'] = Variable<bool>(enabled);
    return map;
  }

  ReminderSettingsCompanion toCompanion(bool nullToAbsent) {
    return ReminderSettingsCompanion(
      babyId: Value(babyId),
      itemId: Value(itemId),
      enabled: Value(enabled),
    );
  }

  factory ReminderSetting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReminderSetting(
      babyId: serializer.fromJson<String>(json['babyId']),
      itemId: serializer.fromJson<String>(json['itemId']),
      enabled: serializer.fromJson<bool>(json['enabled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'babyId': serializer.toJson<String>(babyId),
      'itemId': serializer.toJson<String>(itemId),
      'enabled': serializer.toJson<bool>(enabled),
    };
  }

  ReminderSetting copyWith({String? babyId, String? itemId, bool? enabled}) =>
      ReminderSetting(
        babyId: babyId ?? this.babyId,
        itemId: itemId ?? this.itemId,
        enabled: enabled ?? this.enabled,
      );
  ReminderSetting copyWithCompanion(ReminderSettingsCompanion data) {
    return ReminderSetting(
      babyId: data.babyId.present ? data.babyId.value : this.babyId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReminderSetting(')
          ..write('babyId: $babyId, ')
          ..write('itemId: $itemId, ')
          ..write('enabled: $enabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(babyId, itemId, enabled);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReminderSetting &&
          other.babyId == this.babyId &&
          other.itemId == this.itemId &&
          other.enabled == this.enabled);
}

class ReminderSettingsCompanion extends UpdateCompanion<ReminderSetting> {
  final Value<String> babyId;
  final Value<String> itemId;
  final Value<bool> enabled;
  final Value<int> rowid;
  const ReminderSettingsCompanion({
    this.babyId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.enabled = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReminderSettingsCompanion.insert({
    this.babyId = const Value.absent(),
    required String itemId,
    required bool enabled,
    this.rowid = const Value.absent(),
  })  : itemId = Value(itemId),
        enabled = Value(enabled);
  static Insertable<ReminderSetting> custom({
    Expression<String>? babyId,
    Expression<String>? itemId,
    Expression<bool>? enabled,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (babyId != null) 'baby_id': babyId,
      if (itemId != null) 'item_id': itemId,
      if (enabled != null) 'enabled': enabled,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReminderSettingsCompanion copyWith(
      {Value<String>? babyId,
      Value<String>? itemId,
      Value<bool>? enabled,
      Value<int>? rowid}) {
    return ReminderSettingsCompanion(
      babyId: babyId ?? this.babyId,
      itemId: itemId ?? this.itemId,
      enabled: enabled ?? this.enabled,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (babyId.present) {
      map['baby_id'] = Variable<String>(babyId.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReminderSettingsCompanion(')
          ..write('babyId: $babyId, ')
          ..write('itemId: $itemId, ')
          ..write('enabled: $enabled, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CustomRemindersTable extends CustomReminders
    with TableInfo<$CustomRemindersTable, CustomReminder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomRemindersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _babyIdMeta = const VerificationMeta('babyId');
  @override
  late final GeneratedColumn<String> babyId = GeneratedColumn<String>(
      'baby_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(db_const.sharedBabyId));
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
      'label', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 60),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _subtypeValueMeta =
      const VerificationMeta('subtypeValue');
  @override
  late final GeneratedColumn<String> subtypeValue = GeneratedColumn<String>(
      'subtype_value', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _frequencyMeta =
      const VerificationMeta('frequency');
  @override
  late final GeneratedColumn<String> frequency = GeneratedColumn<String>(
      'frequency', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _intervalDaysMeta =
      const VerificationMeta('intervalDays');
  @override
  late final GeneratedColumn<int> intervalDays = GeneratedColumn<int>(
      'interval_days', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _completionSourceMeta =
      const VerificationMeta('completionSource');
  @override
  late final GeneratedColumn<String> completionSource = GeneratedColumn<String>(
      'completion_source', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(db_const.completionFromEvents));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        babyId,
        label,
        subtypeValue,
        frequency,
        intervalDays,
        completionSource
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'custom_reminders';
  @override
  VerificationContext validateIntegrity(Insertable<CustomReminder> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('baby_id')) {
      context.handle(_babyIdMeta,
          babyId.isAcceptableOrUnknown(data['baby_id']!, _babyIdMeta));
    }
    if (data.containsKey('label')) {
      context.handle(
          _labelMeta, label.isAcceptableOrUnknown(data['label']!, _labelMeta));
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('subtype_value')) {
      context.handle(
          _subtypeValueMeta,
          subtypeValue.isAcceptableOrUnknown(
              data['subtype_value']!, _subtypeValueMeta));
    }
    if (data.containsKey('frequency')) {
      context.handle(_frequencyMeta,
          frequency.isAcceptableOrUnknown(data['frequency']!, _frequencyMeta));
    } else if (isInserting) {
      context.missing(_frequencyMeta);
    }
    if (data.containsKey('interval_days')) {
      context.handle(
          _intervalDaysMeta,
          intervalDays.isAcceptableOrUnknown(
              data['interval_days']!, _intervalDaysMeta));
    }
    if (data.containsKey('completion_source')) {
      context.handle(
          _completionSourceMeta,
          completionSource.isAcceptableOrUnknown(
              data['completion_source']!, _completionSourceMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomReminder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomReminder(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      babyId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}baby_id'])!,
      label: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}label'])!,
      subtypeValue: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subtype_value']),
      frequency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}frequency'])!,
      intervalDays: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}interval_days']),
      completionSource: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}completion_source'])!,
    );
  }

  @override
  $CustomRemindersTable createAlias(String alias) {
    return $CustomRemindersTable(attachedDatabase, alias);
  }
}

class CustomReminder extends DataClass implements Insertable<CustomReminder> {
  final int id;

  /// NOT NULL, `''` = rappel valable pour tous les bébés (lecture honnête des
  /// lignes héritées de v10, où la table n'était pas scopée).
  final String babyId;
  final String label;

  /// Null = rappel **détaché** : aucun soin lié, achèvement manuel (D2).
  /// Valeur de `HealthSubtype` (`nettoyage_nez`, `nettoyage_nombril`, …) : le soin
  /// dont l'absence dans `tracking_events` rend le rappel dû.
  final String? subtypeValue;

  /// `daily` | `weekly` | `monthly` | `every_n_days` — voir [CustomReminder].
  final String frequency;

  /// Seulement pour `every_n_days` : longueur du roulement en jours.
  final int? intervalDays;

  /// `'from_events'` | `'manual'` — qui décide que le rappel est fait (D2).
  final String completionSource;
  const CustomReminder(
      {required this.id,
      required this.babyId,
      required this.label,
      this.subtypeValue,
      required this.frequency,
      this.intervalDays,
      required this.completionSource});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['baby_id'] = Variable<String>(babyId);
    map['label'] = Variable<String>(label);
    if (!nullToAbsent || subtypeValue != null) {
      map['subtype_value'] = Variable<String>(subtypeValue);
    }
    map['frequency'] = Variable<String>(frequency);
    if (!nullToAbsent || intervalDays != null) {
      map['interval_days'] = Variable<int>(intervalDays);
    }
    map['completion_source'] = Variable<String>(completionSource);
    return map;
  }

  CustomRemindersCompanion toCompanion(bool nullToAbsent) {
    return CustomRemindersCompanion(
      id: Value(id),
      babyId: Value(babyId),
      label: Value(label),
      subtypeValue: subtypeValue == null && nullToAbsent
          ? const Value.absent()
          : Value(subtypeValue),
      frequency: Value(frequency),
      intervalDays: intervalDays == null && nullToAbsent
          ? const Value.absent()
          : Value(intervalDays),
      completionSource: Value(completionSource),
    );
  }

  factory CustomReminder.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomReminder(
      id: serializer.fromJson<int>(json['id']),
      babyId: serializer.fromJson<String>(json['babyId']),
      label: serializer.fromJson<String>(json['label']),
      subtypeValue: serializer.fromJson<String?>(json['subtypeValue']),
      frequency: serializer.fromJson<String>(json['frequency']),
      intervalDays: serializer.fromJson<int?>(json['intervalDays']),
      completionSource: serializer.fromJson<String>(json['completionSource']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'babyId': serializer.toJson<String>(babyId),
      'label': serializer.toJson<String>(label),
      'subtypeValue': serializer.toJson<String?>(subtypeValue),
      'frequency': serializer.toJson<String>(frequency),
      'intervalDays': serializer.toJson<int?>(intervalDays),
      'completionSource': serializer.toJson<String>(completionSource),
    };
  }

  CustomReminder copyWith(
          {int? id,
          String? babyId,
          String? label,
          Value<String?> subtypeValue = const Value.absent(),
          String? frequency,
          Value<int?> intervalDays = const Value.absent(),
          String? completionSource}) =>
      CustomReminder(
        id: id ?? this.id,
        babyId: babyId ?? this.babyId,
        label: label ?? this.label,
        subtypeValue:
            subtypeValue.present ? subtypeValue.value : this.subtypeValue,
        frequency: frequency ?? this.frequency,
        intervalDays:
            intervalDays.present ? intervalDays.value : this.intervalDays,
        completionSource: completionSource ?? this.completionSource,
      );
  CustomReminder copyWithCompanion(CustomRemindersCompanion data) {
    return CustomReminder(
      id: data.id.present ? data.id.value : this.id,
      babyId: data.babyId.present ? data.babyId.value : this.babyId,
      label: data.label.present ? data.label.value : this.label,
      subtypeValue: data.subtypeValue.present
          ? data.subtypeValue.value
          : this.subtypeValue,
      frequency: data.frequency.present ? data.frequency.value : this.frequency,
      intervalDays: data.intervalDays.present
          ? data.intervalDays.value
          : this.intervalDays,
      completionSource: data.completionSource.present
          ? data.completionSource.value
          : this.completionSource,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomReminder(')
          ..write('id: $id, ')
          ..write('babyId: $babyId, ')
          ..write('label: $label, ')
          ..write('subtypeValue: $subtypeValue, ')
          ..write('frequency: $frequency, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('completionSource: $completionSource')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, babyId, label, subtypeValue, frequency,
      intervalDays, completionSource);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomReminder &&
          other.id == this.id &&
          other.babyId == this.babyId &&
          other.label == this.label &&
          other.subtypeValue == this.subtypeValue &&
          other.frequency == this.frequency &&
          other.intervalDays == this.intervalDays &&
          other.completionSource == this.completionSource);
}

class CustomRemindersCompanion extends UpdateCompanion<CustomReminder> {
  final Value<int> id;
  final Value<String> babyId;
  final Value<String> label;
  final Value<String?> subtypeValue;
  final Value<String> frequency;
  final Value<int?> intervalDays;
  final Value<String> completionSource;
  const CustomRemindersCompanion({
    this.id = const Value.absent(),
    this.babyId = const Value.absent(),
    this.label = const Value.absent(),
    this.subtypeValue = const Value.absent(),
    this.frequency = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.completionSource = const Value.absent(),
  });
  CustomRemindersCompanion.insert({
    this.id = const Value.absent(),
    this.babyId = const Value.absent(),
    required String label,
    this.subtypeValue = const Value.absent(),
    required String frequency,
    this.intervalDays = const Value.absent(),
    this.completionSource = const Value.absent(),
  })  : label = Value(label),
        frequency = Value(frequency);
  static Insertable<CustomReminder> custom({
    Expression<int>? id,
    Expression<String>? babyId,
    Expression<String>? label,
    Expression<String>? subtypeValue,
    Expression<String>? frequency,
    Expression<int>? intervalDays,
    Expression<String>? completionSource,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (babyId != null) 'baby_id': babyId,
      if (label != null) 'label': label,
      if (subtypeValue != null) 'subtype_value': subtypeValue,
      if (frequency != null) 'frequency': frequency,
      if (intervalDays != null) 'interval_days': intervalDays,
      if (completionSource != null) 'completion_source': completionSource,
    });
  }

  CustomRemindersCompanion copyWith(
      {Value<int>? id,
      Value<String>? babyId,
      Value<String>? label,
      Value<String?>? subtypeValue,
      Value<String>? frequency,
      Value<int?>? intervalDays,
      Value<String>? completionSource}) {
    return CustomRemindersCompanion(
      id: id ?? this.id,
      babyId: babyId ?? this.babyId,
      label: label ?? this.label,
      subtypeValue: subtypeValue ?? this.subtypeValue,
      frequency: frequency ?? this.frequency,
      intervalDays: intervalDays ?? this.intervalDays,
      completionSource: completionSource ?? this.completionSource,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (babyId.present) {
      map['baby_id'] = Variable<String>(babyId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (subtypeValue.present) {
      map['subtype_value'] = Variable<String>(subtypeValue.value);
    }
    if (frequency.present) {
      map['frequency'] = Variable<String>(frequency.value);
    }
    if (intervalDays.present) {
      map['interval_days'] = Variable<int>(intervalDays.value);
    }
    if (completionSource.present) {
      map['completion_source'] = Variable<String>(completionSource.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomRemindersCompanion(')
          ..write('id: $id, ')
          ..write('babyId: $babyId, ')
          ..write('label: $label, ')
          ..write('subtypeValue: $subtypeValue, ')
          ..write('frequency: $frequency, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('completionSource: $completionSource')
          ..write(')'))
        .toString();
  }
}

class $MeasurementsTable extends Measurements
    with TableInfo<$MeasurementsTable, Measurement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MeasurementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _babyIdMeta = const VerificationMeta('babyId');
  @override
  late final GeneratedColumn<String> babyId = GeneratedColumn<String>(
      'baby_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
      'unit', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _recordedAtMeta =
      const VerificationMeta('recordedAt');
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
      'recorded_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, babyId, kind, value, unit, recordedAt, notes];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'measurements';
  @override
  VerificationContext validateIntegrity(Insertable<Measurement> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('baby_id')) {
      context.handle(_babyIdMeta,
          babyId.isAcceptableOrUnknown(data['baby_id']!, _babyIdMeta));
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
          _unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
          _recordedAtMeta,
          recordedAt.isAcceptableOrUnknown(
              data['recorded_at']!, _recordedAtMeta));
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Measurement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Measurement(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      babyId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}baby_id']),
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
      unit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit'])!,
      recordedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}recorded_at'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
    );
  }

  @override
  $MeasurementsTable createAlias(String alias) {
    return $MeasurementsTable(attachedDatabase, alias);
  }
}

class Measurement extends DataClass implements Insertable<Measurement> {
  final int id;

  /// Nullable, comme `tracking_events.baby_id` : un suivi sans profil reste lisible.
  final String? babyId;
  final String kind;
  final String value;
  final String unit;
  final DateTime recordedAt;
  final String? notes;
  const Measurement(
      {required this.id,
      this.babyId,
      required this.kind,
      required this.value,
      required this.unit,
      required this.recordedAt,
      this.notes});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || babyId != null) {
      map['baby_id'] = Variable<String>(babyId);
    }
    map['kind'] = Variable<String>(kind);
    map['value'] = Variable<String>(value);
    map['unit'] = Variable<String>(unit);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  MeasurementsCompanion toCompanion(bool nullToAbsent) {
    return MeasurementsCompanion(
      id: Value(id),
      babyId:
          babyId == null && nullToAbsent ? const Value.absent() : Value(babyId),
      kind: Value(kind),
      value: Value(value),
      unit: Value(unit),
      recordedAt: Value(recordedAt),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
    );
  }

  factory Measurement.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Measurement(
      id: serializer.fromJson<int>(json['id']),
      babyId: serializer.fromJson<String?>(json['babyId']),
      kind: serializer.fromJson<String>(json['kind']),
      value: serializer.fromJson<String>(json['value']),
      unit: serializer.fromJson<String>(json['unit']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'babyId': serializer.toJson<String?>(babyId),
      'kind': serializer.toJson<String>(kind),
      'value': serializer.toJson<String>(value),
      'unit': serializer.toJson<String>(unit),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  Measurement copyWith(
          {int? id,
          Value<String?> babyId = const Value.absent(),
          String? kind,
          String? value,
          String? unit,
          DateTime? recordedAt,
          Value<String?> notes = const Value.absent()}) =>
      Measurement(
        id: id ?? this.id,
        babyId: babyId.present ? babyId.value : this.babyId,
        kind: kind ?? this.kind,
        value: value ?? this.value,
        unit: unit ?? this.unit,
        recordedAt: recordedAt ?? this.recordedAt,
        notes: notes.present ? notes.value : this.notes,
      );
  Measurement copyWithCompanion(MeasurementsCompanion data) {
    return Measurement(
      id: data.id.present ? data.id.value : this.id,
      babyId: data.babyId.present ? data.babyId.value : this.babyId,
      kind: data.kind.present ? data.kind.value : this.kind,
      value: data.value.present ? data.value.value : this.value,
      unit: data.unit.present ? data.unit.value : this.unit,
      recordedAt:
          data.recordedAt.present ? data.recordedAt.value : this.recordedAt,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Measurement(')
          ..write('id: $id, ')
          ..write('babyId: $babyId, ')
          ..write('kind: $kind, ')
          ..write('value: $value, ')
          ..write('unit: $unit, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, babyId, kind, value, unit, recordedAt, notes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Measurement &&
          other.id == this.id &&
          other.babyId == this.babyId &&
          other.kind == this.kind &&
          other.value == this.value &&
          other.unit == this.unit &&
          other.recordedAt == this.recordedAt &&
          other.notes == this.notes);
}

class MeasurementsCompanion extends UpdateCompanion<Measurement> {
  final Value<int> id;
  final Value<String?> babyId;
  final Value<String> kind;
  final Value<String> value;
  final Value<String> unit;
  final Value<DateTime> recordedAt;
  final Value<String?> notes;
  const MeasurementsCompanion({
    this.id = const Value.absent(),
    this.babyId = const Value.absent(),
    this.kind = const Value.absent(),
    this.value = const Value.absent(),
    this.unit = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.notes = const Value.absent(),
  });
  MeasurementsCompanion.insert({
    this.id = const Value.absent(),
    this.babyId = const Value.absent(),
    required String kind,
    required String value,
    required String unit,
    required DateTime recordedAt,
    this.notes = const Value.absent(),
  })  : kind = Value(kind),
        value = Value(value),
        unit = Value(unit),
        recordedAt = Value(recordedAt);
  static Insertable<Measurement> custom({
    Expression<int>? id,
    Expression<String>? babyId,
    Expression<String>? kind,
    Expression<String>? value,
    Expression<String>? unit,
    Expression<DateTime>? recordedAt,
    Expression<String>? notes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (babyId != null) 'baby_id': babyId,
      if (kind != null) 'kind': kind,
      if (value != null) 'value': value,
      if (unit != null) 'unit': unit,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (notes != null) 'notes': notes,
    });
  }

  MeasurementsCompanion copyWith(
      {Value<int>? id,
      Value<String?>? babyId,
      Value<String>? kind,
      Value<String>? value,
      Value<String>? unit,
      Value<DateTime>? recordedAt,
      Value<String?>? notes}) {
    return MeasurementsCompanion(
      id: id ?? this.id,
      babyId: babyId ?? this.babyId,
      kind: kind ?? this.kind,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      recordedAt: recordedAt ?? this.recordedAt,
      notes: notes ?? this.notes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (babyId.present) {
      map['baby_id'] = Variable<String>(babyId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MeasurementsCompanion(')
          ..write('id: $id, ')
          ..write('babyId: $babyId, ')
          ..write('kind: $kind, ')
          ..write('value: $value, ')
          ..write('unit: $unit, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }
}

class $ReminderCompletionsTable extends ReminderCompletions
    with TableInfo<$ReminderCompletionsTable, ReminderCompletion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReminderCompletionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _babyIdMeta = const VerificationMeta('babyId');
  @override
  late final GeneratedColumn<String> babyId = GeneratedColumn<String>(
      'baby_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(db_const.sharedBabyId));
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
      'item_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
      'completed_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, babyId, itemId, completedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminder_completions';
  @override
  VerificationContext validateIntegrity(Insertable<ReminderCompletion> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('baby_id')) {
      context.handle(_babyIdMeta,
          babyId.isAcceptableOrUnknown(data['baby_id']!, _babyIdMeta));
    }
    if (data.containsKey('item_id')) {
      context.handle(_itemIdMeta,
          itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta));
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completed_at']!, _completedAtMeta));
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReminderCompletion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReminderCompletion(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      babyId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}baby_id'])!,
      itemId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}item_id'])!,
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}completed_at'])!,
    );
  }

  @override
  $ReminderCompletionsTable createAlias(String alias) {
    return $ReminderCompletionsTable(attachedDatabase, alias);
  }
}

class ReminderCompletion extends DataClass
    implements Insertable<ReminderCompletion> {
  final int id;
  final String babyId;
  final String itemId;
  final DateTime completedAt;
  const ReminderCompletion(
      {required this.id,
      required this.babyId,
      required this.itemId,
      required this.completedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['baby_id'] = Variable<String>(babyId);
    map['item_id'] = Variable<String>(itemId);
    map['completed_at'] = Variable<DateTime>(completedAt);
    return map;
  }

  ReminderCompletionsCompanion toCompanion(bool nullToAbsent) {
    return ReminderCompletionsCompanion(
      id: Value(id),
      babyId: Value(babyId),
      itemId: Value(itemId),
      completedAt: Value(completedAt),
    );
  }

  factory ReminderCompletion.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReminderCompletion(
      id: serializer.fromJson<int>(json['id']),
      babyId: serializer.fromJson<String>(json['babyId']),
      itemId: serializer.fromJson<String>(json['itemId']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'babyId': serializer.toJson<String>(babyId),
      'itemId': serializer.toJson<String>(itemId),
      'completedAt': serializer.toJson<DateTime>(completedAt),
    };
  }

  ReminderCompletion copyWith(
          {int? id, String? babyId, String? itemId, DateTime? completedAt}) =>
      ReminderCompletion(
        id: id ?? this.id,
        babyId: babyId ?? this.babyId,
        itemId: itemId ?? this.itemId,
        completedAt: completedAt ?? this.completedAt,
      );
  ReminderCompletion copyWithCompanion(ReminderCompletionsCompanion data) {
    return ReminderCompletion(
      id: data.id.present ? data.id.value : this.id,
      babyId: data.babyId.present ? data.babyId.value : this.babyId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReminderCompletion(')
          ..write('id: $id, ')
          ..write('babyId: $babyId, ')
          ..write('itemId: $itemId, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, babyId, itemId, completedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReminderCompletion &&
          other.id == this.id &&
          other.babyId == this.babyId &&
          other.itemId == this.itemId &&
          other.completedAt == this.completedAt);
}

class ReminderCompletionsCompanion extends UpdateCompanion<ReminderCompletion> {
  final Value<int> id;
  final Value<String> babyId;
  final Value<String> itemId;
  final Value<DateTime> completedAt;
  const ReminderCompletionsCompanion({
    this.id = const Value.absent(),
    this.babyId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.completedAt = const Value.absent(),
  });
  ReminderCompletionsCompanion.insert({
    this.id = const Value.absent(),
    this.babyId = const Value.absent(),
    required String itemId,
    required DateTime completedAt,
  })  : itemId = Value(itemId),
        completedAt = Value(completedAt);
  static Insertable<ReminderCompletion> custom({
    Expression<int>? id,
    Expression<String>? babyId,
    Expression<String>? itemId,
    Expression<DateTime>? completedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (babyId != null) 'baby_id': babyId,
      if (itemId != null) 'item_id': itemId,
      if (completedAt != null) 'completed_at': completedAt,
    });
  }

  ReminderCompletionsCompanion copyWith(
      {Value<int>? id,
      Value<String>? babyId,
      Value<String>? itemId,
      Value<DateTime>? completedAt}) {
    return ReminderCompletionsCompanion(
      id: id ?? this.id,
      babyId: babyId ?? this.babyId,
      itemId: itemId ?? this.itemId,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (babyId.present) {
      map['baby_id'] = Variable<String>(babyId.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReminderCompletionsCompanion(')
          ..write('id: $id, ')
          ..write('babyId: $babyId, ')
          ..write('itemId: $itemId, ')
          ..write('completedAt: $completedAt')
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
  late final $ReminderSettingsTable reminderSettings =
      $ReminderSettingsTable(this);
  late final $CustomRemindersTable customReminders =
      $CustomRemindersTable(this);
  late final $MeasurementsTable measurements = $MeasurementsTable(this);
  late final $ReminderCompletionsTable reminderCompletions =
      $ReminderCompletionsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        babyProfiles,
        trackingEvents,
        reminderDismissals,
        reminderSettings,
        customReminders,
        measurements,
        reminderCompletions
      ];
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
  Value<String?> subtype,
  Value<String?> notes,
  Value<String?> wasteType,
  Value<String?> color,
  Value<String?> texture,
  Value<String?> babyId,
  Value<double?> quantity,
});
typedef $$TrackingEventsTableUpdateCompanionBuilder = TrackingEventsCompanion
    Function({
  Value<int> id,
  Value<String> type,
  Value<DateTime> timestamp,
  Value<double?> duration,
  Value<String?> subtype,
  Value<String?> notes,
  Value<String?> wasteType,
  Value<String?> color,
  Value<String?> texture,
  Value<String?> babyId,
  Value<double?> quantity,
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

  ColumnFilters<String> get subtype => $composableBuilder(
      column: $table.subtype, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get wasteType => $composableBuilder(
      column: $table.wasteType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get texture => $composableBuilder(
      column: $table.texture, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get babyId => $composableBuilder(
      column: $table.babyId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnFilters(column));
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

  ColumnOrderings<String> get subtype => $composableBuilder(
      column: $table.subtype, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get wasteType => $composableBuilder(
      column: $table.wasteType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get texture => $composableBuilder(
      column: $table.texture, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get babyId => $composableBuilder(
      column: $table.babyId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnOrderings(column));
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

  GeneratedColumn<String> get subtype =>
      $composableBuilder(column: $table.subtype, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get wasteType =>
      $composableBuilder(column: $table.wasteType, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get texture =>
      $composableBuilder(column: $table.texture, builder: (column) => column);

  GeneratedColumn<String> get babyId =>
      $composableBuilder(column: $table.babyId, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);
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
            Value<String?> subtype = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String?> wasteType = const Value.absent(),
            Value<String?> color = const Value.absent(),
            Value<String?> texture = const Value.absent(),
            Value<String?> babyId = const Value.absent(),
            Value<double?> quantity = const Value.absent(),
          }) =>
              TrackingEventsCompanion(
            id: id,
            type: type,
            timestamp: timestamp,
            duration: duration,
            subtype: subtype,
            notes: notes,
            wasteType: wasteType,
            color: color,
            texture: texture,
            babyId: babyId,
            quantity: quantity,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String type,
            required DateTime timestamp,
            Value<double?> duration = const Value.absent(),
            Value<String?> subtype = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String?> wasteType = const Value.absent(),
            Value<String?> color = const Value.absent(),
            Value<String?> texture = const Value.absent(),
            Value<String?> babyId = const Value.absent(),
            Value<double?> quantity = const Value.absent(),
          }) =>
              TrackingEventsCompanion.insert(
            id: id,
            type: type,
            timestamp: timestamp,
            duration: duration,
            subtype: subtype,
            notes: notes,
            wasteType: wasteType,
            color: color,
            texture: texture,
            babyId: babyId,
            quantity: quantity,
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
  Value<String> babyId,
  required String itemId,
  required DateTime dismissedAt,
  Value<int> rowid,
});
typedef $$ReminderDismissalsTableUpdateCompanionBuilder
    = ReminderDismissalsCompanion Function({
  Value<String> babyId,
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
  ColumnFilters<String> get babyId => $composableBuilder(
      column: $table.babyId, builder: (column) => ColumnFilters(column));

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
  ColumnOrderings<String> get babyId => $composableBuilder(
      column: $table.babyId, builder: (column) => ColumnOrderings(column));

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
  GeneratedColumn<String> get babyId =>
      $composableBuilder(column: $table.babyId, builder: (column) => column);

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
            Value<String> babyId = const Value.absent(),
            Value<String> itemId = const Value.absent(),
            Value<DateTime> dismissedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ReminderDismissalsCompanion(
            babyId: babyId,
            itemId: itemId,
            dismissedAt: dismissedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<String> babyId = const Value.absent(),
            required String itemId,
            required DateTime dismissedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ReminderDismissalsCompanion.insert(
            babyId: babyId,
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
typedef $$ReminderSettingsTableCreateCompanionBuilder
    = ReminderSettingsCompanion Function({
  Value<String> babyId,
  required String itemId,
  required bool enabled,
  Value<int> rowid,
});
typedef $$ReminderSettingsTableUpdateCompanionBuilder
    = ReminderSettingsCompanion Function({
  Value<String> babyId,
  Value<String> itemId,
  Value<bool> enabled,
  Value<int> rowid,
});

class $$ReminderSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $ReminderSettingsTable> {
  $$ReminderSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get babyId => $composableBuilder(
      column: $table.babyId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get itemId => $composableBuilder(
      column: $table.itemId, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get enabled => $composableBuilder(
      column: $table.enabled, builder: (column) => ColumnFilters(column));
}

class $$ReminderSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReminderSettingsTable> {
  $$ReminderSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get babyId => $composableBuilder(
      column: $table.babyId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get itemId => $composableBuilder(
      column: $table.itemId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get enabled => $composableBuilder(
      column: $table.enabled, builder: (column) => ColumnOrderings(column));
}

class $$ReminderSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReminderSettingsTable> {
  $$ReminderSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get babyId =>
      $composableBuilder(column: $table.babyId, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);
}

class $$ReminderSettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ReminderSettingsTable,
    ReminderSetting,
    $$ReminderSettingsTableFilterComposer,
    $$ReminderSettingsTableOrderingComposer,
    $$ReminderSettingsTableAnnotationComposer,
    $$ReminderSettingsTableCreateCompanionBuilder,
    $$ReminderSettingsTableUpdateCompanionBuilder,
    (
      ReminderSetting,
      BaseReferences<_$AppDatabase, $ReminderSettingsTable, ReminderSetting>
    ),
    ReminderSetting,
    PrefetchHooks Function()> {
  $$ReminderSettingsTableTableManager(
      _$AppDatabase db, $ReminderSettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReminderSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReminderSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReminderSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> babyId = const Value.absent(),
            Value<String> itemId = const Value.absent(),
            Value<bool> enabled = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ReminderSettingsCompanion(
            babyId: babyId,
            itemId: itemId,
            enabled: enabled,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<String> babyId = const Value.absent(),
            required String itemId,
            required bool enabled,
            Value<int> rowid = const Value.absent(),
          }) =>
              ReminderSettingsCompanion.insert(
            babyId: babyId,
            itemId: itemId,
            enabled: enabled,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ReminderSettingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ReminderSettingsTable,
    ReminderSetting,
    $$ReminderSettingsTableFilterComposer,
    $$ReminderSettingsTableOrderingComposer,
    $$ReminderSettingsTableAnnotationComposer,
    $$ReminderSettingsTableCreateCompanionBuilder,
    $$ReminderSettingsTableUpdateCompanionBuilder,
    (
      ReminderSetting,
      BaseReferences<_$AppDatabase, $ReminderSettingsTable, ReminderSetting>
    ),
    ReminderSetting,
    PrefetchHooks Function()>;
typedef $$CustomRemindersTableCreateCompanionBuilder = CustomRemindersCompanion
    Function({
  Value<int> id,
  Value<String> babyId,
  required String label,
  Value<String?> subtypeValue,
  required String frequency,
  Value<int?> intervalDays,
  Value<String> completionSource,
});
typedef $$CustomRemindersTableUpdateCompanionBuilder = CustomRemindersCompanion
    Function({
  Value<int> id,
  Value<String> babyId,
  Value<String> label,
  Value<String?> subtypeValue,
  Value<String> frequency,
  Value<int?> intervalDays,
  Value<String> completionSource,
});

class $$CustomRemindersTableFilterComposer
    extends Composer<_$AppDatabase, $CustomRemindersTable> {
  $$CustomRemindersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get babyId => $composableBuilder(
      column: $table.babyId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subtypeValue => $composableBuilder(
      column: $table.subtypeValue, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get frequency => $composableBuilder(
      column: $table.frequency, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get intervalDays => $composableBuilder(
      column: $table.intervalDays, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get completionSource => $composableBuilder(
      column: $table.completionSource,
      builder: (column) => ColumnFilters(column));
}

class $$CustomRemindersTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomRemindersTable> {
  $$CustomRemindersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get babyId => $composableBuilder(
      column: $table.babyId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subtypeValue => $composableBuilder(
      column: $table.subtypeValue,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get frequency => $composableBuilder(
      column: $table.frequency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get intervalDays => $composableBuilder(
      column: $table.intervalDays,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get completionSource => $composableBuilder(
      column: $table.completionSource,
      builder: (column) => ColumnOrderings(column));
}

class $$CustomRemindersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomRemindersTable> {
  $$CustomRemindersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get babyId =>
      $composableBuilder(column: $table.babyId, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get subtypeValue => $composableBuilder(
      column: $table.subtypeValue, builder: (column) => column);

  GeneratedColumn<String> get frequency =>
      $composableBuilder(column: $table.frequency, builder: (column) => column);

  GeneratedColumn<int> get intervalDays => $composableBuilder(
      column: $table.intervalDays, builder: (column) => column);

  GeneratedColumn<String> get completionSource => $composableBuilder(
      column: $table.completionSource, builder: (column) => column);
}

class $$CustomRemindersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CustomRemindersTable,
    CustomReminder,
    $$CustomRemindersTableFilterComposer,
    $$CustomRemindersTableOrderingComposer,
    $$CustomRemindersTableAnnotationComposer,
    $$CustomRemindersTableCreateCompanionBuilder,
    $$CustomRemindersTableUpdateCompanionBuilder,
    (
      CustomReminder,
      BaseReferences<_$AppDatabase, $CustomRemindersTable, CustomReminder>
    ),
    CustomReminder,
    PrefetchHooks Function()> {
  $$CustomRemindersTableTableManager(
      _$AppDatabase db, $CustomRemindersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomRemindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomRemindersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomRemindersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> babyId = const Value.absent(),
            Value<String> label = const Value.absent(),
            Value<String?> subtypeValue = const Value.absent(),
            Value<String> frequency = const Value.absent(),
            Value<int?> intervalDays = const Value.absent(),
            Value<String> completionSource = const Value.absent(),
          }) =>
              CustomRemindersCompanion(
            id: id,
            babyId: babyId,
            label: label,
            subtypeValue: subtypeValue,
            frequency: frequency,
            intervalDays: intervalDays,
            completionSource: completionSource,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> babyId = const Value.absent(),
            required String label,
            Value<String?> subtypeValue = const Value.absent(),
            required String frequency,
            Value<int?> intervalDays = const Value.absent(),
            Value<String> completionSource = const Value.absent(),
          }) =>
              CustomRemindersCompanion.insert(
            id: id,
            babyId: babyId,
            label: label,
            subtypeValue: subtypeValue,
            frequency: frequency,
            intervalDays: intervalDays,
            completionSource: completionSource,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CustomRemindersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CustomRemindersTable,
    CustomReminder,
    $$CustomRemindersTableFilterComposer,
    $$CustomRemindersTableOrderingComposer,
    $$CustomRemindersTableAnnotationComposer,
    $$CustomRemindersTableCreateCompanionBuilder,
    $$CustomRemindersTableUpdateCompanionBuilder,
    (
      CustomReminder,
      BaseReferences<_$AppDatabase, $CustomRemindersTable, CustomReminder>
    ),
    CustomReminder,
    PrefetchHooks Function()>;
typedef $$MeasurementsTableCreateCompanionBuilder = MeasurementsCompanion
    Function({
  Value<int> id,
  Value<String?> babyId,
  required String kind,
  required String value,
  required String unit,
  required DateTime recordedAt,
  Value<String?> notes,
});
typedef $$MeasurementsTableUpdateCompanionBuilder = MeasurementsCompanion
    Function({
  Value<int> id,
  Value<String?> babyId,
  Value<String> kind,
  Value<String> value,
  Value<String> unit,
  Value<DateTime> recordedAt,
  Value<String?> notes,
});

class $$MeasurementsTableFilterComposer
    extends Composer<_$AppDatabase, $MeasurementsTable> {
  $$MeasurementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get babyId => $composableBuilder(
      column: $table.babyId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));
}

class $$MeasurementsTableOrderingComposer
    extends Composer<_$AppDatabase, $MeasurementsTable> {
  $$MeasurementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get babyId => $composableBuilder(
      column: $table.babyId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));
}

class $$MeasurementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MeasurementsTable> {
  $$MeasurementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get babyId =>
      $composableBuilder(column: $table.babyId, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $$MeasurementsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MeasurementsTable,
    Measurement,
    $$MeasurementsTableFilterComposer,
    $$MeasurementsTableOrderingComposer,
    $$MeasurementsTableAnnotationComposer,
    $$MeasurementsTableCreateCompanionBuilder,
    $$MeasurementsTableUpdateCompanionBuilder,
    (
      Measurement,
      BaseReferences<_$AppDatabase, $MeasurementsTable, Measurement>
    ),
    Measurement,
    PrefetchHooks Function()> {
  $$MeasurementsTableTableManager(_$AppDatabase db, $MeasurementsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MeasurementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MeasurementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MeasurementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> babyId = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<String> unit = const Value.absent(),
            Value<DateTime> recordedAt = const Value.absent(),
            Value<String?> notes = const Value.absent(),
          }) =>
              MeasurementsCompanion(
            id: id,
            babyId: babyId,
            kind: kind,
            value: value,
            unit: unit,
            recordedAt: recordedAt,
            notes: notes,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> babyId = const Value.absent(),
            required String kind,
            required String value,
            required String unit,
            required DateTime recordedAt,
            Value<String?> notes = const Value.absent(),
          }) =>
              MeasurementsCompanion.insert(
            id: id,
            babyId: babyId,
            kind: kind,
            value: value,
            unit: unit,
            recordedAt: recordedAt,
            notes: notes,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MeasurementsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MeasurementsTable,
    Measurement,
    $$MeasurementsTableFilterComposer,
    $$MeasurementsTableOrderingComposer,
    $$MeasurementsTableAnnotationComposer,
    $$MeasurementsTableCreateCompanionBuilder,
    $$MeasurementsTableUpdateCompanionBuilder,
    (
      Measurement,
      BaseReferences<_$AppDatabase, $MeasurementsTable, Measurement>
    ),
    Measurement,
    PrefetchHooks Function()>;
typedef $$ReminderCompletionsTableCreateCompanionBuilder
    = ReminderCompletionsCompanion Function({
  Value<int> id,
  Value<String> babyId,
  required String itemId,
  required DateTime completedAt,
});
typedef $$ReminderCompletionsTableUpdateCompanionBuilder
    = ReminderCompletionsCompanion Function({
  Value<int> id,
  Value<String> babyId,
  Value<String> itemId,
  Value<DateTime> completedAt,
});

class $$ReminderCompletionsTableFilterComposer
    extends Composer<_$AppDatabase, $ReminderCompletionsTable> {
  $$ReminderCompletionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get babyId => $composableBuilder(
      column: $table.babyId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get itemId => $composableBuilder(
      column: $table.itemId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnFilters(column));
}

class $$ReminderCompletionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReminderCompletionsTable> {
  $$ReminderCompletionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get babyId => $composableBuilder(
      column: $table.babyId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get itemId => $composableBuilder(
      column: $table.itemId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnOrderings(column));
}

class $$ReminderCompletionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReminderCompletionsTable> {
  $$ReminderCompletionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get babyId =>
      $composableBuilder(column: $table.babyId, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => column);
}

class $$ReminderCompletionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ReminderCompletionsTable,
    ReminderCompletion,
    $$ReminderCompletionsTableFilterComposer,
    $$ReminderCompletionsTableOrderingComposer,
    $$ReminderCompletionsTableAnnotationComposer,
    $$ReminderCompletionsTableCreateCompanionBuilder,
    $$ReminderCompletionsTableUpdateCompanionBuilder,
    (
      ReminderCompletion,
      BaseReferences<_$AppDatabase, $ReminderCompletionsTable,
          ReminderCompletion>
    ),
    ReminderCompletion,
    PrefetchHooks Function()> {
  $$ReminderCompletionsTableTableManager(
      _$AppDatabase db, $ReminderCompletionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReminderCompletionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReminderCompletionsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReminderCompletionsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> babyId = const Value.absent(),
            Value<String> itemId = const Value.absent(),
            Value<DateTime> completedAt = const Value.absent(),
          }) =>
              ReminderCompletionsCompanion(
            id: id,
            babyId: babyId,
            itemId: itemId,
            completedAt: completedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> babyId = const Value.absent(),
            required String itemId,
            required DateTime completedAt,
          }) =>
              ReminderCompletionsCompanion.insert(
            id: id,
            babyId: babyId,
            itemId: itemId,
            completedAt: completedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ReminderCompletionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ReminderCompletionsTable,
    ReminderCompletion,
    $$ReminderCompletionsTableFilterComposer,
    $$ReminderCompletionsTableOrderingComposer,
    $$ReminderCompletionsTableAnnotationComposer,
    $$ReminderCompletionsTableCreateCompanionBuilder,
    $$ReminderCompletionsTableUpdateCompanionBuilder,
    (
      ReminderCompletion,
      BaseReferences<_$AppDatabase, $ReminderCompletionsTable,
          ReminderCompletion>
    ),
    ReminderCompletion,
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
  $$ReminderSettingsTableTableManager get reminderSettings =>
      $$ReminderSettingsTableTableManager(_db, _db.reminderSettings);
  $$CustomRemindersTableTableManager get customReminders =>
      $$CustomRemindersTableTableManager(_db, _db.customReminders);
  $$MeasurementsTableTableManager get measurements =>
      $$MeasurementsTableTableManager(_db, _db.measurements);
  $$ReminderCompletionsTableTableManager get reminderCompletions =>
      $$ReminderCompletionsTableTableManager(_db, _db.reminderCompletions);
}
