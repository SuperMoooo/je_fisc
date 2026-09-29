import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:je_fisc/config/di/injector.dart';
import 'package:je_fisc/core/security/biometric_service.dart';

import '../../../../../core/utils/app_status.dart';
import '../../../domain/repositories/work_repository.dart';
import 'work_event.dart';
import 'work_state.dart';

class WorkBloc extends Bloc<WorkEvent, WorkState>
    with ActionBlocMixin<WorkEvent, WorkState> {
  WorkBloc(this._repo) : super(const WorkState()) {
    on<WorkStarted>(_onStarted);
    // restartable: a keystroke cancels the wait started by the one before,
    // so only the last one, once typing pauses, becomes the query.
    on<WorkSearchChanged>(_onSearchChanged, transformer: restartable());
    on<WorkPageRequested>(_onPageRequested);
  }

  final WorkRepository _repo;

  /// How long typing has to pause before the search runs.
  static const _searchDebounce = Duration(milliseconds: 300);

  Future<void> _onStarted(WorkStarted event, Emitter<WorkState> emit) =>
      runAction(emit, (current) async {
        final authenticated = await getIt<BiometricService>()
            .verifyUserLocalAuth();
        if (!authenticated) {
          return current.copyWith(
            status: AppStatus.failure,
            errorMessage: "Não autenticado",
          );
        }
        return current.copyWith(status: AppStatus.success);
      });

  Future<void> _onSearchChanged(
    WorkSearchChanged event,
    Emitter<WorkState> emit,
  ) => runAction(emit, (current) async {
    await Future<void>.delayed(_searchDebounce);
    return current.copyWith(query: event.query.trim());
  });

  /// Not through runAction, on purpose: this handler emits nothing. It hands
  /// the repository's Future to the list, whose own loading row, error row
  /// and retry button show it. runAction would add a second error display,
  /// and would re-emit the state it started from — undoing a search typed
  /// while the page was loading.
  void _onPageRequested(WorkPageRequested event, Emitter<WorkState> emit) {
    event.respond(
      _repo.searchWorks(
        query: event.query,
        page: event.page,
        limit: event.limit,
      ),
    );
  }
}
