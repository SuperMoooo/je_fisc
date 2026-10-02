import '../../../../core/network/paginated.dart';
import '../models/backup_import.dart';
import '../models/visit_model.dart';
import '../models/visit_picture_model.dart';
import '../models/work_model.dart';

abstract interface class WorkRepository {
  // Works — flat: a work never carries its visits. Load those with
  // [fetchVisits].
  Future<List<WorkModel>> fetchWorks();

  /// The page of works after the one keyed [next] (null: the first page)
  /// matching [query] — every word of it, in the client name or the address,
  /// ignoring case and accents — newest first. An empty [query] pages through
  /// every work. Pass the returned `next` back as is to get the page after.
  Future<Paginated<WorkModel>> searchWorks({String query = '', Object? next});

  Future<WorkModel?> fetchWork({required int id});
  Future<WorkModel> createWork({required WorkModel work});
  Future<void> updateWork(WorkModel work);

  /// Also deletes the work's visits, with their pictures and categories.
  Future<void> deleteWork(int id);

  // Visits — each comes back with its `pictures` and `categories` filled.

  /// The work's visits, newest first, complete.
  Future<List<VisitModel>> fetchVisits(int workId);

  /// Saves the visit with its `categories`; its `pictures` are ignored — add
  /// them afterwards with [addVisitPicture].
  Future<VisitModel> createVisit(VisitModel visit);

  /// Saves the visit and replaces its categories with `visit.categories`.
  /// Pictures are left alone.
  Future<void> updateVisit(VisitModel visit);

  /// Also deletes the visit's pictures and categories.
  Future<void> deleteVisit(int id);

  // Visit pictures — `picturePath` on what comes back is absolute.

  /// Keeps a copy of the file at [sourcePath], so a picker's temporary file
  /// is fine to pass.
  Future<VisitPictureModel> addVisitPicture(int visitId, String sourcePath);
  Future<void> deleteVisitPicture(int id);

  // Backup

  /// Lets the user save a copy of the whole database on the device. False
  /// when they dismissed the save dialog. Picture files are not included.
  Future<bool> exportBackup();

  /// Lets the user pick a backup [exportBackup] wrote and adds what it holds
  /// that is not here yet — nothing here is changed or removed. Null when
  /// they dismissed the dialog.
  Future<BackupImport?> importBackup();

  // Report

  /// Builds a PDF of the work and every visit — date, categories, notes and
  /// pictures — and lets the user save it. False when they dismissed the
  /// save dialog.
  Future<bool> exportVisitsReport(int workId);
}
