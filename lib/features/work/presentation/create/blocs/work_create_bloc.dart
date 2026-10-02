import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';

import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/utils/app_status.dart';
import '../../../domain/repositories/work_repository.dart';
import 'work_create_event.dart';
import 'work_create_state.dart';

class WorkCreateBloc extends Bloc<WorkCreateEvent, WorkCreateState>
    with ActionBlocMixin<WorkCreateEvent, WorkCreateState> {
  WorkCreateBloc(this._repo) : super(const WorkCreateState()) {
    on<WorkCreateStarted>(_onStarted);
    on<WorkCreateRequested>(_onSave, transformer: droppable());
  }

  final WorkRepository _repo;

  /// Nothing to load for a new work: the empty form is ready at once. An
  /// edit loads the work the form starts from.
  Future<void> _onStarted(
    WorkCreateStarted event,
    Emitter<WorkCreateState> emit,
  ) => runAction(emit, (current) async {
    final id = event.workId;
    if (id == null) return current.copyWith(status: AppStatus.success);
    final work = await _repo.fetchWork(id: id);
    if (work == null) {
      throw const NotFoundException(message: 'Esta obra já não existe.');
    }
    return current.copyWith(status: AppStatus.success, work: work);
  });

  Future<void> _onSave(
    WorkCreateRequested event,
    Emitter<WorkCreateState> emit,
  ) => runAction(emit, (current) async {
    if (event.work.id == 0) {
      final work = await _repo.createWork(work: event.work);
      return current.copyWith(
        status: AppStatus.success,
        createdWorkId: work.id,
      );
    }
    await _repo.updateWork(event.work);
    return current.copyWith(status: AppStatus.success, isUpdated: true);
  });
}
