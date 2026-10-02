import 'package:equatable/equatable.dart';

/// Everything that can happen to WorkDetail, as values. Sealed, so the `on<...>`
/// registrations are checked for completeness when a new one is added.
sealed class WorkDetailEvent extends Equatable {
  const WorkDetailEvent();

  @override
  List<Object?> get props => const [];
}

/// Loads the screen. Dispatched when it opens, and again to refresh or retry.
final class WorkDetailStarted extends WorkDetailEvent {
  const WorkDetailStarted({required this.workId});

  final int workId;

  @override
  List<Object?> get props => [workId];
}

/// Deletes the work on screen, with its visits and their pictures.
final class WorkDetailDeleted extends WorkDetailEvent {
  const WorkDetailDeleted();
}

/// Builds the PDF report of the work's visits and asks where to save it.
final class WorkDetailReportRequested extends WorkDetailEvent {
  const WorkDetailReportRequested();
}

/// Deletes one of the work's visits, with its pictures.
final class WorkDetailVisitDeleted extends WorkDetailEvent {
  const WorkDetailVisitDeleted(this.visitId);

  final int visitId;

  @override
  List<Object?> get props => [visitId];
}
