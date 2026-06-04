// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_db.dart';

// ignore_for_file: type=lint
class $TrackingEventsTable extends TrackingEvents
    with TableInfo<$TrackingEventsTable, TrackingEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrackingEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMeta = const VerificationMeta(
    'duration',
  );
  @override
  late final GeneratedColumn<double> duration = GeneratedColumn<double>(
    'duration',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, type, timestamp, duration, notes];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tracking_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<TrackingEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('duration')) {
      context.handle(
        _durationMeta,
        duration.isAcceptableOrUnknown(data['duration']!, _durationMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TrackingEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrackingEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      duration: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}duration'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
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
  const TrackingEvent({
    required this.id,
    required this.type,
    required this.timestamp,
    this.duration,
    this.notes,
  });
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
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory TrackingEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrackingEvent(
      id: serializer.fromJson<int>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      duration: serializer.fromJson<double?>(json['duration']),
      notes: serializer.fromJson<String?>(json['notes']),
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
    };
  }

  TrackingEvent copyWith({
    int? id,
    String? type,
    DateTime? timestamp,
    Value<double?> duration = const Value.absent(),
    Value<String?> notes = const Value.absent(),
  }) => TrackingEvent(
    id: id ?? this.id,
    type: type ?? this.type,
    timestamp: timestamp ?? this.timestamp,
    duration: duration.present ? duration.value : this.duration,
    notes: notes.present ? notes.value : this.notes,
  );
  TrackingEvent copyWithCompanion(TrackingEventsCompanion data) {
    return TrackingEvent(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      duration: data.duration.present ? data.duration.value : this.duration,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrackingEvent(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('timestamp: $timestamp, ')
          ..write('duration: $duration, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, type, timestamp, duration, notes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrackingEvent &&
          other.id == this.id &&
          other.type == this.type &&
          other.timestamp == this.timestamp &&
          other.duration == this.duration &&
          other.notes == this.notes);
}

class TrackingEventsCompanion extends UpdateCompanion<TrackingEvent> {
  final Value<int> id;
  final Value<String> type;
  final Value<DateTime> timestamp;
  final Value<double?> duration;
  final Value<String?> notes;
  const TrackingEventsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.duration = const Value.absent(),
    this.notes = const Value.absent(),
  });
  TrackingEventsCompanion.insert({
    this.id = const Value.absent(),
    required String type,
    required DateTime timestamp,
    this.duration = const Value.absent(),
    this.notes = const Value.absent(),
  }) : type = Value(type),
       timestamp = Value(timestamp);
  static Insertable<TrackingEvent> custom({
    Expression<int>? id,
    Expression<String>? type,
    Expression<DateTime>? timestamp,
    Expression<double>? duration,
    Expression<String>? notes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (timestamp != null) 'timestamp': timestamp,
      if (duration != null) 'duration': duration,
      if (notes != null) 'notes': notes,
    });
  }

  TrackingEventsCompanion copyWith({
    Value<int>? id,
    Value<String>? type,
    Value<DateTime>? timestamp,
    Value<double?>? duration,
    Value<String?>? notes,
  }) {
    return TrackingEventsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      duration: duration ?? this.duration,
      notes: notes ?? this.notes,
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
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrackingEventsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('timestamp: $timestamp, ')
          ..write('duration: $duration, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TrackingEventsTable trackingEvents = $TrackingEventsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [trackingEvents];
}

typedef $$TrackingEventsTableCreateCompanionBuilder =
    TrackingEventsCompanion Function({
      Value<int> id,
      required String type,
      required DateTime timestamp,
      Value<double?> duration,
      Value<String?> notes,
    });
typedef $$TrackingEventsTableUpdateCompanionBuilder =
    TrackingEventsCompanion Function({
      Value<int> id,
      Value<String> type,
      Value<DateTime> timestamp,
      Value<double?> duration,
      Value<String?> notes,
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
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );
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
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
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
}

class $$TrackingEventsTableTableManager
    extends
        RootTableManager<
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
            BaseReferences<_$AppDatabase, $TrackingEventsTable, TrackingEvent>,
          ),
          TrackingEvent,
          PrefetchHooks Function()
        > {
  $$TrackingEventsTableTableManager(
    _$AppDatabase db,
    $TrackingEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrackingEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrackingEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrackingEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<double?> duration = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => TrackingEventsCompanion(
                id: id,
                type: type,
                timestamp: timestamp,
                duration: duration,
                notes: notes,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String type,
                required DateTime timestamp,
                Value<double?> duration = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => TrackingEventsCompanion.insert(
                id: id,
                type: type,
                timestamp: timestamp,
                duration: duration,
                notes: notes,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TrackingEventsTableProcessedTableManager =
    ProcessedTableManager<
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
        BaseReferences<_$AppDatabase, $TrackingEventsTable, TrackingEvent>,
      ),
      TrackingEvent,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TrackingEventsTableTableManager get trackingEvents =>
      $$TrackingEventsTableTableManager(_db, _db.trackingEvents);
}
