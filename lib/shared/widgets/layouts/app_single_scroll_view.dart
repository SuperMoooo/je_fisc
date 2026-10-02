import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';

/// The standard scrollable page body: one [SingleChildScrollView] with the
/// safe area, the page padding and the keyboard behaviour already decided, so
/// screens stop re-deciding them one at a time.
///
/// ```dart
/// Scaffold(
///   appBar: const AppAppBar(title: 'Profile'),
///   // The app bar already ate the top inset, so the body doesn't inset again.
///   body: AppSingleScrollView(
///     safeAreaTop: false,
///     child: Column(children: [...]),
///   ),
/// )
/// ```
///
/// Vertical by design — it is a page scroller, not a general-purpose one. And
/// it builds its whole [child] whether or not any of it is on screen, so for a
/// long or repeating list reach for `ListView.builder` instead.
class AppSingleScrollView extends StatelessWidget {
  const AppSingleScrollView({
    super.key,
    required this.child,
    this.padding = AppConstants.paddingPage,
    this.safeArea = true,
    this.safeAreaTop = true,
    this.safeAreaBottom = true,
    this.safeAreaHorizontal = true,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.onDrag,
    this.avoidKeyboard = false,
    this.fillViewport = false,
    this.alwaysScrollable = false,
    this.physics,
    this.controller,
    this.reverse = false,
  });

  final Widget child;

  /// Inset around [child], inside the safe area.
  final EdgeInsets padding;

  /// Master switch for the safe area. Off means the content runs under the
  /// notch, the status bar and the home indicator — for a screen that paints
  /// itself edge to edge and insets whatever needs it by hand.
  final bool safeArea;

  /// Whether the top inset is honoured. Set false under an [AppBar]: it has
  /// already consumed the status bar, and insetting twice leaves a gap.
  final bool safeAreaTop;

  /// Whether the bottom inset is honoured — the home indicator, mainly. Set
  /// false when a bottom bar or a pinned footer below this one already takes
  /// it.
  final bool safeAreaBottom;

  /// Whether the side insets are honoured. They only amount to anything in
  /// landscape on a notched phone, which is exactly when they matter.
  final bool safeAreaHorizontal;

  /// What dragging does to an open keyboard.
  /// [ScrollViewKeyboardDismissBehavior.onDrag] — the default — closes it as
  /// soon as the user scrolls, which is what a form wants.
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  /// Adds the keyboard's height to the bottom padding, so the content can
  /// scroll clear of it.
  ///
  /// Leave this off inside a normal [Scaffold]: `resizeToAvoidBottomInset`
  /// already shrinks the body, and doing both leaves a gap the height of the
  /// keyboard. Turn it on in a bottom sheet, a dialog, or a Scaffold with
  /// `resizeToAvoidBottomInset: false`.
  final bool avoidKeyboard;

  /// Stretches [child] to at least the height of the viewport, so a short page
  /// can still push a footer down with a [Spacer] or an [Expanded] while a
  /// tall one scrolls as usual.
  ///
  /// Costs an [IntrinsicHeight] pass over the child, so leave it off for a
  /// page that is taller than the screen anyway.
  final bool fillViewport;

  /// Lets the view scroll — and so bounce, and so drive a [RefreshIndicator] —
  /// even when the content is shorter than the viewport. Ignored when
  /// [physics] is set.
  final bool alwaysScrollable;

  final ScrollPhysics? physics;
  final ScrollController? controller;
  final bool reverse;

  Widget _scrollView(Widget content, EdgeInsets resolvedPadding) {
    return SingleChildScrollView(
      padding: resolvedPadding,
      controller: controller,
      reverse: reverse,
      keyboardDismissBehavior: keyboardDismissBehavior,
      physics:
          physics ??
          (alwaysScrollable ? const AlwaysScrollableScrollPhysics() : null),
      child: content,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolvedPadding = avoidKeyboard
        ? padding.copyWith(
            bottom: padding.bottom + MediaQuery.viewInsetsOf(context).bottom,
          )
        : padding;

    Widget scrollView = _scrollView(child, resolvedPadding);

    if (fillViewport) {
      scrollView = LayoutBuilder(
        builder: (context, constraints) {
          // Nested inside another scrollable there is no viewport height to
          // fill, so the child just takes the height it asks for.
          final available = constraints.hasBoundedHeight
              ? (constraints.maxHeight - resolvedPadding.vertical).clamp(
                  0.0,
                  double.infinity,
                )
              : 0.0;

          return _scrollView(
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: available),
              // A minimum alone leaves the child's height unbounded, and an
              // Expanded inside it would throw; this gives it a height to
              // divide up.
              child: IntrinsicHeight(child: child),
            ),
            resolvedPadding,
          );
        },
      );
    }

    if (!safeArea) return scrollView;

    return SafeArea(
      top: safeAreaTop,
      bottom: safeAreaBottom,
      left: safeAreaHorizontal,
      right: safeAreaHorizontal,
      // Without this the bottom inset collapses the moment the keyboard opens,
      // and the content jumps by the height of the home indicator.
      maintainBottomViewPadding: true,
      child: scrollView,
    );
  }
}
