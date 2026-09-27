import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import './empty_view.dart';
import './error_view.dart';
import '../../core/utils/app_status.dart';

/// Draws one screen's [AppStatus] as a skeleton, a failure, an empty state or
/// the body.
///
/// ```dart
/// BlocBuilder<HomeBloc, HomeState>(
///   builder: (context, state) => AppStatusView(
///     status: state.status,
///     message: state.errorMessage,
///     onRetry: () => context.read<HomeBloc>().add(const HomeStarted()),
///     isEmpty: state.items.isEmpty,
///     skeleton: (context) => _body(context, HomeState.placeholder),
///     builder: (context) => _body(context, state),
///   ),
/// )
/// ```
///
/// It takes no type parameter and no data: the caller has the state in hand
/// and closes over it, so both builders are plain [WidgetBuilder]s and there
/// is nothing to thread through. It builds inline rather than as a route, so a
/// [Scaffold] keeps its app bar while the content loads.
///
/// **A refresh should not pass [AppStatus.loading].** Doing so trades the body
/// for a skeleton and the screen flickers. Leave the status on
/// [AppStatus.success] and emit the new data when it lands — with one state
/// class per screen the old data is still there to draw, which is the reason
/// the state is shaped that way.
class AppStatusView extends StatelessWidget {
  /// Creates the shell around a screen's [builder].
  const AppStatusView({
    super.key,
    required this.status,
    required this.builder,
    this.skeleton,
    this.isEmpty = false,
    this.emptyTitle,
    this.emptyMessage,
    this.emptyIcon,
    this.emptyActionLabel,
    this.onEmptyAction,
    this.errorTitle,
    this.message,
    this.onRetry,
  });

  /// Which of the four screens to draw. Usually `state.status`.
  final AppStatus status;

  /// The body, drawn on [AppStatus.success].
  final WidgetBuilder builder;

  /// The shape to shimmer while the first load runs, e.g.
  /// `(context) => _body(context, HomeState.placeholder)`. Null shows a
  /// centered spinner instead.
  ///
  /// It has to be built from *fake* data, not an empty state — Skeletonizer
  /// traces the tree it is handed, so a `ListView.builder` over nothing traces
  /// to a blank screen. States from `moarch create feature` carry a
  /// `placeholder` for exactly this.
  final WidgetBuilder? skeleton;

  /// Whether a loaded screen has nothing worth drawing, e.g.
  /// `state.items.isEmpty`. A plain bool rather than a callback: the caller
  /// already has the state.
  final bool isEmpty;

  /// Copy for the empty state. Null keeps [EmptyView]'s own wording.
  final String? emptyTitle;
  final String? emptyMessage;
  final IconData? emptyIcon;
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;

  /// Copy for the failed state. [message] is the state's `errorMessage`.
  final String? errorTitle;
  final String? message;

  /// Passing this is what puts the retry button in [ErrorView]. Usually
  /// re-dispatching the event that loaded the screen.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      AppStatus.initial || AppStatus.loading => _loading(context),
      AppStatus.failure => ErrorView(
          title: errorTitle ?? 'Something went wrong',
          message: message,
          onRetry: onRetry,
        ),
      AppStatus.success when isEmpty => EmptyView(
          title: emptyTitle ?? 'Nothing here yet',
          message: emptyMessage ?? 'No items are available right now.',
          icon: emptyIcon ?? Icons.inbox_outlined,
          actionLabel: emptyActionLabel,
          onAction: onEmptyAction,
        ),
      AppStatus.success => builder(context),
    };
  }

  Widget _loading(BuildContext context) {
    final shape = skeleton;
    if (shape == null) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    return Skeletonizer(child: shape(context));
  }
}
