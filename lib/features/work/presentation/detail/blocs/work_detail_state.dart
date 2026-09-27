import 'package:equatable/equatable.dart';

import '../../../../../core/utils/app_status.dart';

/// Everything the WorkDetail screen draws from, in one place.
///
/// A status field rather than a sealed state per phase: `_body` in the view is
/// handed this same class whatever the status is, so a field added here is
/// added once and every phase can draw it. Showing a spinner over the list
/// already on screen is a `copyWith` with the status moved to `loading` —
/// there is nothing to re-declare. The status itself is [AppStatus], shared by
/// every screen, which is what lets `AppStatusView` draw it — and being a
/// [StatusState] is what lets the bloc's `runAction` handle its errors.
class WorkDetailState extends Equatable
    implements StatusState<WorkDetailState> {
  const WorkDetailState({
    this.status = AppStatus.initial,
    this.errorMessage,
    this.successMessage,
  });

  /// The state the loading skeleton is traced from.
  ///
  /// TODO: as you add fields, give them fake values here — Skeletonizer
  /// shimmers the tree it is handed, and a body drawn from an empty state
  /// traces to a blank screen. `BoneMock.name` / `BoneMock.words(3)`
  /// (skeletonizer) hand out strings whose length becomes the width of the
  /// bone.
  static const placeholder = WorkDetailState(status: AppStatus.success);

  @override
  final AppStatus status;

  /// Why the last attempt failed — and only the last one: [copyWith] drops
  /// this unless it is passed again, so the next emit clears it. That is what
  /// makes it safe to both draw it (the failure screen) and fire it once (a
  /// toast), and it means an action that fails without blanking the screen is
  /// `copyWith(errorMessage: e.message)` with the status left on success.
  final String? errorMessage;

  /// What went right, for the screen to say once — 'Saved', 'Sent'. Dropped
  /// by [copyWith] like [errorMessage], so the toast fires on the emit that
  /// sets it and not on the next one.
  final String? successMessage;

  // TODO: add what the screen shows, e.g.
  // `final List<WorkDetailModel> items;`. A field has to reach four places: the
  // constructor, `copyWith`, `props` — without which two states compare equal
  // and the second emit is dropped — and `placeholder`.

  WorkDetailState copyWith({
    AppStatus? status,
    String? errorMessage,
    String? successMessage,
  }) {
    return WorkDetailState(
      status: status ?? this.status,
      // Not `?? this.errorMessage`: see the two fields above. A message not
      // passed here is a message already shown.
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  WorkDetailState withStatus(AppStatus status, {String? errorMessage}) =>
      copyWith(status: status, errorMessage: errorMessage);

  @override
  List<Object?> get props => [status, errorMessage, successMessage];
}
