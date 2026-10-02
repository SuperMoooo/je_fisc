import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';

import '../../../../core/security/biometric_service.dart';
import '../../../../core/utils/app_status.dart';
import 'navigation_event.dart';
import 'navigation_state.dart';

/// The lock in front of every tab: one biometric check when the app opens,
/// rather than one per screen.
class NavigationBloc extends Bloc<NavigationEvent, NavigationState>
    with ActionBlocMixin<NavigationEvent, NavigationState> {
  NavigationBloc(this._biometrics) : super(const NavigationState()) {
    on<NavigationStarted>(_onStarted, transformer: droppable());
  }

  final BiometricService _biometrics;

  /// A debug build lets a failed check through, so an emulator with no lock
  /// screen can still reach the app. `kDebugMode` without importing Flutter.
  static const _isDebug = !bool.fromEnvironment('dart.vm.product');

  Future<void> _onStarted(
    NavigationStarted event,
    Emitter<NavigationState> emit,
  ) => runAction(emit, (current) async {
    final authenticated = await _biometrics.verifyUserLocalAuth();
    if (!authenticated && !_isDebug) {
      return current.copyWith(
        status: AppStatus.failure,
        errorMessage: 'Não autenticado',
      );
    }
    return current.copyWith(status: AppStatus.success);
  });
}
