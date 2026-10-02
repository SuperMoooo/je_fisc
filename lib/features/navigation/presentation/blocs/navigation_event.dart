import 'package:equatable/equatable.dart';

sealed class NavigationEvent extends Equatable {
  const NavigationEvent();

  @override
  List<Object?> get props => const [];
}

/// Runs the biometric check that opens the app. Dispatched when the shell
/// first builds, and again to retry.
final class NavigationStarted extends NavigationEvent {
  const NavigationStarted();
}
