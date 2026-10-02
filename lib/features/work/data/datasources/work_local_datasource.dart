import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'package:je_fisc/core/database/app_database.dart';
import 'package:je_fisc/core/database/safe_db_call.dart';
import 'package:je_fisc/core/errors/app_exception.dart';
import 'package:je_fisc/core/network/paginated.dart';
import 'package:je_fisc/core/services/local_file_store.dart';
import 'package:je_fisc/core/utils/extensions.dart';
import 'package:je_fisc/features/category/domain/models/category_model.dart';
import 'package:je_fisc/features/work/domain/models/backup_import.dart';
import 'package:je_fisc/features/work/domain/models/visit_model.dart';
import 'package:je_fisc/features/work/domain/models/visit_picture_model.dart';
import 'package:je_fisc/features/work/domain/models/work_model.dart';

/// Works, their visits, and each visit's pictures and categories — the
/// `works`, `visits`, `visit_pictures` and `visit_categories` tables of
/// [AppDatabase].
///
/// Every call goes through [safeDbCall], so a sqflite error leaves here as an
/// `AppException`.
///
/// Picture files: `visit_pictures.picture_path` holds a path relative to
/// [LocalFileStore]; the models handed out carry the resolved, absolute one.
/// Rows cascade on delete in SQLite, the files do not, so every delete below
/// that can take pictures with it removes their files too.
class WorkLocalDataSource {
  const WorkLocalDataSource(this._db, this._files);

  final Database _db;
  final LocalFileStore _files;

  static const _picturesFolder = 'visit_pictures';
  static final _whitespace = RegExp(r'\s+');

  /// How many works [searchWorks] returns per page.
  static const _pageSize = 20;

  /// A work's row: its JSON plus the `search_key` [searchWorks] matches.
  static Map<String, dynamic> _workRow(WorkModel work) => {
    ...work.toJson(),
    'search_key': SearchKeys.work(
      clientName: work.clientName,
      address: work.address,
    ),
  };

  /// Escapes `LIKE`'s wildcards, so a typed `%` or `_` matches itself.
  static String _escapeLike(String text) =>
      text.replaceAllMapped(RegExp(r'[\\%_]'), (m) => '\\${m[0]}');

  // ── Works ────────────────────────────────────────────────────

  Future<List<WorkModel>> fetchWorks() => safeDbCall(() async {
    final rows = await _db.query(Tables.works, orderBy: 'start_date DESC');
    return rows.map(WorkModel.fromJson).toList();
  });

  /// The page of [limit] works after the one keyed [next] whose client name
  /// or address contains every word of [query], newest first. An empty
  /// [query] pages through every work.
  ///
  /// [next] is a 1-based page number — null for the first page — and only
  /// this method reads it. One row more than [limit] is asked for, so the
  /// last page is known without a trailing empty request.
  ///
  /// Matched against `search_key` ([SearchKeys.work]), so case and accents
  /// are ignored on both sides.
  Future<Paginated<WorkModel>> searchWorks({
    String query = '',
    Object? next,
    int limit = _pageSize,
  }) => safeDbCall(() async {
    final page = next as int? ?? 1;
    final words = query.searchKey
        .split(_whitespace)
        .where((word) => word.isNotEmpty)
        .toList();
    final rows = await _db.query(
      Tables.works,
      where: words.isEmpty
          ? null
          : List.filled(
              words.length,
              r"search_key LIKE ? ESCAPE '\'",
            ).join(' AND '),
      whereArgs: words.isEmpty
          ? null
          : [for (final word in words) '%${_escapeLike(word)}%'],
      // `id` breaks ties, so a page boundary between two works with the same
      // start date cannot show one twice and skip the other.
      orderBy: 'start_date DESC, id DESC',
      limit: limit + 1,
      offset: (page - 1) * limit,
    );
    final hasMore = rows.length > limit;
    return Paginated(
      items: rows.take(limit).map(WorkModel.fromJson).toList(),
      next: hasMore ? page + 1 : null,
    );
  });

