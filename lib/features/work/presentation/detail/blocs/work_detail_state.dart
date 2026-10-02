import 'package:equatable/equatable.dart';
import 'package:je_fisc/features/category/domain/models/category_model.dart';
import 'package:je_fisc/features/work/domain/models/visit_model.dart';
import 'package:je_fisc/features/work/domain/models/work_model.dart';
import 'package:skeletonizer/skeletonizer.dart';

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
    this.work,
    this.visits = const [],
    this.isDeleted = false,
  });

  /// The state the loading skeleton is traced from.
  ///
  /// Every field has fake values — Skeletonizer shimmers the tree it is
  /// handed, and a body drawn from an empty state traces to a blank screen.
  /// `BoneMock` strings' length becomes the width of the bone. `final`, not
  /// `const`: the models hold `DateTime`s.
  static final placeholder = WorkDetailState(
    status: AppStatus.success,
    work: WorkModel(
      id: 0,
      clientName: BoneMock.name,
      address: BoneMock.address,
      startDate: DateTime(2000),
      endDate: DateTime(2000),
    ),
    visits: [
      for (var i = 0; i < 3; i++)
        VisitModel(
          id: i,
          workId: 0,
          date: DateTime(2000),
          categories: [
            CategoryModel(id: 0, name: BoneMock.words(1)),
            CategoryModel(id: 1, name: BoneMock.words(2)),
          ],
        ),
    ],
  );

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

  final WorkModel? work;

  /// The work's visits, newest first, each with its pictures and categories.
  final List<VisitModel> visits;

  /// Set once the work is deleted — the view pops back to the list.
  final bool isDeleted;

  WorkDetailState copyWith({
    AppStatus? status,
    String? errorMessage,
    String? successMessage,
    WorkModel? work,
    List<VisitModel>? visits,
    bool? isDeleted,
  }) {
    return WorkDetailState(
      status: status ?? this.status,
      // Not `?? this.errorMessage`: see the two fields above. A message not
      // passed here is a message already shown.
      errorMessage: errorMessage,
      successMessage: successMessage,
      work: work ?? this.work,
      visits: visits ?? this.visits,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  WorkDetailState withStatus(AppStatus status, {String? errorMessage}) =>
      copyWith(status: status, errorMessage: errorMessage);

  @override
  List<Object?> get props => [
    status,
    errorMessage,
    successMessage,
    work,
    visits,
    isDeleted,
  ];
}
