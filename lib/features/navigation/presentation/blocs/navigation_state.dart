import 'package:equatable/equatable.dart';

import '../../../../core/utils/app_status.dart';

/// Whether the app is unlocked. `success` shows the tabs; anything before it
/// shows the check, and `failure` its retry.
class NavigationState extends Equatable
    implements StatusState<NavigationState> {
  const NavigationState({
    this.status = AppStatus.initial,
    this.errorMessage,
    this.successMessage,
  });

  @override
  final AppStatus status;

  /// One-shot: [copyWith] clears it unless it is passed again.
  final String? errorMessage;

  /// One-shot, like [errorMessage].
  final String? successMessage;

  NavigationState copyWith({
    AppStatus? status,
    String? errorMessage,
    String? successMessage,
  }) {
    return NavigationState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  NavigationState withStatus(AppStatus status, {String? errorMessage}) =>
      copyWith(status: status, errorMessage: errorMessage);

  @override
  List<Object?> get props => [status, errorMessage, successMessage];
}
