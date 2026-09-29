import 'package:sqflite/sqflite.dart' as sqflite;

import '../errors/app_exception.dart';
import '../utils/app_logger.dart';

/// Runs one database call and turns whatever it throws into an
/// [AppException], so nothing above the datasource sees a sqflite type.
///
/// ```dart
/// Future<List<WorkModel>> fetchWorks() => safeDbCall(() async {
///   final rows = await _db.query(Tables.works);
///   return rows.map(WorkModel.fromJson).toList();
/// });
/// ```
Future<T> safeDbCall<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on AppException {
    rethrow;
  } on sqflite.DatabaseException catch (e, st) {
    appLogger.e('[Database] — $e', error: e, stackTrace: st);
    throw StorageException(message: _messageFor(e));
  } catch (e, st) {
    throw AppException.fromError(e, st);
  }
}

String _messageFor(sqflite.DatabaseException e) {
  if (e.isUniqueConstraintError()) return 'Este registo já existe.';
  if (e.isNotNullConstraintError()) {
    return 'Falta preencher um campo obrigatório.';
  }
  // sqflite has no helper for this one; SQLite's message is stable.
  if (e.toString().contains('FOREIGN KEY constraint failed')) {
    return 'O registo a que isto pertence já não existe.';
  }
  if (e.isDatabaseClosedError()) return 'A base de dados local está fechada.';
  return 'Não foi possível aceder aos dados locais.';
}
