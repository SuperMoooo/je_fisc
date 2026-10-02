import 'package:equatable/equatable.dart';

/// Everything that can happen to Work, as values. Sealed, so the `on<...>`
/// registrations are checked for completeness when a new one is added.
sealed class WorkEvent extends Equatable {
  const WorkEvent();

  @override
  List<Object?> get props => const [];
}

/// Loads the screen's first page of works. Dispatched when it opens, and
/// again to retry. The biometric check is the navigation shell's, before
/// this screen is ever built.
final class WorkStarted extends WorkEvent {
  const WorkStarted();
}

/// Pull-to-refresh: reloads the current search from its first page, over the
/// works already on screen.
final class WorkRefreshed extends WorkEvent {
  const WorkRefreshed();
}

/// The search field changed. The bloc waits for typing to pause before it
/// takes [query], so a word typed quickly is one search, not one per letter.
final class WorkSearchChanged extends WorkEvent {
  const WorkSearchChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

/// The list neared its end and wants the next page — also the retry after a
/// page failed. Sent freely: `PagedBlocMixin.loadMore` ignores it while a
/// page is loading or after the last one.
final class WorkMoreRequested extends WorkEvent {
  const WorkMoreRequested();
}
