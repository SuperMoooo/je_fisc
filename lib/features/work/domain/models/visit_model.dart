import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:je_fisc/features/category/domain/models/category_model.dart';

import 'visit_picture_model.dart';

part 'visit_model.freezed.dart';
part 'visit_model.g.dart';

/// What the feature reasons about, and the shape it has on the wire.
///
/// Freezed derives the constructor, `copyWith`, `==` and `hashCode` from the
/// field list, so equality covers every field — none is written here. An
/// `id`-keyed `==` made every draft of a create form compare equal, and a
/// state holder that drops an equal state then dropped every keystroke after
/// the first.
///
/// Run `fvm dart run build_runner build --delete-conflicting-outputs` after
/// editing this file.
@freezed
abstract class VisitModel with _$VisitModel {
  /// Freezed needs a private constructor before a class may declare members
  /// of its own — a getter, or a method that reads the fields.
  const VisitModel._();

  const factory VisitModel({
    required int id,
    required int workId,
    required DateTime date,

    /// Loaded with the visit by `fetchVisits`. Not columns of the `visits`
    /// row, so JSON leaves them out both ways and `toJson()` stays a row the
    /// database can take as-is.
    @Default([])
    @JsonKey(includeFromJson: false, includeToJson: false)
    List<VisitPictureModel> pictures,
    @Default([])
    @JsonKey(includeFromJson: false, includeToJson: false)
    List<CategoryModel> categories,
  }) = _VisitModel;

  factory VisitModel.fromJson(Map<String, dynamic> json) =>
      _$VisitModelFromJson(json);

  /// A blank Visit — what a create form starts from before anything is filled
  /// in. Freezed does not write this one, so it is yours to keep in step with
  /// the fields above.
  factory VisitModel.empty() =>
      VisitModel(id: 0, workId: 0, date: DateTime.now());
}
