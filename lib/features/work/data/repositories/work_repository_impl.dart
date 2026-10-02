import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/paginated.dart';
import '../../domain/models/backup_import.dart';
import '../../domain/models/visit_model.dart';
import '../../domain/models/visit_picture_model.dart';
import '../../domain/models/work_model.dart';
import '../../domain/repositories/work_repository.dart';
import '../datasources/work_local_datasource.dart';
import '../datasources/work_report_datasource.dart';

class WorkRepositoryImpl implements WorkRepository {
  const WorkRepositoryImpl(this._local, this._report);

  final WorkLocalDataSource _local;
  final WorkReportDataSource _report;

  // ── Works ────────────────────────────────────────────────────

  @override
  Future<List<WorkModel>> fetchWorks() => _local.fetchWorks();

  @override
  Future<Paginated<WorkModel>> searchWorks({String query = '', Object? next}) =>
      _local.searchWorks(query: query, next: next);

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

  // ── Backup ───────────────────────────────────────────────────

  @override
  Future<bool> exportBackup() => _local.exportBackup();

  @override
  Future<BackupImport?> importBackup() => _local.importBackup();

  // ── Report ───────────────────────────────────────────────────

  @override
  Future<bool> exportVisitsReport(int workId) async {
    final work = await _local.fetchWork(workId);
    if (work == null) {
      throw const NotFoundException(message: 'Esta obra já não existe.');
    }
    final visits = await _local.fetchVisits(workId);
    return _report.exportVisits(work, visits);
  }
}
