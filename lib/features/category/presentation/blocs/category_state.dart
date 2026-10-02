import 'package:equatable/equatable.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/utils/app_status.dart';
import '../../domain/models/category_model.dart';

class CategoryState extends Equatable implements StatusState<CategoryState> {
  const CategoryState({
    this.status = AppStatus.initial,
    this.errorMessage,
    this.successMessage,
    this.categories = const [],
  });

  /// The state the loading skeleton is traced from.
  static final placeholder = CategoryState(
    status: AppStatus.success,
    categories: [
      for (var i = 0; i < 10; i++) CategoryModel(id: i, name: BoneMock.title),
    ],
  );

  @override
  final AppStatus status;

  /// One-shot: [copyWith] clears it unless it is passed again.
  final String? errorMessage;

  /// One-shot, like [errorMessage].
  final String? successMessage;

  /// Every category, alphabetically.
  final List<CategoryModel> categories;

  CategoryState copyWith({
    AppStatus? status,
    String? errorMessage,
    String? successMessage,
    List<CategoryModel>? categories,
  }) {
    return CategoryState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      successMessage: successMessage,
      categories: categories ?? this.categories,
    );
  }

  @override
  CategoryState withStatus(AppStatus status, {String? errorMessage}) =>
      copyWith(status: status, errorMessage: errorMessage);

  @override
  List<Object?> get props => [status, errorMessage, successMessage, categories];
}
