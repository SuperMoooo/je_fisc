import '../models/calendar_visit_model.dart';

abstract interface class CalendarRepository {
  /// Every visit from [from] to [to], both days included, in date order.
  Future<List<CalendarVisitModel>> fetchVisits({
    required DateTime from,
    required DateTime to,
  });
}
