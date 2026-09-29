import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Files the app keeps for good — pictures taken on a visit, attachments —
/// under the app's documents directory.
///
/// What a picker returns lives in a cache the OS may clear, so anything a
/// database row points at is copied in here first. Paths handed out by [save]
/// are **relative**: on iOS the documents directory moves on every app
/// update, so an absolute path stored in a row would stop resolving. Store
/// the relative path, and [resolve] it when reading.
class LocalFileStore {
  Directory? _root;

  Future<Directory> get _documents async =>
      _root ??= await getApplicationDocumentsDirectory();

  /// Copies [sourcePath] into [folder] under a fresh name and returns the
  /// copy's path relative to the documents directory.
  Future<String> save(String sourcePath, {required String folder}) async {
    final root = await _documents;
    final name =
        '${DateTime.now().microsecondsSinceEpoch}${p.extension(sourcePath)}';
    final relative = p.join(folder, name);
    final target = File(p.join(root.path, relative));
    await target.parent.create(recursive: true);
    await File(sourcePath).copy(target.path);
    return relative;
  }

  /// The absolute path of a file [save] returned.
  Future<String> resolve(String relativePath) async =>
      p.join((await _documents).path, relativePath);

  /// Deletes the files [save] returned. A file already gone is not an error.
  Future<void> delete(Iterable<String> relativePaths) async {
    for (final relative in relativePaths) {
      final file = File(await resolve(relative));
      if (await file.exists()) await file.delete();
    }
  }
}
