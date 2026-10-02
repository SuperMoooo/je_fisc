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

  /// Renames [category] to its `name`, trimmed. Visits tagged with it follow,
  /// since they point at its id.
  Future<void> updateCategory(CategoryModel category) => safeDbCall(() async {
    final trimmed = category.name.trim();
    try {
      await _db.update(
        Tables.categories,
        {'name': trimmed},
        where: 'id = ?',
        whereArgs: [category.id],
      );
    } on DatabaseException catch (e) {
      if (!e.isUniqueConstraintError()) rethrow;
      throw StorageException(message: 'A categoria "$trimmed" já existe.');
    }
  });

  /// Deletes the category. One some visit is tagged with is refused
  /// (ON DELETE RESTRICT), with a message saying so.
  Future<void> deleteCategory(int id) => safeDbCall(() async {
    try {
      await _db.delete(Tables.categories, where: 'id = ?', whereArgs: [id]);
    } on DatabaseException catch (e) {
      if (!e.toString().contains('FOREIGN KEY constraint failed')) rethrow;
      throw const StorageException(
        message:
            'Esta categoria está a ser usada em visitas e não pode ser '
            'eliminada.',
      );
    }
  });
}
