import 'package:equatable/equatable.dart';

import '../../../../../core/utils/app_status.dart';
import '../../../../category/domain/models/category_model.dart';
import '../../../domain/models/visit_model.dart';

/// Everything the VisitCreate screen draws from, in one place.
///
/// A status field rather than a sealed state per phase — see [AppStatus].
/// Being a [StatusState] is what lets the bloc's `runAction` handle its
/// errors.
class VisitCreateState extends Equatable
    implements StatusState<VisitCreateState> {
  const VisitCreateState({
    this.status = AppStatus.initial,
    this.errorMessage,
    this.successMessage,
    this.savedVisitId,
    this.isSubmitting = false,
    this.categories = const [],
    this.visit,
  });

  /// The state the loading skeleton is traced from.
  static const placeholder = VisitCreateState(status: AppStatus.success);

  @override
  final AppStatus status;

  /// Why the last attempt failed — and only the last one: [copyWith] drops
  /// this unless it is passed again, so the next emit clears it.
  final String? errorMessage;

  /// What went right, for the screen to say once. Dropped by [copyWith] like
  /// [errorMessage].
  final String? successMessage;

  /// Set once the visit is saved — the view pops back to the work on it.
  final int? savedVisitId;

  /// A save is in flight — the button spins. Dropped by [copyWith] like the
  /// messages, so whatever `runAction` emits next, success or failure, ends
  /// it without the handler having to.
  final bool isSubmitting;

  /// Every category, alphabetically — what the form picks from.
  final List<CategoryModel> categories;

  /// The visit being edited, as loaded; null when adding one.
  final VisitModel? visit;

  bool get isEditing => visit != null;

  VisitCreateState copyWith({
    AppStatus? status,
    String? errorMessage,
    String? successMessage,
    int? savedVisitId,
    bool? isSubmitting,
    List<CategoryModel>? categories,
    VisitModel? visit,
  }) {
    return VisitCreateState(
      status: status ?? this.status,
      // Not `?? this.errorMessage`: see the two fields above. A message not
      // passed here is a message already shown.
      errorMessage: errorMessage,
      successMessage: successMessage,
      savedVisitId: savedVisitId,
      isSubmitting: isSubmitting ?? false,
      categories: categories ?? this.categories,
      visit: visit ?? this.visit,
    );
  }

  @override
  VisitCreateState withStatus(AppStatus status, {String? errorMessage}) =>
      copyWith(status: status, errorMessage: errorMessage);

  @override
  List<Object?> get props => [
    status,
    errorMessage,
    successMessage,
    savedVisitId,
    isSubmitting,
    categories,
    visit,
  ];
}
