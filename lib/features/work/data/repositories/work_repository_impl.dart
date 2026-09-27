import '../datasources/work_local_datasource.dart';
import '../../domain/models/work_model.dart';
import '../../domain/repositories/work_repository.dart';

class WorkRepositoryImpl implements WorkRepository {
  const WorkRepositoryImpl(this._local);

  // TODO: read from / write to the cache once it has methods.
  // ignore: unused_field
  final WorkLocalDataSource _local;

  @override
  Future<List<WorkModel>> fetchAll() {
    // TODO: implement using the datasource above
    throw UnimplementedError();
  }
}
