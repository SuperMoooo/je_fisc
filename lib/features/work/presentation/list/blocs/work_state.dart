import 'package:equatable/equatable.dart';

import '../../../../../core/utils/app_status.dart';
import '../../../../../core/utils/paged_list.dart';
import '../../../domain/models/work_model.dart';

/// Everything the Work screen draws from, in one place.
///
/// A status field rather than a sealed state per phase: `_body` in the view is
/// handed this same class whatever the status is, so a field added here is
/// added once and every phase can draw it. Showing a spinner over the list
/// already on screen is a `copyWith` with the status moved to `loading` —
/// there is nothing to re-declare. The status itself is [AppStatus], shared by
/// every screen, which is what lets `AppStatusView` draw it — and being a
/// [StatusState] is what lets the bloc's `runAction` handle its errors.
///
/// The works are a [PagedList]: the first page loads with the screen (or with
/// a new search), and `PagedBlocMixin` appends the pages after it as
/// `WorkList` scrolls.
class WorkState extends Equatable implements StatusState<WorkState> {
  const WorkState({
    this.status = AppStatus.initial,
    this.errorMessage,
    this.successMessage,
    this.query = '',
    this.works = const PagedList(),
    this.isBackingUp = false,
  });

  /// The state the loading skeleton is traced from. The skeleton draws fake
  /// works of its own (`WorkListSkeleton`), so [works] stays empty here.
  static const placeholder = WorkState(status: AppStatus.success);

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

  /// The search the list is showing, trimmed. Empty shows every work.
  final String query;

  /// The works matching [query] loaded so far, and where paging through them
  /// is — the next page's key, and whether it is loading or failed.
  final PagedList<WorkModel> works;

  /// A backup is being written — the Backup button shows a spinner.
  final bool isBackingUp;

  WorkState copyWith({
    AppStatus? status,
    String? errorMessage,
    String? successMessage,
    String? query,
    PagedList<WorkModel>? works,
    bool? isBackingUp,
  }) {
    return WorkState(
      status: status ?? this.status,
      // Not `?? this.errorMessage`: see the two fields above. A message not
      // passed here is a message already shown.
      errorMessage: errorMessage,
      successMessage: successMessage,
      query: query ?? this.query,
      works: works ?? this.works,
      isBackingUp: isBackingUp ?? this.isBackingUp,
    );
  }

  @override
  WorkState withStatus(AppStatus status, {String? errorMessage}) =>
      copyWith(status: status, errorMessage: errorMessage);

  @override
  List<Object?> get props => [
    status,
    errorMessage,
    successMessage,
    query,
    works,
    isBackingUp,
  ];
}
