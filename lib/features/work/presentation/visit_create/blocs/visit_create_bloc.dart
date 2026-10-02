import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';

import '../../../../../core/errors/app_exception.dart';
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
    on<VisitCreateRequested>(_onSave, transformer: droppable());
  }

  final WorkRepository _repo;
  final CategoryRepository _categories;

  /// The categories the form picks from, and the visit being edited if any.
  /// One after the other, like `WorkDetailBloc`: `.wait` would wrap an
  /// [AppException] in a ParallelWaitError.
  Future<void> _onStarted(
    VisitCreateStarted event,
    Emitter<VisitCreateState> emit,
  ) => runAction(emit, (current) async {
    final categories = await _categories.fetchCategories();
    final visitId = event.visitId;
    if (visitId == null) {
      return current.copyWith(
        status: AppStatus.success,
        categories: categories,
      );
    }
    final visits = await _repo.fetchVisits(event.workId);
    final visit = visits.where((v) => v.id == visitId).firstOrNull;
    if (visit == null) {
      throw const NotFoundException(message: 'Esta visita já não existe.');
    }
    return current.copyWith(
      status: AppStatus.success,
      categories: categories,
      visit: visit,
    );
  });

  Future<void> _onSave(
    VisitCreateRequested event,
    Emitter<VisitCreateState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true));
    await runAction(emit, (current) async {
      var visit = event.visit;
      if (visit.id == 0) {
        visit = await _repo.createVisit(visit);
      } else {
        await _repo.updateVisit(visit);
      }
      for (final id in event.removedPictureIds) {
        await _repo.deleteVisitPicture(id);
      }
      // createVisit and updateVisit ignore `pictures`: each file is copied
      // in on its own.
      for (final path in event.picturePaths) {
        await _repo.addVisitPicture(visit.id, path);
      }
      return current.copyWith(
        status: AppStatus.success,
        savedVisitId: visit.id,
      );
    });
  }
}
