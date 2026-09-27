import 'package:bloc/bloc.dart';

import '../../../../../core/utils/app_status.dart';
import '../../../domain/repositories/work_repository.dart';
import 'work_create_event.dart';
import 'work_create_state.dart';

class WorkCreateBloc extends Bloc<WorkCreateEvent, WorkCreateState>
    with ActionBlocMixin<WorkCreateEvent, WorkCreateState> {
  WorkCreateBloc(this._repo) : super(const WorkCreateState()) {
    on<WorkCreateStarted>(_onStarted);

    // TODO: one handler per action, e.g.
    // on<WorkCreateDeleted>(_onDeleted, transformer: droppable());
    // `transformer:` is how events queue before the handler sees them —
    // droppable, restartable, sequential, concurrent, from bloc_concurrency.
    // Wrap each handler's body in runAction (from ActionBlocMixin), which
    // handles loading and AppException for you:
    //
    // Future<void> _onDeleted(WorkCreateDeleted event, Emitter<WorkCreateState> emit) =>
    //     runAction(emit, (current) async {
    //       await _repo.delete(event.id);
    //       return current.copyWith(successMessage: 'Deleted');
    //     });
  }

  final WorkRepository _repo;

  Future<void> _onStarted(
    WorkCreateStarted event,
    Emitter<WorkCreateState> emit,
  ) => runAction(emit, (current) async {
    // TODO: put what this returns onto the state — add a field for it in
    // WorkCreateState, and pass it in the copyWith below.
    await _repo.fetchAll();
    return current.copyWith(status: AppStatus.success);
  });
}
