import 'package:bloc/bloc.dart';

import '../errors/app_exception.dart';

/// Where a screen is, as one value.
///
/// Every state from `moarch create feature` carries one of these, so the four
/// screens a load can be on are named the same way across the whole app and
/// `AppStatusView` can draw them without knowing which feature it is looking
/// at.
///
/// A phase that belongs to one screen alone — submitting, reordering,
/// uploading — is a field on that screen's state, not a value here. Adding one
/// here would ask every other feature to handle a case it will never emit.
enum AppStatus {
  /// Nothing has been asked for yet. The first frame, before the bloc's
  /// `Started` event is handled.
  initial,

  /// A load is in flight and there is nothing on screen to keep.
  ///
  /// A *refresh* over data already shown is not this: leave the status on
  /// [success] and the body stays put instead of collapsing to a skeleton.
  loading,

  /// The screen has what it needs and can draw.
  success,

  /// The load failed. The state's `errorMessage` says why.
  failure;

  /// Whether nothing has been asked for yet.
  bool get isInitial => this == AppStatus.initial;

  /// Whether a first load is in flight.
  bool get isLoading => this == AppStatus.loading;

  /// Whether the screen has what it needs.
  bool get isSuccess => this == AppStatus.success;

  /// Whether the last load failed.
  bool get isFailure => this == AppStatus.failure;
}

/// Contract for states usable with [ActionBlocMixin.runAction].
///
/// Every state from `moarch create feature` implements it with one line:
/// `copyWith(status: status, errorMessage: errorMessage)`.
abstract interface class StatusState<S> {
  AppStatus get status;
  S withStatus(AppStatus status, {String? errorMessage});
}

/// Shared loading/error handling for bloc event handlers.
///
/// ```dart
/// class MyBloc extends Bloc<MyEvent, MyState>
///     with ActionBlocMixin<MyEvent, MyState> {
///   Future<void> _onSaved(MySaved event, Emitter<MyState> emit) =>
///       runAction(emit, (current) async {
///         await _repo.save(event.item);
///         return current.copyWith(successMessage: 'Saved');
///       });
/// }
/// ```
mixin ActionBlocMixin<E, S extends StatusState<S>> on Bloc<E, S> {
  /// Runs [action] with shared loading/error handling.
  ///
  /// Where the screen already is decides what a run looks like:
  ///
  /// - **Nothing on screen yet** (initial, or a retry after a failure): emits
  ///   [AppStatus.loading] first, and a failure lands on [AppStatus.failure] —
  ///   the error screen with its retry button.
  /// - **Data on screen** ([AppStatus.success]): no loading is emitted, so the
  ///   body stays put, and a failure keeps [AppStatus.success] with only
  ///   `errorMessage` set — a toast, not a blank screen. Show an action's
  ///   progress through a field of the screen's own, e.g. `isSubmitting`.
  ///
  /// [action] receives the pre-action state and returns the next one. A first
  /// load has to return it with `status: AppStatus.success`; an action over
  /// loaded data inherits that status from `current`.
  ///
  /// Anything that is not an [AppException] is still shown as a generic
  /// message, and handed to [addError] so `onError` and the `BlocObserver`
  /// see it rather than it vanishing.
  Future<void> runAction(
    Emitter<S> emit,
    Future<S> Function(S current) action,
  ) async {
    final current = state;
    final loaded = current.status.isSuccess;
    if (!loaded) emit(current.withStatus(AppStatus.loading));
    final failed = loaded ? AppStatus.success : AppStatus.failure;
    try {
      emit(await action(current));
    } on AppException catch (e) {
      emit(current.withStatus(failed, errorMessage: e.message));
    } catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(current.withStatus(failed, errorMessage: 'Erro desconhecido'));
    }
  }
}
