import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';

import '../../../../../core/network/paginated.dart';
import '../../../../../core/utils/app_status.dart';
import '../../../../../core/utils/paged_list.dart';
import '../../../domain/models/work_model.dart';
import '../../../domain/repositories/work_repository.dart';
import 'work_event.dart';
import 'work_state.dart';

class WorkBloc extends Bloc<WorkEvent, WorkState>
    with
        ActionBlocMixin<WorkEvent, WorkState>,
        PagedBlocMixin<WorkEvent, WorkState, WorkModel> {
  WorkBloc(this._repo) : super(const WorkState()) {
    on<WorkStarted>(_onStarted);
    on<WorkRefreshed>(_onRefreshed);
    // restartable: a keystroke cancels the wait started by the one before,
    // so only the last one, once typing pauses, becomes the query.
    on<WorkSearchChanged>(_onSearchChanged, transformer: restartable());
    on<WorkMoreRequested>((event, emit) => loadMore(emit));
    // droppable: a second tap while the save dialog is open does nothing.
    on<WorkBackupRequested>(_onBackupRequested, transformer: droppable());
  }

  final WorkRepository _repo;

  /// How long typing has to pause before the search runs.
  static const _searchDebounce = Duration(milliseconds: 300);

  Future<void> _onStarted(WorkStarted event, Emitter<WorkState> emit) =>
      runAction(emit, (current) async {
        final first = await _repo.searchWorks(query: current.query);
        return current.copyWith(
          status: AppStatus.success,
          works: PagedList.first(first),
        );
      });

  /// The works on screen stay until the new first page lands; a failure is a
  /// toast over them (runAction, from a loaded screen).
  Future<void> _onRefreshed(WorkRefreshed event, Emitter<WorkState> emit) =>
      runAction(emit, (current) async {
        final first = await _repo.searchWorks(query: current.query);
        return current.copyWith(works: PagedList.first(first));
      });

  /// A new search replaces the list with its first page. A page of the old
  /// search still loading is then dropped by [loadMore], since the list it
  /// belonged to is gone.
  Future<void> _onSearchChanged(
    WorkSearchChanged event,
    Emitter<WorkState> emit,
  ) => runAction(emit, (current) async {
    await Future<void>.delayed(_searchDebounce);
    final query = event.query.trim();
    final first = await _repo.searchWorks(query: query);
    return current.copyWith(query: query, works: PagedList.first(first));
  });

  /// The spinner goes up before the save dialog and comes down whatever
  /// happens — a failure keeps the list and shows a toast (runAction).
  Future<void> _onBackupRequested(
    WorkBackupRequested event,
    Emitter<WorkState> emit,
  ) async {
    emit(state.copyWith(isBackingUp: true));
    await runAction(emit, (current) async {
      final saved = await _repo.exportBackup();
      return current.copyWith(
        isBackingUp: false,
        successMessage: saved ? 'Cópia de segurança guardada' : null,
      );
    });
    if (state.isBackingUp) emit(state.copyWith(isBackingUp: false));
  }

  @override
  Future<Paginated<WorkModel>> fetchPage(Object? next) =>
      _repo.searchWorks(query: state.query, next: next);

  @override
  PagedList<WorkModel> pagedOf(WorkState state) => state.works;

  @override
  WorkState withPaged(WorkState state, PagedList<WorkModel> paged) =>
      state.copyWith(works: paged);
}
