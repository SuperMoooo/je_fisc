import 'package:sqflite/sqflite.dart';

import 'package:je_fisc/core/database/app_database.dart';
import 'package:je_fisc/core/database/safe_db_call.dart';
import 'package:je_fisc/features/calendar/domain/models/calendar_visit_model.dart';

/// Visits by date, across every work — the `visits` table of [AppDatabase]
/// joined to `works`.
///
/// Every call goes through [safeDbCall], so a sqflite error leaves here as an
/// `AppException`.
class CalendarLocalDataSource {
  const CalendarLocalDataSource(this._db);

  final Database _db;

  /// Every visit from [from] to [to], both days included, in date order.
  ///
  /// `visits.date` is an ISO-8601 string, which sorts the way the dates do,
  /// so the range is a plain string comparison: from the start of [from] to
  /// before the start of the day after [to].
  Future<List<CalendarVisitModel>> fetchVisits({
    required DateTime from,
    required DateTime to,
  }) => safeDbCall(() async {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day + 1);
    final rows = await _db.rawQuery(
      'SELECT v.id, v.work_id, v.date, w.client_name, w.address '
      'FROM ${Tables.visits} v '
      'JOIN ${Tables.works} w ON w.id = v.work_id '
      'WHERE v.date >= ? AND v.date < ? '
      'ORDER BY v.date, w.client_name',
      [start.toIso8601String(), end.toIso8601String()],
    );
    return rows.map(CalendarVisitModel.fromJson).toList();
  });
}
