import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';

import '../../../../core/utils/app_status.dart';
import '../../domain/repositories/calendar_repository.dart';
import 'calendar_event.dart';
import 'calendar_state.dart';

class CalendarBloc extends Bloc<CalendarEvent, CalendarState>
    with ActionBlocMixin<CalendarEvent, CalendarState> {
  CalendarBloc(this._repo) : super(const CalendarState()) {
    on<CalendarStarted>(_onStarted);
    // restartable: swiping through months quickly only loads the last one.
    on<CalendarRangeChanged>(_onRangeChanged, transformer: restartable());
    on<CalendarDaySelected>(
      (event, emit) => emit(state.copyWith(selectedDay: event.day)),
    );
    on<CalendarRefreshed>(_onRefreshed, transformer: restartable());
  }

  final CalendarRepository _repo;

  Future<void> _onStarted(CalendarStarted event, Emitter<CalendarState> emit) =>
      runAction(emit, (current) async {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final first = DateTime(now.year, now.month);
        final last = DateTime(now.year, now.month + 1, 0);
        final visits = await _repo.fetchVisits(from: first, to: last);
        return current.copyWith(
          status: AppStatus.success,
          first: first,
          last: last,
          selectedDay: current.selectedDay ?? today,
          visits: visits,
        );
      });

  /// The month on screen stays until the new one lands; a failure is a toast
  /// over it (runAction, from a loaded screen).
  Future<void> _onRangeChanged(
    CalendarRangeChanged event,
    Emitter<CalendarState> emit,
  ) => runAction(emit, (current) async {
    final visits = await _repo.fetchVisits(from: event.first, to: event.last);
    return current.copyWith(
      first: event.first,
      last: event.last,
      visits: visits,
    );
  });

  Future<void> _onRefreshed(
    CalendarRefreshed event,
    Emitter<CalendarState> emit,
  ) => runAction(emit, (current) async {
    final first = current.first;
    final last = current.last;
    if (first == null || last == null) return current;
    final visits = await _repo.fetchVisits(from: first, to: last);
    return current.copyWith(visits: visits);
  });
}
