import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:je_fisc/core/database/app_database.dart';
import 'package:je_fisc/core/errors/app_exception.dart';
import 'package:je_fisc/core/services/local_file_store.dart';
import 'package:je_fisc/features/category/data/datasources/category_local_datasource.dart';
import 'package:je_fisc/features/work/data/datasources/work_local_datasource.dart';
import 'package:je_fisc/features/work/domain/models/visit_model.dart';
import 'package:je_fisc/features/work/domain/models/work_model.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// [LocalFileStore] over a temp directory — the real one asks path_provider,
/// which has no implementation in a unit test.
class _TempFileStore implements LocalFileStore {
  _TempFileStore(this.root);

  final Directory root;
  var _next = 0;

  @override
  Future<String> save(String sourcePath, {required String folder}) async {
    final relative = p.join(folder, 'copy_${_next++}.jpg');
    final target = File(p.join(root.path, relative));
    await target.parent.create(recursive: true);
    await File(sourcePath).copy(target.path);
    return relative;
  }

  @override
  Future<String> resolve(String relativePath) async =>
      p.join(root.path, relativePath);

  @override
  Future<void> delete(Iterable<String> relativePaths) async {
    for (final relative in relativePaths) {
      final file = File(await resolve(relative));
      if (await file.exists()) await file.delete();
    }
  }
}

/// Visit notes, and importing a backup into a database with data of its own
/// — against a real SQLite, through sqflite's FFI factory.
void main() {
  late Directory dir;
  late _TempFileStore files;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('je_fisc_import_test');
    await databaseFactory.setDatabasesPath(dir.path);
    files = _TempFileStore(Directory(p.join(dir.path, 'documents')));
  });

  tearDown(() => dir.delete(recursive: true));

  WorkModel work(String client) => WorkModel(
    id: 0,
    clientName: client,
    address: 'Rua',
    startDate: DateTime(2026, 9),
  );

  test('a visit keeps its notes, and an edit can clear them', () async {
    final db = await AppDatabase.open();
    addTearDown(db.close);
    final works = WorkLocalDataSource(db, files);

    final w = await works.createWork(work('Ana'));
    final visit = await works.createVisit(
      VisitModel(
        id: 0,
        workId: w.id,
        date: DateTime(2026, 9, 10),
        notes: 'Fissura na parede norte',
      ),
    );
    expect((await works.fetchVisits(w.id)).single.notes, visit.notes);

    await works.updateVisit(visit.copyWith(notes: null));
    expect((await works.fetchVisits(w.id)).single.notes, isNull);
  });

  group('importBackupFrom', () {
    late String backupPath;

    /// A backup holding works "Ana" (two visits, one with pictures) and
    /// "Bruno" (one visit), and a category this device lacks.
    setUp(() async {
      backupPath = p.join(dir.path, 'backup.db');
      final backup = await AppDatabase.openAt(backupPath);
      final source = WorkLocalDataSource(backup, files);
      final categories = CategoryLocalDataSource(backup);
      final telhado = await categories.createCategory('Telhado');

      final ana = await source.createWork(work('Ana'));
      await source.createVisit(
        VisitModel(id: 0, workId: ana.id, date: DateTime(2026, 9, 10)),
      );
      final second = await source.createVisit(
        VisitModel(
          id: 0,
          workId: ana.id,
          date: DateTime(2026, 9, 20),
          notes: 'Telhado com infiltrações',
          categories: [telhado],
        ),
      );
      final picture = File(p.join(dir.path, 'picture.jpg'));
      await picture.writeAsBytes([1, 2, 3]);
      await source.addVisitPicture(second.id, picture.path);
      final gone = await source.addVisitPicture(second.id, picture.path);
      await File(gone.picturePath).delete();

      final bruno = await source.createWork(work('Bruno'));
      await source.createVisit(
        VisitModel(id: 0, workId: bruno.id, date: DateTime(2026, 9, 15)),
      );
      await backup.close();
    });

    test('adds only what is not here yet, and a second import adds '
        'nothing', () async {
      final db = await AppDatabase.open();
      addTearDown(db.close);
      final works = WorkLocalDataSource(db, files);

      // "Ana" and her first visit are already here.
      final ana = await works.createWork(work('Ana'));
      await works.createVisit(
        VisitModel(
          id: 0,
          workId: ana.id,
          date: DateTime(2026, 9, 10),
          notes: 'Local',
        ),
      );

      final imported = await works.importBackupFrom(backupPath);
      expect(imported, (works: 1, visits: 2, missingPictures: 1));

      final all = await works.fetchWorks();
      expect(all.map((w) => w.clientName), unorderedEquals(['Ana', 'Bruno']));

      final anaVisits = await works.fetchVisits(ana.id);
      expect(anaVisits, hasLength(2));
      final [newest, oldest] = anaVisits;
      expect(oldest.notes, 'Local', reason: 'the local visit is untouched');
      expect(newest.notes, 'Telhado com infiltrações');
      expect(newest.categories.map((c) => c.name), ['Telhado']);
      expect(newest.pictures, hasLength(1));
      expect(await File(newest.pictures.single.picturePath).exists(), isTrue);

      // Imported "Bruno" is found by the search, like one created here.
      final found = await works.searchWorks(query: 'bruno');
      expect(found.items.single.clientName, 'Bruno');

      final again = await works.importBackupFrom(backupPath);
      expect(again, (works: 0, visits: 0, missingPictures: 0));
    });

    test('a file that is not a backup is refused with a message saying '
        'so, and adds nothing', () async {
      final db = await AppDatabase.open();
      addTearDown(db.close);
      final works = WorkLocalDataSource(db, files);

      final text = File(p.join(dir.path, 'notes.txt'));
      await text.writeAsString('not a database');
      final otherDb = p.join(dir.path, 'other.db');
      final other = await openDatabase(
        otherDb,
        version: 1,
        onCreate: (db, _) => db.execute('CREATE TABLE things (id INTEGER)'),
      );
      await other.close();

      for (final path in [text.path, otherDb]) {
        await expectLater(
          works.importBackupFrom(path),
          throwsA(
            isA<StorageException>().having(
              (e) => e.message,
              'message',
              contains('não é uma cópia'),
            ),
          ),
        );
      }
      expect(await works.fetchWorks(), isEmpty);
    });
  });
}
