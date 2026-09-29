import 'dart:async';

import 'package:equatable/equatable.dart';

import '../../../domain/models/work_model.dart';

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

/// The search field changed. The bloc waits for typing to pause before it
/// takes [query], so a word typed quickly is one search, not one per letter.
final class WorkSearchChanged extends WorkEvent {
  const WorkSearchChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

/// The list needs another page — sent by `WorkList`'s fetcher, which awaits
/// [result].
///
/// `MoInfiniteScroll` keeps the pages and asks for them with a function that
/// returns a Future; this event is how that function reaches the repository
/// without the view touching it. The bloc answers with the repository's
/// Future as-is, so a failure reaches the list as the error it shows with its
/// retry button.
final class WorkPageRequested extends WorkEvent {
  WorkPageRequested({
    required this.query,
    required this.page,
    required this.limit,
  });

  final String query;
  final int page;
  final int limit;

  final _completer = Completer<List<WorkModel>>();

  /// Completes with the page, or with the error loading it.
  Future<List<WorkModel>> get result => _completer.future;

  /// Called once, by the bloc.
  void respond(Future<List<WorkModel>> works) => _completer.complete(works);

  @override
  List<Object?> get props => [query, page, limit];
}
