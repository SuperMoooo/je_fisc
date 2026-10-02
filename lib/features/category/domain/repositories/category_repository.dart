import '../models/category_model.dart';

abstract interface class CategoryRepository {
  /// Every category, alphabetically.
  Future<List<CategoryModel>> fetchCategories();

  /// Adds a category. A name already taken, in any capitalisation, fails
  /// with an `AppException` saying so.
  Future<CategoryModel> createCategory(String name);
}
