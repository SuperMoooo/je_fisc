import '../models/category_model.dart';

abstract interface class CategoryRepository {
  /// Every category, alphabetically.
  Future<List<CategoryModel>> fetchCategories();

  /// Adds a category. A name already taken, in any capitalisation, fails
  /// with an `AppException` saying so.
  Future<CategoryModel> createCategory(String name);

  /// Renames the category with `category.id` to `category.name`. A name
  /// already taken fails like [createCategory].
  Future<void> updateCategory(CategoryModel category);

  /// Deletes the category. One that a visit is tagged with fails with an
  /// `AppException` saying so.
  Future<void> deleteCategory(int id);
}
