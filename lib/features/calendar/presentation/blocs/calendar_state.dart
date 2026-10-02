import 'package:equatable/equatable.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/utils/app_status.dart';
import '../../domain/models/calendar_visit_model.dart';

class CalendarState extends Equatable implements StatusState<CalendarState> {
  const CalendarState({
    this.status = AppStatus.initial,
    this.errorMessage,
    this.successMessage,
    this.first,
    this.last,
    this.selectedDay,
    this.visits = const [],
  });

  /// The state the loading skeleton is traced from. `final`, not `const`:
  /// the models hold `DateTime`s.
  static final placeholder = CalendarState(
    status: AppStatus.success,
    selectedDay: DateTime(2000),
    visits: [
      for (var i = 0; i < 2; i++)
        CalendarVisitModel(
          id: i,
          workId: 0,
          clientName: BoneMock.name,
          address: BoneMock.address,
          date: DateTime(2000),
        ),
    ],
  );

  @override
  final AppStatus status;

  /// One-shot: [copyWith] clears it unless it is passed again.
  final String? errorMessage;

  /// One-shot, like [errorMessage].
  final String? successMessage;

  /// The days on screen, which [visits] covers. Null before the first load.
  final DateTime? first;
  final DateTime? last;

  /// The tapped day, whose visits are listed under the calendar.
  final DateTime? selectedDay;

  /// Every visit from [first] to [last], in date order.
  final List<CalendarVisitModel> visits;

  /// Visits per day, for the dots under each one. Keyed by the day itself,
  /// so two visits on one day count twice rather than overwriting each other.
  Map<DateTime, int> get visitsPerDay {
    final counts = <DateTime, int>{};
    for (final visit in visits) {
      final day = DateTime(visit.date.year, visit.date.month, visit.date.day);
      counts[day] = (counts[day] ?? 0) + 1;
    }
    return counts;
  }

  /// The visits on [selectedDay].
  List<CalendarVisitModel> get selectedVisits {
    final day = selectedDay;
    if (day == null) return const [];
    return [
      for (final visit in visits)
        if (visit.date.year == day.year &&
            visit.date.month == day.month &&
            visit.date.day == day.day)
          visit,
    ];
  }

  CalendarState copyWith({
    AppStatus? status,
    String? errorMessage,
    String? successMessage,
    DateTime? first,
    DateTime? last,
    DateTime? selectedDay,
    List<CalendarVisitModel>? visits,
  }) {
    return CalendarState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      successMessage: successMessage,
      first: first ?? this.first,
      last: last ?? this.last,
      selectedDay: selectedDay ?? this.selectedDay,
      visits: visits ?? this.visits,
    );
  }

  @override
  CalendarState withStatus(AppStatus status, {String? errorMessage}) =>
      copyWith(status: status, errorMessage: errorMessage);

  @override
  List<Object?> get props => [
    status,
    errorMessage,
    successMessage,
    first,
    last,
    selectedDay,
    visits,
  ];
}
