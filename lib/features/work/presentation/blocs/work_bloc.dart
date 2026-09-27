import 'package:bloc/bloc.dart';
import 'package:je_fisc/config/di/injector.dart';
import 'package:je_fisc/core/security/biometric_service.dart';

import '../../../../core/utils/app_status.dart';
import '../../domain/repositories/work_repository.dart';
import 'work_event.dart';
import 'work_state.dart';

class WorkBloc extends Bloc<WorkEvent, WorkState>
    with ActionBlocMixin<WorkEvent, WorkState> {
  WorkBloc(this._repo) : super(const WorkState()) {
    on<WorkStarted>(_onStarted);

    // TODO: one handler per action, e.g.
    // on<WorkDeleted>(_onDeleted, transformer: droppable());
    // `transformer:` is how events queue before the handler sees them —
    // droppable, restartable, sequential, concurrent, from bloc_concurrency.
    // Wrap each handler's body in runAction (from ActionBlocMixin), which
    // handles loading and AppException for you:
    //
    // Future<void> _onDeleted(WorkDeleted event, Emitter<WorkState> emit) =>
    //     runAction(emit, (current) async {
    //       await _repo.delete(event.id);
    //       return current.copyWith(successMessage: 'Deleted');
    //     });
  }

  final WorkRepository _repo;

  Future<void> _onStarted(WorkStarted event, Emitter<WorkState> emit) =>
      runAction(emit, (current) async {
        final authenticated = await getIt<BiometricService>()
            .verifyUserLocalAuth();
        if (!authenticated) {
          return current.copyWith(
            status: AppStatus.failure,
            errorMessage: "Not authenticated",
          );
        }
        await _repo.fetchAll();
        return current.copyWith(status: AppStatus.success);
      });
}
