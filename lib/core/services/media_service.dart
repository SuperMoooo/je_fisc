import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import 'permission_service.dart';

class MediaService {
  MediaService(this._permissionService);

  final PermissionService _permissionService;
  final ImagePicker _imagePicker = ImagePicker();

  /// Pick an image from gallery or camera.
  Future<File?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    if (source == ImageSource.camera) {
      final granted = await _permissionService.request(
        permission: Permission.camera,
      );
      if (!granted) {
        return null;
      }
    } else if (Platform.isAndroid || Platform.isIOS) {
      final granted = await _permissionService.request(
        permission: Permission.photos,
      );
      if (!granted) {
        return null;
      }
    }

    final XFile? file = await _imagePicker.pickImage(
      source: source,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );

    return file != null ? File(file.path) : null;
  }

  /// Pick multiple images from gallery.
  Future<List<File>?> pickMultiImage({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    if (Platform.isAndroid || Platform.isIOS) {
      final granted = await _permissionService.request(
        permission: Permission.photos,
      );
      if (!granted) {
        return null;
      }
    }

    final List<XFile> files = await _imagePicker.pickMultiImage(
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );

    return files.map((file) => File(file.path)).toList();
  }

  /// Pick a video from gallery or camera.
  Future<File?> pickVideo({
    required ImageSource source,
    Duration? maxDuration,
  }) async {
    if (source == ImageSource.camera) {
      final granted = await _permissionService.request(
        permission: Permission.camera,
      );
      if (!granted) {
        return null;
      }
    } else if (Platform.isAndroid || Platform.isIOS) {
      final granted = await _permissionService.request(
        permission: Permission.photos,
      );
      if (!granted) {
        return null;
      }
    }

    final XFile? file = await _imagePicker.pickVideo(
      source: source,
      maxDuration: maxDuration,
    );

    return file != null ? File(file.path) : null;
  }

  /// Pick one or more files from the device.
  Future<List<File>?> pickFiles({
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    bool allowMultiple = false,
  }) async {
    if (Platform.isAndroid) {
      final granted = await _permissionService.request(
        permission: Permission.photos,
      );
      if (!granted) {
        return null;
      }
    }

    // Static since file_picker 11 — `FilePicker.platform` was the entry point
    // up to 10.x — and returning the files directly since 12, which dropped
    // the `FilePickerResult` wrapper. A cancelled dialog is an empty list.
    //
    // Two entry points rather than `pickFiles(allowMultiple: false)`: that
    // flag is deprecated and goes away in a later file_picker.
    final List<PlatformFile> files;
    if (allowMultiple) {
      files = await FilePicker.pickFiles(
        type: type,
        allowedExtensions: allowedExtensions,
      );
    } else {
      final PlatformFile? file = await FilePicker.pickFile(
        type: type,
        allowedExtensions: allowedExtensions,
      );
      files = file == null ? const [] : [file];
    }

    // `path` is null for a file that is not on local disk — a web pick, or a
    // cloud provider's document on Android. Read those through `readAsBytes`
    // or `xFile` instead; there is no `File` to hand back.
    return files
        .where((file) => file.path != null)
        .map((file) => File(file.path!))
        .toList();
  }
}
