import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';

import '../../../../core/utils/app_status.dart';
import '../../domain/repositories/category_repository.dart';
import 'category_event.dart';
import 'category_state.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState>
    with ActionBlocMixin<CategoryEvent, CategoryState> {
  CategoryBloc(this._repo) : super(const CategoryState()) {
    on<CategoryStarted>(_onStarted);
    on<CategoryCreated>(_onCreated, transformer: droppable());
    on<CategoryRenamed>(_onRenamed, transformer: droppable());
    on<CategoryDeleted>(_onDeleted, transformer: droppable());
  }

  final CategoryRepository _repo;

  Future<void> _onStarted(CategoryStarted event, Emitter<CategoryState> emit) =>
      runAction(emit, (current) async {
        final categories = await _repo.fetchCategories();
        return current.copyWith(
          status: AppStatus.success,
          categories: categories,
        );
      });

  /// Reloads the list after the insert rather than splicing the new one in,
  /// so it lands where the database's own order puts it.
  Future<void> _onCreated(CategoryCreated event, Emitter<CategoryState> emit) =>
      runAction(emit, (current) async {
        final created = await _repo.createCategory(event.name);
        final categories = await _repo.fetchCategories();
        return current.copyWith(
          categories: categories,
          successMessage: 'Categoria "${created.name}" adicionada',
        );
      });

  /// Reloads, like [_onCreated], so the renamed one moves to its new place.
  Future<void> _onRenamed(CategoryRenamed event, Emitter<CategoryState> emit) =>
      runAction(emit, (current) async {
        await _repo.updateCategory(event.category.copyWith(name: event.name));
        final categories = await _repo.fetchCategories();
        return current.copyWith(
          categories: categories,
          successMessage: 'Categoria atualizada',
        );
      });

  Future<void> _onDeleted(CategoryDeleted event, Emitter<CategoryState> emit) =>
      runAction(emit, (current) async {
        await _repo.deleteCategory(event.category.id);
        return current.copyWith(
          categories: [
            for (final c in current.categories)
              if (c.id != event.category.id) c,
          ],
          successMessage: 'Categoria "${event.category.name}" eliminada',
        );
      });
}
