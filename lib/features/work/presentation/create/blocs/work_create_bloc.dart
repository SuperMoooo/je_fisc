import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';

import '../../../../../core/utils/app_status.dart';
import '../../../domain/repositories/work_repository.dart';
import 'work_create_event.dart';
import 'work_create_state.dart';

class WorkCreateBloc extends Bloc<WorkCreateEvent, WorkCreateState>
    with ActionBlocMixin<WorkCreateEvent, WorkCreateState> {
  WorkCreateBloc(this._repo) : super(const WorkCreateState()) {
    on<WorkCreateRequested>(_onCreate, transformer: droppable());
  }

  final WorkRepository _repo;

  Future<void> _onCreate(
    WorkCreateRequested event,
    Emitter<WorkCreateState> emit,
  ) => runAction(emit, (current) async {
    final work = await _repo.createWork(work: event.work);
    return current.copyWith(status: AppStatus.success, createdWorkId: work.id);
  });
}
