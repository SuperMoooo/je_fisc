import 'package:freezed_annotation/freezed_annotation.dart';

part 'work_model.freezed.dart';
part 'work_model.g.dart';

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
abstract class WorkModel with _$WorkModel {
  /// Freezed needs a private constructor before a class may declare members
  /// of its own — a getter, or a method that reads the fields.
  const WorkModel._();

  const factory WorkModel({
    required int id,
    required String clientName,
    required String address,
    required DateTime startDate,
    DateTime? endDate,
  }) = _WorkModel;

  factory WorkModel.fromJson(Map<String, dynamic> json) =>
      _$WorkModelFromJson(json);

  /// A blank Work — what a create form starts from before anything is filled
  /// in. Freezed does not write this one, so it is yours to keep in step with
  /// the fields above.
  factory WorkModel.empty() => WorkModel(
    id: 0,
    clientName: '',
    address: '',
    startDate: DateTime.now(),
    endDate: DateTime.now(),
  );
}
