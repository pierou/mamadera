import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/data/local/app_db.dart';

/// Empty [GeneratedDatabase] shell: executes raw SQL with no tables of its own,
/// so `schema.sql` is replayed by SQLite and not by Drift.
class _RawSqlDatabase extends GeneratedDatabase {
  _RawSqlDatabase(super.e);

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];

  @override
  int get schemaVersion => 1;
}

/// Path to the generated DDL reference, from the package root (`flutter test`'s
/// working directory).
const String _schemaPath = 'lib/data/local/schema.sql';

/// BACKLOG B26 — `schema.sql` must replay.
///
/// The file is the DDL reference people read when they reason about the
/// database (and the file the migration tests describe their seeds by), so a
/// statement in it that SQLite rejects is worse than a stale comment: it looks
/// authoritative. Until B26 was paid it did not parse at all — `measurements`
/// ended its column list with a trailing comma.
///
/// The guard is therefore two-fold: the whole file must execute against an
/// empty database, and the table it is most likely to drift on
/// (`reminder_settings`) must have the same columns, in the same order, as a
/// fresh install produced by Drift.
void main() {
  setUp(() {
    // Two databases in one test (the replay, then a fresh install to compare
    // against) is deliberate; without the flag every result is buried under a
    // multi-database warning.
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  test('schema.sql replays into an empty database without a syntax error',
      () async {
    final file = File(_schemaPath);
    expect(file.existsSync(), isTrue,
        reason: '$_schemaPath is the DDL reference; it must exist');

    final db = _RawSqlDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final statements = _sqlStatements(file.readAsStringSync());
    expect(statements, isNotEmpty, reason: 'no statement found');
    for (final statement in statements) {
      // Failures must name the statement: "the file does not replay" is not an
      // error a reader can act on.
      expect(
        () => db.customStatement(statement),
        returnsNormally,
        reason: 'statement rejected by SQLite:\n$statement',
      );
    }

    final tables = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          'AND name NOT LIKE \'sqlite_%\' ORDER BY name',
        )
        .get();
    expect(
      tables.map((t) => t.read<String>('name')),
      containsAll(<String>[
        'app_settings',
        'baby_profiles',
        'custom_reminders',
        'measurements',
        'reminder_completions',
        'reminder_dismissals',
        'reminder_settings',
        'tracking_events',
      ]),
    );
  });

  test(
      'schema.sql describes the same reminder_settings columns a fresh '
      'install actually has', () async {
    final replayed = _RawSqlDatabase(NativeDatabase.memory());
    addTearDown(replayed.close);
    for (final statement
        in _sqlStatements(File(_schemaPath).readAsStringSync())) {
      replayed.customStatement(statement);
    }

    final fresh = AppDatabase(NativeDatabase.memory());
    addTearDown(fresh.close);

    expect(
      await _columnsOf(replayed, 'reminder_settings'),
      await _columnsOf(fresh, 'reminder_settings'),
      reason: 'the reference file and Drift disagree about reminder_settings — '
          'B26 is exactly this class of defect',
    );
  });
}

/// Column names of a table, in declaration order.
Future<List<String>> _columnsOf(GeneratedDatabase db, String table) async {
  final rows = await db.customSelect('PRAGMA table_info("$table")').get();
  return rows.map((r) => r.read<String>('name')).toList();
}

/// The executable statements of a SQL script: `--` comments stripped, text cut
/// on the semicolons that sit outside a `'...'` literal.
///
/// Deliberately a scanner and not a `split(';')`: the reference file carries
/// commented values like `'daily' | 'weekly'` and a future edit that puts a
/// semicolon inside a literal must not make the guard lie about the file.
List<String> _sqlStatements(String source) {
  final stripped = _stripComments(source);

  final statements = <String>[];
  final buffer = StringBuffer();
  var insideString = false;
  for (var i = 0; i < stripped.length; i++) {
    final char = stripped[i];
    if (char == "'") {
      // A doubled quote ('') is an escaped quote inside a literal, not a close.
      final isEscaped = i + 1 < stripped.length && stripped[i + 1] == "'";
      if (!isEscaped) insideString = !insideString;
    }
    if (char == ';' && !insideString) {
      final statement = buffer.toString().trim();
      if (statement.isNotEmpty) statements.add(statement);
      buffer.clear();
      continue;
    }
    buffer.write(char);
  }
  final tail = buffer.toString().trim();
  if (tail.isNotEmpty) statements.add(tail);
  return statements;
}

/// The script with its `--` comments removed.
///
/// A `--` inside a `'...'` literal is data, not a comment, so the scan tracks
/// quote state (a doubled `''` is an escaped quote, not a closing one).
String _stripComments(String source) {
  final out = StringBuffer();
  for (final line in source.split('\n')) {
    var insideString = false;
    var cut = -1;
    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == "'") {
        final isEscaped = i + 1 < line.length && line[i + 1] == "'";
        if (!isEscaped) insideString = !insideString;
      } else if (char == '-' &&
          !insideString &&
          i + 1 < line.length &&
          line[i + 1] == '-') {
        cut = i;
        break;
      }
    }
    out.writeln(cut < 0 ? line : line.substring(0, cut));
  }
  return out.toString();
}
