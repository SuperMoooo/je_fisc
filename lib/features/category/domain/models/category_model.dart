import 'package:freezed_annotation/freezed_annotation.dart';

part 'category_model.freezed.dart';
part 'category_model.g.dart';

/// One row of the `categories` lookup table — what a visit is tagged with.
///
/// Run `fvm dart run build_runner build --delete-conflicting-outputs` after
/// editing this file.
@freezed
abstract class CategoryModel with _$CategoryModel {
  const CategoryModel._();

  const factory CategoryModel({required int id, required String name}) =
      _CategoryModel;

  factory CategoryModel.fromJson(Map<String, dynamic> json) =>
      _$CategoryModelFromJson(json);

  /// A blank Category for create forms. Keep it in step with the fields.
  factory CategoryModel.empty() => const CategoryModel(id: 0, name: '');
}
