import 'package:freezed_annotation/freezed_annotation.dart';

part 'calendar_visit_model.freezed.dart';
part 'calendar_visit_model.g.dart';

/// A visit as the calendar shows it: the day, and enough of its work to say
/// whose it was and to open it.
///
/// Read from `visits` joined to `works`; the keys are the aliases that query
/// gives its columns.
///
/// Run `fvm dart run build_runner build --delete-conflicting-outputs` after
/// editing this file.
@freezed
abstract class CalendarVisitModel with _$CalendarVisitModel {
  const CalendarVisitModel._();

  const factory CalendarVisitModel({
    required int id,
    required int workId,
    required String clientName,
    required String address,
    required DateTime date,
  }) = _CalendarVisitModel;

  factory CalendarVisitModel.fromJson(Map<String, dynamic> json) =>
      _$CalendarVisitModelFromJson(json);

  /// A blank CalendarVisit. Keep it in step with the fields.
  factory CalendarVisitModel.empty() => CalendarVisitModel(
    id: 0,
    workId: 0,
    clientName: '',
    address: '',
    date: DateTime(2000),
  );
}
