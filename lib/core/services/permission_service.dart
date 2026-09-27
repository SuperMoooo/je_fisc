import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Request a specific permission.
  Future<bool> request({required Permission permission}) async {
    final status = await permission.status;

    switch (status) {
      case PermissionStatus.granted:
      case PermissionStatus.limited:
        return true;

      case PermissionStatus.denied:
        final response = await permission.request();
        return response.isGranted || response.isLimited;

      case PermissionStatus.permanentlyDenied:
        await openAppSettings();
        final updated = await permission.status;
        return updated.isGranted || updated.isLimited;

      default:
        return false;
    }
  }
}
