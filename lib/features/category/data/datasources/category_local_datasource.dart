import 'package:sqflite/sqflite.dart';

import 'package:je_fisc/core/database/app_database.dart';
import 'package:je_fisc/core/database/safe_db_call.dart';
import 'package:je_fisc/core/errors/app_exception.dart';
import 'package:je_fisc/features/category/domain/models/category_model.dart';

/// The `categories` lookup table of [AppDatabase].
///
/// Every call goes through [safeDbCall], so a sqflite error leaves here as an
/// `AppException`.
class CategoryLocalDataSource {
  const CategoryLocalDataSource(this._db);

  final Database _db;

  /// Every category, alphabetically — ignoring case, the way the column is
  /// declared.
  Future<List<CategoryModel>> fetchCategories() => safeDbCall(() async {
    final rows = await _db.query(Tables.categories, orderBy: 'name');
    return rows.map(CategoryModel.fromJson).toList();
  });

  /// Adds a category called [name], trimmed, and returns it with its id.
  Future<CategoryModel> createCategory(String name) => safeDbCall(() async {
    final trimmed = name.trim();
    try {
      final id = await _db.insert(Tables.categories, {'name': trimmed});
      return CategoryModel(id: id, name: trimmed);
    } on DatabaseException catch (e) {
      // The column is UNIQUE COLLATE NOCASE, so this is the same name in
      // any capitalisation — worth saying which, rather than the generic
      // "already exists" safeDbCall would give.
      if (!e.isUniqueConstraintError()) rethrow;
      throw StorageException(message: 'A categoria "$trimmed" já existe.');
    }
  });
}
