import '../../domain/models/visit_model.dart';
import '../../domain/models/visit_picture_model.dart';
import '../../domain/models/work_model.dart';
import '../../domain/repositories/work_repository.dart';
import '../datasources/work_local_datasource.dart';

class WorkRepositoryImpl implements WorkRepository {
  const WorkRepositoryImpl(this._local);

  final WorkLocalDataSource _local;

  // ── Works ────────────────────────────────────────────────────

  @override
  Future<List<WorkModel>> fetchWorks() => _local.fetchWorks();

  @override
  Future<List<WorkModel>> searchWorks({
    String query = '',
    required int page,
    required int limit,
  }) => _local.searchWorks(query: query, page: page, limit: limit);

  @override
  Future<WorkModel?> fetchWork({required int id}) => _local.fetchWork(id);

  @override
  Future<WorkModel> createWork({required WorkModel work}) =>
      _local.createWork(work);

  @override
  Future<void> updateWork(WorkModel work) => _local.updateWork(work);

  @override
  Future<void> deleteWork(int id) => _local.deleteWork(id);

  // ── Visits ───────────────────────────────────────────────────

  @override
  Future<List<VisitModel>> fetchVisits(int workId) =>
      _local.fetchVisits(workId);

  @override
  Future<VisitModel> createVisit(VisitModel visit) => _local.createVisit(visit);

  @override
  Future<void> updateVisit(VisitModel visit) => _local.updateVisit(visit);

  @override
  Future<void> deleteVisit(int id) => _local.deleteVisit(id);

  // ── Visit pictures ───────────────────────────────────────────

  @override
  Future<VisitPictureModel> addVisitPicture(int visitId, String sourcePath) =>
      _local.addVisitPicture(visitId, sourcePath);

  @override
  Future<void> deleteVisitPicture(int id) => _local.deleteVisitPicture(id);
}
