import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';

import '../../../../../core/utils/app_status.dart';
import '../../../domain/repositories/work_repository.dart';
import 'work_detail_event.dart';
import 'work_detail_state.dart';

class WorkDetailBloc extends Bloc<WorkDetailEvent, WorkDetailState>
    with ActionBlocMixin<WorkDetailEvent, WorkDetailState> {
  WorkDetailBloc(this._repo) : super(const WorkDetailState()) {
    on<WorkDetailStarted>(_onStarted);
    on<WorkDetailDeleted>(_onDeleted, transformer: droppable());
    on<WorkDetailVisitDeleted>(_onVisitDeleted, transformer: droppable());
  }

  final WorkRepository _repo;

  Future<void> _onStarted(
    WorkDetailStarted event,
    Emitter<WorkDetailState> emit,
  ) => runAction(emit, (current) async {
    // One after the other on purpose: `(a, b).wait` would wrap a failure in
    // a ParallelWaitError, which runAction does not recognise as the
    // AppException inside it. Both are local reads, so nothing is lost.
    final work = await _repo.fetchWork(id: event.workId);
    final visits = await _repo.fetchVisits(event.workId);
    return current.copyWith(
      status: AppStatus.success,
      work: work,
      visits: visits,
    );
  });

  /// The view pops back to the list on [WorkDetailState.isDeleted].
  Future<void> _onDeleted(
    WorkDetailDeleted event,
    Emitter<WorkDetailState> emit,
  ) => runAction(emit, (current) async {
    final work = current.work;
    if (work == null) return current;
    await _repo.deleteWork(work.id);
    return current.copyWith(isDeleted: true);
  });

  Future<void> _onVisitDeleted(
    WorkDetailVisitDeleted event,
    Emitter<WorkDetailState> emit,
  ) => runAction(emit, (current) async {
    await _repo.deleteVisit(event.visitId);
    return current.copyWith(
      visits: [
        for (final visit in current.visits)
          if (visit.id != event.visitId) visit,
      ],
      successMessage: 'Visita eliminada',
    );
  });
}
