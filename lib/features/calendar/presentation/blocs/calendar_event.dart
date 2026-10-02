import 'package:equatable/equatable.dart';

sealed class CalendarEvent extends Equatable {
  const CalendarEvent();

  @override
  List<Object?> get props => const [];
}

/// Loads the screen on today's month. Dispatched when it opens, and again to
/// retry.
final class CalendarStarted extends CalendarEvent {
  const CalendarStarted();
}

/// The calendar turned to show [first] to [last] — load that range's visits.
final class CalendarRangeChanged extends CalendarEvent {
  const CalendarRangeChanged({required this.first, required this.last});

  final DateTime first;
  final DateTime last;

  @override
  List<Object?> get props => [first, last];
}

/// A day was tapped: list its visits under the calendar.
final class CalendarDaySelected extends CalendarEvent {
  const CalendarDaySelected(this.day);

  final DateTime day;

  @override
  List<Object?> get props => [day];
}

/// Reloads the range on screen — after coming back from a work, whose
/// visits may have changed.
final class CalendarRefreshed extends CalendarEvent {
  const CalendarRefreshed();
}
