import 'package:freezed_annotation/freezed_annotation.dart';

part 'work_model.freezed.dart';
part 'work_model.g.dart';

/// What the feature reasons about, and the shape it has on the wire.
///
/// Freezed writes the constructor, `copyWith`, `==` and `hashCode` from the
/// field list below, so equality covers every field you add — which is what a
/// bloc state depends on: `emit` drops a state that compares equal to the
/// current one, so a hand-written `==` that misses a field silently loses the
/// change. Its `copyWith` also tells "not passed" from "passed null", which
/// `?? this.x` cannot.
///
/// json_serializable writes `fromJson` / `toJson` from the same field list.
/// The repository hands this class to the presentation layer as it is, so
/// every field is declared once.
///
/// Run `fvm dart run build_runner build --delete-conflicting-outputs` after
/// editing this file.
@freezed
abstract class WorkModel with _$WorkModel {
  /// Freezed needs a private constructor before a class may declare members
  /// of its own — a getter, or a method that reads the fields.
  const WorkModel._();

  const factory WorkModel({
    required int id,
    // TODO: add your other fields. build.yaml maps `createdAt` to
    // `created_at`; only a key that is not snake_case needs saying:
    // `@JsonKey(name: 'createdAt') DateTime? createdAt,`.
  }) = _WorkModel;

  factory WorkModel.fromJson(Map<String, dynamic> json) =>
      _$WorkModelFromJson(json);

  /// A blank Work — what a create form starts from before anything is filled
  /// in. Freezed does not write this one, so it is yours to keep in step with
  /// the fields above.
  factory WorkModel.empty() => const WorkModel(id: 0);
}
