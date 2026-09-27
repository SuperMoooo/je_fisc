import '../models/work_model.dart';

abstract interface class WorkRepository {
  Future<List<WorkModel>> fetchAll();

  // TODO: add your other methods
}
