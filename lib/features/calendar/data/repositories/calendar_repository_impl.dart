import '../datasources/calendar_local_datasource.dart';
import '../../domain/models/calendar_visit_model.dart';
import '../../domain/repositories/calendar_repository.dart';

class CalendarRepositoryImpl implements CalendarRepository {
  const CalendarRepositoryImpl(this._local);

  final CalendarLocalDataSource _local;

  @override
  Future<List<CalendarVisitModel>> fetchVisits({
    required DateTime from,
    required DateTime to,
  }) => _local.fetchVisits(from: from, to: to);
}
