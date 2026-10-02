import '../datasources/category_local_datasource.dart';
import '../../domain/models/category_model.dart';
import '../../domain/repositories/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  const CategoryRepositoryImpl(this._local);

  final CategoryLocalDataSource _local;

  @override
  Future<List<CategoryModel>> fetchCategories() => _local.fetchCategories();

  @override
  Future<CategoryModel> createCategory(String name) =>
      _local.createCategory(name);

  @override
  Future<void> updateCategory(CategoryModel category) =>
      _local.updateCategory(category);

  @override
  Future<void> deleteCategory(int id) => _local.deleteCategory(id);
}
