import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';

import '../../../../../core/utils/app_status.dart';
import '../../../../category/domain/repositories/category_repository.dart';
import '../../../domain/repositories/work_repository.dart';
import 'visit_create_event.dart';
import 'visit_create_state.dart';

class VisitCreateBloc extends Bloc<VisitCreateEvent, VisitCreateState>
    with ActionBlocMixin<VisitCreateEvent, VisitCreateState> {
  VisitCreateBloc(this._repo, this._categories)
    : super(const VisitCreateState()) {
    on<VisitCreateStarted>(_onStarted);
    on<VisitCreateRequested>(_onCreate, transformer: droppable());
  }

  final WorkRepository _repo;
  final CategoryRepository _categories;

  /// The categories the form picks from.
  Future<void> _onStarted(
    VisitCreateStarted event,
    Emitter<VisitCreateState> emit,
  ) => runAction(emit, (current) async {
    final categories = await _categories.fetchCategories();
    return current.copyWith(status: AppStatus.success, categories: categories);
  });

  Future<void> _onCreate(
    VisitCreateRequested event,
    Emitter<VisitCreateState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true));
    await runAction(emit, (current) async {
      final visit = await _repo.createVisit(event.visit);
      // createVisit ignores `pictures`: each file is copied in on its own.
      for (final path in event.picturePaths) {
        await _repo.addVisitPicture(visit.id, path);
      }
      return current.copyWith(
        status: AppStatus.success,
        createdVisitId: visit.id,
      );
    });
  }
}
