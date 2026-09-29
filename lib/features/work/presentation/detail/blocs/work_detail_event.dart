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
}

// TODO: one event per action the screen can take.
