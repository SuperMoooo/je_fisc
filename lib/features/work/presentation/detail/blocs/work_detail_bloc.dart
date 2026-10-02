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
    // droppable: a second tap while the report is built does nothing.
    on<WorkDetailReportRequested>(_onReportRequested, transformer: droppable());
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

  /// The spinner goes up before the report is built and comes down whatever
  /// happens — a failure keeps the screen and shows a toast (runAction).
  Future<void> _onReportRequested(
    WorkDetailReportRequested event,
    Emitter<WorkDetailState> emit,
  ) async {
    final work = state.work;
    if (work == null) return;
    emit(state.copyWith(isExportingReport: true));
    await runAction(emit, (current) async {
      final saved = await _repo.exportVisitsReport(work.id);
      return current.copyWith(
        isExportingReport: false,
        successMessage: saved ? 'Relatório PDF guardado' : null,
      );
    });
    if (state.isExportingReport) {
      emit(state.copyWith(isExportingReport: false));
    }
  }

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
