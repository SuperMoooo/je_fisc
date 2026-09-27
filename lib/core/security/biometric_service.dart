import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/types/auth_messages_ios.dart';

import '../utils/app_logger.dart';

class BiometricService {
  BiometricService([LocalAuthentication? auth])
      : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;
  // True when the device has a lock screen, biometrics enrolled or not.
  Future<bool> canAuthenticate() => _auth.isDeviceSupported();

  Future<bool> authenticate() {
    return _auth.authenticate(
      localizedReason: 'Please authenticate to continue',
      biometricOnly: false,
      authMessages: const <AuthMessages>[
        AndroidAuthMessages(
          signInTitle: 'Authentication required',
          cancelButton: 'Cancel',
        ),
        IOSAuthMessages(cancelButton: 'Cancel'),
      ],
    );
  }

  /// Runs local authentication, reporting failure as a snackbar rather than
  /// throwing, so callers only need the bool.
  Future<bool> verifyUserLocalAuth(BuildContext context) async {
    // Resolved before any await — the prompt can outlive the calling widget.
    final messenger = ScaffoldMessenger.of(context);

    try {
      final didAuthenticate = await authenticate();
      if (!didAuthenticate) {
        _showFeedback(messenger, 'Authentication failed');
        return false;
      }
      return true;
    } on LocalAuthException catch (e) {
      appLogger.e('LocalAuthException: ${e.code.name} - ${e.description}');
      // Device has neither biometrics nor a PIN/pattern/password set up, so
      // there is no local credential to fall back to.
      final message = e.code == LocalAuthExceptionCode.noCredentialsSet
          ? 'Device has no lock method configured'
          : e.description ?? 'Authentication error';
      _showFeedback(messenger, message);
      return false;
    } on PlatformException catch (e) {
      appLogger.e('PlatformException: ${e.message}');
      _showFeedback(messenger, e.message ?? 'Authentication error');
      return false;
    }
  }

  void _showFeedback(ScaffoldMessengerState messenger, String message) {
    // The screen may have been popped while the prompt was up.
    if (!messenger.mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}
