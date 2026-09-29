import 'package:equatable/equatable.dart';
import 'package:je_fisc/features/work/domain/models/work_model.dart';

/// Everything that can happen to WorkCreate, as values. Sealed, so the `on<...>`
/// registrations are checked for completeness when a new one is added.
sealed class WorkCreateEvent extends Equatable {
  const WorkCreateEvent();

  @override
  List<Object?> get props => const [];
}

/// Loads the screen. Dispatched when it opens, and again to refresh or retry.
final class WorkCreateStarted extends WorkCreateEvent {
  const WorkCreateStarted();
}

final class WorkCreateRequested extends WorkCreateEvent {
  const WorkCreateRequested({required this.work});
  final WorkModel work;
}

// TODO: one event per action the screen can take.