  Future<WorkModel?> fetchWork(int id) => safeDbCall(() async {
    final rows = await _db.query(
      Tables.works,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : WorkModel.fromJson(rows.first);
  });

  /// Inserts [work] and returns it with the id SQLite gave it. An `id` of 0
  /// (what `WorkModel.empty()` starts with) lets the database pick one.
  Future<WorkModel> createWork(WorkModel work) => safeDbCall(() async {
    final id = await _insert(_db, Tables.works, _workRow(work));
    return work.copyWith(id: id);
  });

  Future<void> updateWork(WorkModel work) => safeDbCall(() async {
    await _update(Tables.works, work.id, _workRow(work));
  });

  /// Deletes the work, its visits and their pictures and categories.
  Future<void> deleteWork(int id) => safeDbCall(() async {
    final pictures = await _db.rawQuery(
      'SELECT p.picture_path FROM ${Tables.visitPictures} p '
      'JOIN ${Tables.visits} v ON v.id = p.visit_id '
      'WHERE v.work_id = ?',
      [id],
    );
    await _db.delete(Tables.works, where: 'id = ?', whereArgs: [id]);
    await _files.delete(pictures.map((r) => r['picture_path']! as String));
  });

  // ── Visits ───────────────────────────────────────────────────

  /// The work's visits, newest first, each with its pictures and categories.
  ///
  /// Three queries whatever the number of visits — one per table, the child
  /// tables filtered by a subquery on the work — grouped by visit in Dart. A
  /// single JOIN would return one row per picture × category pair of every
  /// visit; a query per visit would be N+1 round trips.
  Future<List<VisitModel>> fetchVisits(int workId) => safeDbCall(() async {
    const ofWork =
        'visit_id IN (SELECT id FROM ${Tables.visits} WHERE work_id = ?)';

    final (visitRows, pictureRows, categoryRows) = await _db.transaction(
      (txn) async => (
        await txn.query(
          Tables.visits,
          where: 'work_id = ?',
          whereArgs: [workId],
          // `id` breaks ties: visits on the same day (the form defaults to
          // today) come most recently created first.
          orderBy: 'date DESC, id DESC',
        ),
        await txn.query(
          Tables.visitPictures,
          where: ofWork,
          whereArgs: [workId],
          orderBy: 'id',
        ),
        // Joined to the lookup table for the name, alphabetically.
        await txn.rawQuery(
          'SELECT vc.visit_id, c.id, c.name '
          'FROM ${Tables.visitCategories} vc '
          'JOIN ${Tables.categories} c ON c.id = vc.category_id '
          'WHERE vc.$ofWork '
          'ORDER BY c.name',
          [workId],
        ),
      ),
    );

    final pictures = <int, List<VisitPictureModel>>{};
    for (final row in pictureRows) {
      final picture = await _pictureFromRow(row);
      (pictures[picture.visitId] ??= []).add(picture);
    }
    final categories = <int, List<CategoryModel>>{};
    for (final row in categoryRows) {
      (categories[row['visit_id']! as int] ??= []).add(
        CategoryModel.fromJson(row),
      );
    }

    return [
      for (final row in visitRows)
        VisitModel.fromJson(row).copyWith(
          pictures: pictures[row['id']] ?? const [],
          categories: categories[row['id']] ?? const [],
        ),
    ];
  });

  /// Inserts [visit] with its categories, in one transaction, and returns it
  /// with its new id. Its `pictures` are ignored — add them afterwards with
  /// [addVisitPicture], which also copies the file.
  Future<VisitModel> createVisit(VisitModel visit) => safeDbCall(() async {
    return _db.transaction((txn) async {
      final id = await _insert(txn, Tables.visits, visit.toJson());
      await _insertCategories(txn, id, visit.categories);
      return visit.copyWith(
        id: id,
        categories: {for (final c in visit.categories) c.id: c}.values.toList(),
      );
    });
  });

  /// Saves [visit]'s row and replaces its categories with `visit.categories`,
  /// in one transaction. Pictures are left alone — see [addVisitPicture] and
  /// [deleteVisitPicture].
  Future<void> updateVisit(VisitModel visit) => safeDbCall(() async {
    await _db.transaction((txn) async {
      await txn.update(
        Tables.visits,
        visit.toJson(),
        where: 'id = ?',
        whereArgs: [visit.id],
      );
      await txn.delete(
        Tables.visitCategories,
        where: 'visit_id = ?',
        whereArgs: [visit.id],
      );
      await _insertCategories(txn, visit.id, visit.categories);
    });
  });

  /// Deletes the visit and its pictures and categories.
  Future<void> deleteVisit(int id) => safeDbCall(() async {
    final pictures = await _db.query(
      Tables.visitPictures,
      columns: ['picture_path'],
      where: 'visit_id = ?',
      whereArgs: [id],
    );
    await _db.delete(Tables.visits, where: 'id = ?', whereArgs: [id]);
    await _files.delete(pictures.map((r) => r['picture_path']! as String));
  });

  // ── Visit pictures ───────────────────────────────────────────

  /// Copies the file at [sourcePath] — straight from a picker is fine — into
  /// the app's own storage and records it against the visit.
  Future<VisitPictureModel> addVisitPicture(int visitId, String sourcePath) =>
      safeDbCall(() async {
        final relative = await _files.save(sourcePath, folder: _picturesFolder);
        try {
          final id = await _db.insert(Tables.visitPictures, {
            'visit_id': visitId,
            'picture_path': relative,
          });
          return VisitPictureModel(
            id: id,
            visitId: visitId,
            picturePath: await _files.resolve(relative),
          );
        } catch (_) {
          // No row points at the copy, so nothing would ever delete it.
          await _files.delete([relative]);
          rethrow;
        }
      });

  Future<void> deleteVisitPicture(int id) => safeDbCall(() async {
    final rows = await _db.query(
      Tables.visitPictures,
      columns: ['picture_path'],
      where: 'id = ?',
      whereArgs: [id],
    );
    await _db.delete(Tables.visitPictures, where: 'id = ?', whereArgs: [id]);
    await _files.delete(rows.map((r) => r['picture_path']! as String));
  });

  // ── Backup ───────────────────────────────────────────────────

  /// Asks the user where to save a copy of the whole database file — every
  /// table, every row — and writes it there. False when the dialog was
  /// dismissed.
  ///
  /// The picture files are not in it: the rows hold only their paths.
  Future<bool> exportBackup() => safeDbCall(() async {
    // Folds a write-ahead log back into the file first, so the bytes read
    // below hold every committed write. A no-op when the log is off.
    await _db.rawQuery('PRAGMA wal_checkpoint(TRUNCATE)');
    final bytes = await File(_db.path).readAsBytes();
    final stamp = DateTime.now().format('yyyyMMdd_HHmm');
    final saved = await FilePicker.saveFile(
      dialogTitle: 'Guardar cópia de segurança',
      fileName: 'je_fisc_backup_$stamp.db',
      bytes: bytes,
    );
    return saved != null;
  });

  /// Asks the user for a backup [exportBackup] wrote and adds to this
  /// database everything in it that is not here yet. Null when the dialog
  /// was dismissed.
  ///
  /// Nothing already here is changed or removed, so it is safe on a device
  /// with data of its own, and importing the same file twice adds nothing
  /// the second time. What counts as already here:
  ///
  /// - a category with the same name, ignoring case;
  /// - a work with the same client, address and start date;
  /// - a visit of that work at the same date and time.
  ///
  /// A new visit comes with its categories, and with those of its pictures
  /// whose files are on this device — see [BackupImport.missingPictures].
  ///
  /// The backup is opened from a copy, migrated to the current schema, so
  /// one written by an older version of the app imports the same way.
  Future<BackupImport?> importBackup() => safeDbCall(() async {
    final picked = await FilePicker.pickFile(
      dialogTitle: 'Escolher cópia de segurança',
    );
    if (picked == null) return null;
    final source = picked.path;
    if (source == null) {
      throw const StorageException(
        message: 'Não foi possível ler o ficheiro escolhido.',
      );
    }
    return importBackupFrom(source);
  });

  /// [importBackup] for the file at [path], without the dialog.
  Future<BackupImport> importBackupFrom(String path) => safeDbCall(() async {
    if (!await _isBackup(path)) throw _notABackup;

    // A copy, never the picked file: opening runs the migrations, and those
    // write to the file they open.
    final copy = p.join(await getDatabasesPath(), _importCopyName);
    await deleteDatabase(copy);
    await File(path).copy(copy);
    try {
      final backup = await AppDatabase.openAt(copy);
      try {
        return await _merge(backup);
      } finally {
        await backup.close();
      }
    } finally {
      await deleteDatabase(copy);
    }
  });

  static const _importCopyName = 'je_fisc_import.db';

  static const _notABackup = StorageException(
    message: 'O ficheiro escolhido não é uma cópia de segurança da aplicação.',
  );

  /// Whether [path] is an SQLite file with this app's tables — checked
  /// before anything opens it for writing, which would add them to any
  /// SQLite file it was handed.
  Future<bool> _isBackup(String path) async {
    const header = 'SQLite format 3\u0000';
    final file = await File(path).open();
    try {
      final bytes = await file.read(header.length);
      if (String.fromCharCodes(bytes) != header) return false;
    } finally {
      await file.close();
    }
    final db = await openReadOnlyDatabase(path, singleInstance: false);
    try {
      final tables = await db.query(
        'sqlite_master',
        where: "type = 'table' AND name IN (?, ?)",
        whereArgs: [Tables.works, Tables.visits],
      );
      return tables.length == 2;
    } finally {
      await db.close();
    }
  }

  /// Copies what [backup] has and this database lacks, in one transaction —
  /// an import that fails half-way adds no rows.
  ///
  /// Ids are never copied: the backup's are only used to follow its rows to
  /// one another, and each is mapped to the id the row has, or gets, here.
  Future<BackupImport> _merge(Database backup) async {
    final categoryRows = await backup.query(Tables.categories);
    final workRows = await backup.query(Tables.works, orderBy: 'id');
    final visitRows = await backup.query(Tables.visits, orderBy: 'id');
    final pictureRows = await backup.query(Tables.visitPictures, orderBy: 'id');
    final linkRows = await backup.query(Tables.visitCategories);

    return _db.transaction((txn) async {
      // Read before anything is inserted, so two rows of the backup that
      // look alike are both imported rather than the second matching the
      // first.
      String workKey(Map<String, Object?> row) =>
          '${row['client_name']}\u0000${row['address']}\u0000'
          '${row['start_date']}';
      final localWorks = {
        for (final row in await txn.query(Tables.works))
          workKey(row): row['id'],
      };
      final localVisits = {
        for (final row in await txn.query(
          Tables.visits,
          columns: ['work_id', 'date'],
        ))
          '${row['work_id']}\u0000${row['date']}',
      };
      final localPictures = {
        for (final row in await txn.query(
          Tables.visitPictures,
          columns: ['picture_path'],
        ))
          row['picture_path'],
      };

      // Backup id → id here.
      final categoryIds = <Object?, int>{};
      for (final row in categoryRows) {
        final name = row['name']! as String;
        await txn.insert(Tables.categories, {
          'name': name,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
        // `name` is NOCASE, so this finds the row whatever its case.
        final local = await txn.query(
          Tables.categories,
          columns: ['id'],
          where: 'name = ?',
          whereArgs: [name],
          limit: 1,
        );
        categoryIds[row['id']] = local.first['id']! as int;
      }

      final workIds = <Object?, int>{};
      var works = 0;
      for (final row in workRows) {
        final existing = localWorks[workKey(row)];
        if (existing != null) {
          workIds[row['id']] = existing as int;
          continue;
        }
        final clientName = row['client_name']! as String;
        final address = row['address']! as String;
        workIds[row['id']] = await txn.insert(Tables.works, {
          'client_name': clientName,
          'address': address,
          'start_date': row['start_date'],
          'end_date': row['end_date'],
          'search_key': SearchKeys.work(
            clientName: clientName,
            address: address,
          ),
        });
        works++;
      }

      // Only the visits added here: one already here keeps its own
      // categories and pictures.
      final visitIds = <Object?, int>{};
      for (final row in visitRows) {
        final workId = workIds[row['work_id']];
        if (workId == null) continue;
        if (localVisits.contains('$workId\u0000${row['date']}')) continue;
        visitIds[row['id']] = await txn.insert(Tables.visits, {
          'work_id': workId,
          'date': row['date'],
          'notes': row['notes'],
        });
      }

      final children = txn.batch();
      for (final row in linkRows) {
        final visitId = visitIds[row['visit_id']];
        final categoryId = categoryIds[row['category_id']];
        if (visitId == null || categoryId == null) continue;
        children.insert(Tables.visitCategories, {
          'visit_id': visitId,
          'category_id': categoryId,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      var missingPictures = 0;
      for (final row in pictureRows) {
        final visitId = visitIds[row['visit_id']];
        if (visitId == null) continue;
        var path = row['picture_path']! as String;
        final file = await _files.resolve(path);
        if (!await File(file).exists()) {
          missingPictures++;
          continue;
        }
        // A file a row here already points at gets a copy of its own:
        // deleting either visit deletes its files, and must not take the
        // other's with it.
        if (localPictures.contains(path)) {
          path = await _files.save(file, folder: _picturesFolder);
        }
        children.insert(Tables.visitPictures, {
          'visit_id': visitId,
          'picture_path': path,
        });
      }
      await children.commit(noResult: true);

      return (
        works: works,
        visits: visitIds.length,
        missingPictures: missingPictures,
      );
    });
  }

  // ── Helpers ──────────────────────────────────────────────────

  /// Inserts [row], letting SQLite pick the id when the model still has the
  /// `0` its `empty()` factory starts with.
  Future<int> _insert(
    DatabaseExecutor db,
    String table,
    Map<String, dynamic> row,
  ) {
    if (row['id'] == 0) row.remove('id');
    return db.insert(table, row);
  }

  Future<void> _update(String table, int id, Map<String, dynamic> row) =>
      _db.update(table, row, where: 'id = ?', whereArgs: [id]);

  /// Links the visit to each of [categories] by id. Duplicates are dropped
  /// rather than tripping the UNIQUE (visit_id, category_id) constraint.
  Future<void> _insertCategories(
    DatabaseExecutor db,
    int visitId,
    List<CategoryModel> categories,
  ) async {
    final batch = db.batch();
    for (final id in {for (final c in categories) c.id}) {
      batch.insert(Tables.visitCategories, {
        'visit_id': visitId,
        'category_id': id,
      });
    }
    await batch.commit(noResult: true);
  }

  Future<VisitPictureModel> _pictureFromRow(Map<String, Object?> row) async =>
      VisitPictureModel.fromJson({
        ...row,
        'picture_path': await _files.resolve(row['picture_path']! as String),
      });
}
