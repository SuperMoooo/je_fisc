import 'package:equatable/equatable.dart';
import 'package:je_fisc/features/work/domain/models/visit_model.dart';

/// Everything that can happen to VisitCreate, as values. Sealed, so the
/// `on<...>` registrations are checked for completeness when a new one is
/// added.
sealed class VisitCreateEvent extends Equatable {
  const VisitCreateEvent();

  @override
  List<Object?> get props => const [];
}

/// Loads the screen. Dispatched when it opens, and again to retry. With a
/// [visitId] the form edits that visit of [workId], and loads it first.
final class VisitCreateStarted extends VisitCreateEvent {
  const VisitCreateStarted({required this.workId, this.visitId});

  final int workId;
  final int? visitId;

  @override
  List<Object?> get props => [workId, visitId];
}

/// Saves [visit] with its categories — adds it when its id is 0, updates it
/// otherwise — then deletes the pictures in [removedPictureIds] and copies
/// in the files at [picturePaths] (straight from a picker is fine).
final class VisitCreateRequested extends VisitCreateEvent {
  const VisitCreateRequested({
    required this.visit,
    this.picturePaths = const [],
    this.removedPictureIds = const [],
  });

  final VisitModel visit;
  final List<String> picturePaths;
  final List<int> removedPictureIds;

  @override
  List<Object?> get props => [visit, picturePaths, removedPictureIds];
}
