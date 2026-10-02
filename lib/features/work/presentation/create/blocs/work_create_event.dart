import 'package:equatable/equatable.dart';
import 'package:je_fisc/features/work/domain/models/work_model.dart';

/// Everything that can happen to WorkCreate, as values. Sealed, so the `on<...>`
/// registrations are checked for completeness when a new one is added.
sealed class WorkCreateEvent extends Equatable {
  const WorkCreateEvent();

  @override
  List<Object?> get props => const [];
}

/// Loads the screen. Dispatched when it opens, and again to retry. With a
/// [workId] the form edits that work, and loads it first; without one it
/// adds a new work.
final class WorkCreateStarted extends WorkCreateEvent {
  const WorkCreateStarted({this.workId});

  final int? workId;

  @override
  List<Object?> get props => [workId];
}

/// Saves [work]: adds it when its id is 0, updates it otherwise.
final class WorkCreateRequested extends WorkCreateEvent {
  const WorkCreateRequested({required this.work});
  final WorkModel work;

  @override
  List<Object?> get props => [work];
}
