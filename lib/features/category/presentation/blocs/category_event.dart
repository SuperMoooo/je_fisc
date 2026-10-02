import 'package:equatable/equatable.dart';

sealed class CategoryEvent extends Equatable {
  const CategoryEvent();

  @override
  List<Object?> get props => const [];
}

/// Loads the screen. Dispatched when it opens, and again to refresh or retry.
final class CategoryStarted extends CategoryEvent {
  const CategoryStarted();
}

/// Adds a category called [name] to the lookup table.
final class CategoryCreated extends CategoryEvent {
  const CategoryCreated(this.name);

  final String name;

  @override
  List<Object?> get props => [name];
}
