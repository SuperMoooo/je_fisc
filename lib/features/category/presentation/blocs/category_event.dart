import 'package:equatable/equatable.dart';

import '../../domain/models/category_model.dart';

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

/// Renames [category] to [name].
final class CategoryRenamed extends CategoryEvent {
  const CategoryRenamed(this.category, this.name);

  final CategoryModel category;
  final String name;

  @override
  List<Object?> get props => [category, name];
}

/// Deletes [category]. Refused while a visit is tagged with it.
final class CategoryDeleted extends CategoryEvent {
  const CategoryDeleted(this.category);

  final CategoryModel category;

  @override
  List<Object?> get props => [category];
}
