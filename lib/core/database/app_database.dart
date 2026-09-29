import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../utils/extensions.dart';

/// The app's one SQLite database: its file, its schema and its migrations.
///
/// Opened once, in `external_module.dart`, and handed out as a [Database] by
/// the locator — datasources take it in their constructor and never open one
/// of their own.
///
/// Changing the schema: append a migration to [_migrations]; never edit one
/// that has shipped. [_version] follows the list, so a fresh install runs
/// every step in order and an upgrade runs only the ones it has not seen.
abstract final class AppDatabase {
  static const fileName = 'je_fisc.db';

  /// One entry per schema version: `_migrations[0]` takes an empty database
  /// to version 1, `_migrations[1]` takes version 1 to 2, and so on.
  static final List<Future<void> Function(Transaction txn)> _migrations = [
    // v1 — works. Column names match WorkModel's JSON keys, so a row goes
    // through `WorkModel.fromJson` / `toJson` unchanged.
    (txn) async {
      await txn.execute('''
        CREATE TABLE ${Tables.works} (
          id          INTEGER PRIMARY KEY AUTOINCREMENT,
          client_name TEXT    NOT NULL,
          address     TEXT    NOT NULL,
          start_date  TEXT    NOT NULL,
          end_date    TEXT    NOT NULL
        )
      ''');
    },
    // v2 — a work's visits, and each visit's pictures and categories.
    // Deleting a work deletes its visits, and a visit its pictures and
    // categories (ON DELETE CASCADE; foreign keys are switched on in
    // `onConfigure`). The picture files on disk are not rows — deleting them
    // is the datasource's job.
    (txn) async {
      await txn.execute('''
        CREATE TABLE ${Tables.visits} (
          id      INTEGER PRIMARY KEY AUTOINCREMENT,
          work_id INTEGER NOT NULL
                  REFERENCES ${Tables.works}(id) ON DELETE CASCADE,
          date    TEXT    NOT NULL
        )
      ''');
      await txn.execute(
        'CREATE INDEX idx_visits_work_id ON ${Tables.visits}(work_id)',
      );

      await txn.execute('''
        CREATE TABLE ${Tables.visitPictures} (
          id           INTEGER PRIMARY KEY AUTOINCREMENT,
          visit_id     INTEGER NOT NULL
                       REFERENCES ${Tables.visits}(id) ON DELETE CASCADE,
          picture_path TEXT    NOT NULL
        )
      ''');
      await txn.execute(
        'CREATE INDEX idx_visit_pictures_visit_id '
        'ON ${Tables.visitPictures}(visit_id)',
      );

      await txn.execute('''
        CREATE TABLE ${Tables.visitCategories} (
          id       INTEGER PRIMARY KEY AUTOINCREMENT,
          visit_id INTEGER NOT NULL
                   REFERENCES ${Tables.visits}(id) ON DELETE CASCADE,
          category TEXT    NOT NULL,
          UNIQUE (visit_id, category)
        )
      ''');
      // The UNIQUE constraint above already indexes visit_id first, so
      // lookups by visit need no index of their own.
    },
    // v3 — works.search_key, what the works search matches against: see
    // [SearchKeys.work]. Rows saved before this version are filled in here;
    // from now on the datasource writes it with every save.
    (txn) async {
      await txn.execute(
        "ALTER TABLE ${Tables.works} "
        "ADD COLUMN search_key TEXT NOT NULL DEFAULT ''",
      );
      final rows = await txn.query(
        Tables.works,
        columns: ['id', 'client_name', 'address'],
      );
      for (final row in rows) {
        await txn.update(
          Tables.works,
          {
            'search_key': SearchKeys.work(
              clientName: row['client_name']! as String,
              address: row['address']! as String,
            ),
          },
          where: 'id = ?',
          whereArgs: [row['id']],
        );
      }
    },
  ];

  static int get _version => _migrations.length;

  static Future<Database> open() async {
    final path = p.join(await getDatabasesPath(), fileName);
    return openDatabase(
      path,
      version: _version,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) => _migrate(db, 0, version),
      onUpgrade: _migrate,
    );
  }

  static Future<void> _migrate(Database db, int from, int to) {
    return db.transaction((txn) async {
      for (var i = from; i < to; i++) {
        await _migrations[i](txn);
      }
    });
  }
}

/// Table names, so a typo is a compile error rather than a runtime one.
abstract final class Tables {
  static const works = 'works';
  static const visits = 'visits';
  static const visitPictures = 'visit_pictures';
  static const visitCategories = 'visit_categories';
}

/// The text a search matches against, stored beside the row it describes.
///
/// Lower case and without accents ([StringX.searchKey]), so "conceicao" finds
/// "Conceição". Folded in Dart because SQLite's `LIKE` only ignores the case
/// of A–Z and knows nothing about accents. A search query goes through the
/// same `searchKey` before it is matched.
abstract final class SearchKeys {
  static String work({required String clientName, required String address}) =>
      '$clientName $address'.searchKey;
}
