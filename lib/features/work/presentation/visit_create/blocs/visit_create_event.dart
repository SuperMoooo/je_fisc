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

/// Loads the screen. Dispatched when it opens, and again to refresh or retry.
final class VisitCreateStarted extends VisitCreateEvent {
  const VisitCreateStarted();
}

/// Saves [visit] with its categories, then copies in the files at
/// [picturePaths] — straight from a picker is fine.
final class VisitCreateRequested extends VisitCreateEvent {
  const VisitCreateRequested({
    required this.visit,
    this.picturePaths = const [],
  });

  final VisitModel visit;
  final List<String> picturePaths;

  @override
  List<Object?> get props => [visit, picturePaths];
}
