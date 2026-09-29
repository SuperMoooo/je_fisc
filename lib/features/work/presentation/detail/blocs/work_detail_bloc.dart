import 'package:bloc/bloc.dart';

import '../../../../../core/utils/app_status.dart';
import '../../../domain/repositories/work_repository.dart';
import 'work_detail_event.dart';
import 'work_detail_state.dart';

class WorkDetailBloc extends Bloc<WorkDetailEvent, WorkDetailState>
    with ActionBlocMixin<WorkDetailEvent, WorkDetailState> {
  WorkDetailBloc(this._repo) : super(const WorkDetailState()) {
    on<WorkDetailStarted>(_onStarted);

    // TODO: one handler per action, e.g.
    // on<WorkDetailDeleted>(_onDeleted, transformer: droppable());
    // `transformer:` is how events queue before the handler sees them —
    // droppable, restartable, sequential, concurrent, from bloc_concurrency.
    // Wrap each handler's body in runAction (from ActionBlocMixin), which
    // handles loading and AppException for you:
    //
    // Future<void> _onDeleted(WorkDetailDeleted event, Emitter<WorkDetailState> emit) =>
    //     runAction(emit, (current) async {
    //       await _repo.delete(event.id);
    //       return current.copyWith(successMessage: 'Deleted');
    //     });
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
}
