import 'package:equatable/equatable.dart';

/// Everything that can happen to Work, as values. Sealed, so the `on<...>`
/// registrations are checked for completeness when a new one is added.
sealed class WorkEvent extends Equatable {
  const WorkEvent();

  @override
  List<Object?> get props => const [];
}

/// Loads the screen. Dispatched when it opens, and again to refresh or retry.
final class WorkStarted extends WorkEvent {
  const WorkStarted();
}

// TODO: one event per action the screen can take.
