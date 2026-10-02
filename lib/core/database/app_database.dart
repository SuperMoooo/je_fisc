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
    // v1 — the initial schema.
    (txn) async {
      // Works. Column names match WorkModel's JSON keys, so a row goes
      // through `WorkModel.fromJson` / `toJson` unchanged. `search_key` is
      // what the works search matches against: see [SearchKeys.work]; the
      // datasource writes it with every save.
      await txn.execute('''
        CREATE TABLE ${Tables.works} (
          id          INTEGER PRIMARY KEY AUTOINCREMENT,
          client_name TEXT    NOT NULL,
          address     TEXT    NOT NULL,
          start_date  TEXT    NOT NULL,
          end_date    TEXT,
          search_key  TEXT    NOT NULL DEFAULT ''
        )
      ''');

      // A work's visits, and each visit's pictures and categories.
      // Deleting a work deletes its visits, and a visit its pictures and
      // categories (ON DELETE CASCADE; foreign keys are switched on in
      // `onConfigure`). The picture files on disk are not rows — deleting
      // them is the datasource's job.
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

    // v2 — categories become a lookup table the user can add to, and a
    // visit's categories point at it by id instead of holding free text.
    (txn) async {
      // NOCASE: "Jardim" and "jardim" are one category, both for the UNIQUE
      // constraint and for the alphabetical order the list is read in.
      await txn.execute('''
        CREATE TABLE ${Tables.categories} (
          id   INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT    NOT NULL UNIQUE COLLATE NOCASE
        )
      ''');
      final seed = txn.batch();
      for (final name in _initialCategories) {
        seed.insert(Tables.categories, {'name': name});
      }
      await seed.commit(noResult: true);

      // Free-text categories saved under v1 join the table rather than being
      // lost; OR IGNORE skips the ones the seed already holds.
      await txn.execute('''
        INSERT OR IGNORE INTO ${Tables.categories} (name)
        SELECT DISTINCT category FROM ${Tables.visitCategories}
      ''');

      // SQLite cannot change a column's type or add a foreign key in place,
      // so the table is rebuilt and the old rows copied across by name.
      // RESTRICT: a category some visit uses cannot be deleted from under it.
      await txn.execute('''
        CREATE TABLE visit_categories_v2 (
          id          INTEGER PRIMARY KEY AUTOINCREMENT,
          visit_id    INTEGER NOT NULL
                      REFERENCES ${Tables.visits}(id) ON DELETE CASCADE,
          category_id INTEGER NOT NULL
                      REFERENCES ${Tables.categories}(id) ON DELETE RESTRICT,
          UNIQUE (visit_id, category_id)
        )
      ''');
      await txn.execute('''
        INSERT OR IGNORE INTO visit_categories_v2 (visit_id, category_id)
        SELECT vc.visit_id, c.id
        FROM ${Tables.visitCategories} vc
        JOIN ${Tables.categories} c ON c.name = vc.category
      ''');
      await txn.execute('DROP TABLE ${Tables.visitCategories}');
      await txn.execute(
        'ALTER TABLE visit_categories_v2 RENAME TO ${Tables.visitCategories}',
      );
      await txn.execute(
        'CREATE INDEX idx_visit_categories_category_id '
        'ON ${Tables.visitCategories}(category_id)',
      );
    },

    // v3 — free-text notes on a visit, optional.
    (txn) async {
      await txn.execute('ALTER TABLE ${Tables.visits} ADD COLUMN notes TEXT');
    },
  ];

  /// What the categories table starts with. Seeded once, by the v2
  /// migration — editing this list later changes nothing on an installed
  /// app; add a migration for that.
  static const _initialCategories = [
    'Trabalhos preparatórios',
    'Movimento de terras / Escavação',
    'Fundações',
    'Revestimento de pavimentos',
    'Alvenarias',
    'Rebocos',
    'Impermeabilizações',
    'Revestimento de paredes',
    'Revestimento de tetos',
    'Rede elétrica',
    'Rede de águas',
    'Rede de esgotos pluviais e domésticos',
    'Ventilação',
    'Carpintarias',
    'Jardim',
    'Serralharias',
    'Domótica',
    'Outros',
  ];

  static int get _version => _migrations.length;

  static Future<Database> open() async =>
      openAt(p.join(await getDatabasesPath(), fileName));

  /// Opens the database file at [path] — the app's own, or a backup copy —
  /// and migrates it to the current schema, so either is read the same way.
  static Future<Database> openAt(String path) {
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
  static const categories = 'categories';
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
