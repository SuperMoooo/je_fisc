import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:je_fisc/core/database/app_database.dart';
import 'package:je_fisc/core/errors/app_exception.dart';
import 'package:je_fisc/core/services/local_file_store.dart';
import 'package:je_fisc/features/calendar/data/datasources/calendar_local_datasource.dart';
import 'package:je_fisc/features/category/data/datasources/category_local_datasource.dart';
import 'package:je_fisc/features/category/domain/models/category_model.dart';
import 'package:je_fisc/features/work/data/datasources/work_local_datasource.dart';
import 'package:je_fisc/features/work/domain/models/visit_model.dart';
import 'package:je_fisc/features/work/domain/models/work_model.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// The schema and the queries against a real SQLite, through sqflite's FFI
/// factory — a fresh file per test in a temp directory.
void main() {
  late Directory dir;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('je_fisc_db_test');
    await databaseFactory.setDatabasesPath(dir.path);
  });

  tearDown(() => dir.delete(recursive: true));

  group('fresh install', () {
    late Database db;
    late CategoryLocalDataSource categories;
    late WorkLocalDataSource works;

    setUp(() async {
      db = await AppDatabase.open();
      categories = CategoryLocalDataSource(db);
      works = WorkLocalDataSource(db, LocalFileStore());
    });

    tearDown(() => db.close());

    test('seeds the 18 initial categories, alphabetically', () async {
      final all = await categories.fetchCategories();
      expect(all, hasLength(18));
      expect(all.first.name, 'Alvenarias');
      expect(
        all.map((c) => c.name),
        contains('Movimento de terras / Escavação'),
      );
    });

    test('a category added is listed; the same name in another case is '
        'refused with a message saying so', () async {
      await categories.createCategory('  Pintura ');
      final names = (await categories.fetchCategories()).map((c) => c.name);
      expect(names, contains('Pintura'));

      expect(
        () => categories.createCategory('pintura'),
        throwsA(
          isA<StorageException>().having(
            (e) => e.message,
            'message',
            contains('já existe'),
          ),
        ),
      );
    });

    test('a category renamed keeps its id; a name already taken is '
        'refused', () async {
      final all = await categories.fetchCategories();
      final jardim = all.firstWhere((c) => c.name == 'Jardim');

      await categories.updateCategory(jardim.copyWith(name: ' Jardins '));
      final renamed = await categories.fetchCategories();
      expect(renamed, contains(CategoryModel(id: jardim.id, name: 'Jardins')));

      expect(
        () => categories.updateCategory(jardim.copyWith(name: 'fundações')),
        throwsA(
          isA<StorageException>().having(
            (e) => e.message,
            'message',
            contains('já existe'),
          ),
        ),
      );
    });

    test('a category no visit uses is deleted; one a visit uses is '
        'refused with a message saying so', () async {
      final all = await categories.fetchCategories();
      final jardim = all.firstWhere((c) => c.name == 'Jardim');
      final outros = all.firstWhere((c) => c.name == 'Outros');

      final work = await works.createWork(
        WorkModel(
          id: 0,
          clientName: 'Cliente',
          address: 'Rua',
          startDate: DateTime(2026, 9),
        ),
      );
      await works.createVisit(
        VisitModel(
          id: 0,
          workId: work.id,
          date: DateTime(2026, 9, 10),
          categories: [jardim],
        ),
      );

      await categories.deleteCategory(outros.id);
      expect(await categories.fetchCategories(), isNot(contains(outros)));

      expect(
        () => categories.deleteCategory(jardim.id),
        throwsA(
          isA<StorageException>().having(
            (e) => e.message,
            'message',
            contains('a ser usada'),
          ),
        ),
      );
    });

    test("a visit's categories come back with it, by name", () async {
      final all = await categories.fetchCategories();
      final jardim = all.firstWhere((c) => c.name == 'Jardim');
      final fundacoes = all.firstWhere((c) => c.name == 'Fundações');

      final work = await works.createWork(
        WorkModel(
          id: 0,
          clientName: 'Cliente',
          address: 'Rua',
          startDate: DateTime(2026, 9),
        ),
      );
      await works.createVisit(
        VisitModel(
          id: 0,
          workId: work.id,
          date: DateTime(2026, 9, 10),
          categories: [jardim, fundacoes, jardim],
        ),
      );

      final visits = await works.fetchVisits(work.id);
      expect(visits, hasLength(1));
      // Alphabetical, and the duplicate dropped.
      expect(visits.single.categories, [fundacoes, jardim]);
    });

    test("a work's visits come newest first, and on the same day the one "
        'created last first', () async {
      final work = await works.createWork(
        WorkModel(
          id: 0,
          clientName: 'Cliente',
          address: 'Rua',
          startDate: DateTime(2026, 9),
        ),
      );
      final created = <int>[];
      for (final date in [
        DateTime(2026, 9, 5),
        DateTime(2026, 9, 20),
        DateTime(2026, 9, 10),
        DateTime(2026, 9, 20),
      ]) {
        final visit = await works.createVisit(
          VisitModel(id: 0, workId: work.id, date: date),
        );
        created.add(visit.id);
      }

      final visits = await works.fetchVisits(work.id);
      expect(visits.map((v) => v.id), [
        created[3],
        created[1],
        created[2],
        created[0],
      ]);
    });

    test('the calendar reads the visits of a range, both ends included, '
        'with their work', () async {
      final calendar = CalendarLocalDataSource(db);
      final work = await works.createWork(
        WorkModel(
          id: 0,
          clientName: 'Ana',
          address: 'Porto',
          startDate: DateTime(2026, 9),
        ),
      );
      for (final date in [
        DateTime(2026, 8, 31),
        DateTime(2026, 9, 1),
        DateTime(2026, 9, 30, 18),
        DateTime(2026, 10, 1),
      ]) {
        await works.createVisit(VisitModel(id: 0, workId: work.id, date: date));
      }

      final september = await calendar.fetchVisits(
        from: DateTime(2026, 9),
        to: DateTime(2026, 9, 30),
      );
      expect(september.map((v) => v.date), [
        DateTime(2026, 9, 1),
        DateTime(2026, 9, 30, 18),
      ]);
      expect(september.first.clientName, 'Ana');
      expect(september.first.workId, work.id);
    });
  });

  test('upgrading a v1 database keeps its free-text categories, now as '
      'rows of the lookup table', () async {
    // The v1 schema, as an installed app has it.
    final path = p.join(dir.path, AppDatabase.fileName);
    final v1 = await openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute(
          'CREATE TABLE works (id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'client_name TEXT NOT NULL, address TEXT NOT NULL, '
          'start_date TEXT NOT NULL, end_date TEXT, '
          "search_key TEXT NOT NULL DEFAULT '')",
        );
        await db.execute(
          'CREATE TABLE visits (id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'work_id INTEGER NOT NULL REFERENCES works(id) ON DELETE CASCADE, '
          'date TEXT NOT NULL)',
        );
        await db.execute(
          'CREATE TABLE visit_pictures (id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'visit_id INTEGER NOT NULL REFERENCES visits(id) ON DELETE CASCADE, '
          'picture_path TEXT NOT NULL)',
        );
        await db.execute(
          'CREATE TABLE visit_categories (id INTEGER PRIMARY KEY '
          'AUTOINCREMENT, visit_id INTEGER NOT NULL REFERENCES visits(id) '
          'ON DELETE CASCADE, category TEXT NOT NULL, '
          'UNIQUE (visit_id, category))',
        );
      },
    );
    await v1.insert('works', {
      'id': 1,
      'client_name': 'C',
      'address': 'A',
      'start_date': DateTime(2026).toIso8601String(),
    });
    await v1.insert('visits', {
      'id': 1,
      'work_id': 1,
      'date': DateTime(2026, 2).toIso8601String(),
    });
    // One that matches a seeded category, one that does not.
    await v1.insert('visit_categories', {'visit_id': 1, 'category': 'Jardim'});
    await v1.insert('visit_categories', {'visit_id': 1, 'category': 'Telhado'});
    await v1.close();

    final db = await AppDatabase.open();
    addTearDown(db.close);

    final all = await CategoryLocalDataSource(db).fetchCategories();
    expect(all, hasLength(19), reason: 'the 18 seeded plus "Telhado"');

    final visits = await WorkLocalDataSource(
      db,
      LocalFileStore(),
    ).fetchVisits(1);
    expect(visits.single.categories.map((c) => c.name), ['Jardim', 'Telhado']);
    expect(visits.single.categories, everyElement(isA<CategoryModel>()));
  });
}
