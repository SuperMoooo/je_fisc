import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_constants.dart';
import '../../../config/theme/app_status_colors.dart';

/// Feedback status for [AppToast].
enum AppToastType { success, error, warning, info }

/// One consistent feedback surface for the whole app.
///
/// ```dart
/// AppToast.success(context, 'Saved');
/// AppToast.show(
///   context,
///   'Check your connection and try again.',
///   title: 'Could not save',
///   type: AppToastType.error,
///   actionLabel: 'Retry',
///   onAction: _save,
/// );
/// ```
///
/// From a Riverpod notifier you already have a context inside `ref.listen` —
/// or use `ref.listenAction`, which calls this for you.
///
/// **It draws its own card on the root [Overlay], not on a [SnackBar].** A
/// SnackBar buys positioning and timing but fixes the motion: 250ms, no scale,
/// and an exit that holds full opacity for 72% of the slide before cutting out.
/// On an outlined card with a shadow that reads as a snap rather than as a
/// dismissal, and none of it is tunable. Owning the [AnimationController] buys
/// a curve on both ends — and it lets a second toast crossfade into the card
/// already on screen instead of making the user watch a full exit first.
class AppToast {
  const AppToast._();

  /// How much of the status color tints the card's surface. Enough to be felt,
  /// not enough to fight the text on it.
  static const double _surfaceTint = 0.07;

  /// The outline, which is what gives the card an edge in both themes — a
  /// shadow alone disappears against a dark background.
  static const double _borderOpacity = 0.30;

  /// The icon chip's fill. Matches [AppLeadingIcon]'s tonal fill, so the two
  /// read as siblings.
  static const double _chipFill = 0.12;

  /// Widest the card gets. Past this a toast on a tablet becomes a banner
  /// stretched across the screen, and the eye has to travel to read six words.
  static const double _maxWidth = 480;

  /// Arriving is slower than leaving. Coming in, the card has to be noticed and
  /// read, and easing it over a third of a second is what makes it look placed
  /// rather than popped; going out it has already done its job.
  static const Duration _enterDuration = Duration(milliseconds: 320);
  static const Duration _exitDuration = Duration(milliseconds: 200);

  /// How far the card rises, as a fraction of its own height. Short on purpose:
  /// a full-height slide reads as a drawer opening, this reads as it settling.
  static const double _rise = 0.35;

  /// Paired with the rise. Growing the last few percent into place is what
  /// makes it look like it came toward the user rather than up past them.
  static const double _enterScale = 0.94;

  /// The live toast, if any. One at a time by design: a stack of toasts is a
  /// log, and a log belongs on a screen rather than over one.
  static OverlayEntry? _entry;
  static ValueNotifier<_ToastSpec>? _live;

  /// Registered by the live overlay so [dismiss] can reach it without a key.
  static VoidCallback? _hideCurrent;

  static void show(
    BuildContext context,
    String message, {
    AppToastType type = AppToastType.info,
    String? title,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
    bool showClose = false,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _feedback(type);

    final spec = _ToastSpec(
      message: message,
      title: title,
      type: type,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
      showClose: showClose,
    );

    // A toast already on screen takes the new content where it stands. Playing
    // its exit first would make the user watch 200ms of a message they have
    // been replaced out of before the one they asked for starts arriving.
    final live = _live;
    if (_entry != null && live != null) {
      live.value = spec;
      return;
    }

    final notifier = ValueNotifier<_ToastSpec>(spec);
    final entry = OverlayEntry(
      builder: (_) => _ToastOverlay(spec: notifier, onGone: _release),
    );
    _live = notifier;
    _entry = entry;
    overlay.insert(entry);
  }

  static void success(BuildContext context, String message, {String? title}) =>
      show(context, message, title: title, type: AppToastType.success);

  static void error(BuildContext context, String message, {String? title}) =>
      show(context, message, title: title, type: AppToastType.error);

  static void warning(BuildContext context, String message, {String? title}) =>
      show(context, message, title: title, type: AppToastType.warning);

  static void info(BuildContext context, String message, {String? title}) =>
      show(context, message, title: title, type: AppToastType.info);

  /// Takes the current toast off screen early — for a screen that is about to
  /// be popped, or an action whose result has already been shown another way.
  /// It animates out; nothing happens if there is no toast up.
  static void dismiss() => _hideCurrent?.call();

  /// Called by the overlay once the card is off screen. Pulling the entry any
  /// earlier would cut the exit animation off at the knees.
  static void _release() {
    // Cleared before the removal so that a second call — a swipe and a timer
    // landing on the same frame — cannot remove the same entry twice.
    final entry = _entry;
    _entry = null;
    // The notifier belongs to the overlay from insertion on, and is disposed
    // there — the widget still has to unsubscribe from it after this runs.
    _live = null;
    entry?.remove();
  }

  /// Called when the overlay goes away without the exit ever running: the route
  /// under it popped, the navigator replaced, a hot restart. The entry died
  /// with its Overlay, so there is nothing to remove — but left pointing at a
  /// disposed notifier, [show] would treat every later toast as a replacement
  /// for a card that no longer exists and quietly do nothing.
  ///
  /// Identity-checked because the exit path nulls these fields a frame before
  /// the widget is disposed, and a toast shown in that gap owns them by then.
  static void _forget(ValueNotifier<_ToastSpec> spec) {
    if (!identical(_live, spec)) return;
    _entry = null;
    _live = null;
  }

  /// A toast usually lands while the user is looking somewhere else, so it
  /// says what happened by feel as well as by color — the worse the news, the
  /// heavier the tap.
  static void _feedback(AppToastType type) => switch (type) {
    AppToastType.success => HapticFeedback.lightImpact(),
    AppToastType.warning => HapticFeedback.mediumImpact(),
    AppToastType.error => HapticFeedback.heavyImpact(),
    AppToastType.info => HapticFeedback.selectionClick(),
  };

  static (Color, IconData) _resolve(
    AppToastType type,
    AppStatusColors status,
    Color error,
  ) => switch (type) {
    AppToastType.success => (status.success, Icons.check_circle_outline),
    AppToastType.error => (error, Icons.error_outline),
    AppToastType.warning => (status.warning, Icons.warning_amber_rounded),
    AppToastType.info => (status.info, Icons.info_outline),
  };
}

/// Everything one call to [AppToast.show] asked for, in one object so that a
/// replacement is a single assignment the live overlay can animate across.
class _ToastSpec {
  const _ToastSpec({
    required this.message,
    required this.title,
    required this.type,
    required this.duration,
    required this.actionLabel,
    required this.onAction,
    required this.showClose,
  });

  final String message;
  final String? title;
  final AppToastType type;
  final Duration duration;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool showClose;
}

/// What actually sits in the overlay: the card, its entrance and exit, its
/// timer, and the swipe that cuts both short.
class _ToastOverlay extends StatefulWidget {
  const _ToastOverlay({required this.spec, required this.onGone});

  /// Listened to rather than passed by value, so [AppToast.show] can swap the
  /// content of a card that is already up without rebuilding the entry.
  final ValueNotifier<_ToastSpec> spec;

  /// Called once the card is off screen and the entry can be pulled.
  final VoidCallback onGone;

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _curve;
  Timer? _timer;
  bool _entered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this)
      ..addStatusListener(_handleStatus);
    // Out on the mirror of the way in: decelerating into place, accelerating
    // away. Reversing easeOutCubic instead would have it crawl off the screen.
    _curve = CurvedAnimation(
      parent: _controller,
      curve: AppConstants.curveEnter,
      reverseCurve: AppConstants.curveExit,
    );
    widget.spec.addListener(_handleSpecChanged);
    AppToast._hideCurrent = _hide;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Durations are settled here and not in initState because "reduce motion"
    // is a MediaQuery — and a controller ignores a duration changed mid-flight,
    // so they have to be right before the first forward() rather than after it.
    final reduced = MediaQuery.disableAnimationsOf(context);
    _controller
      ..duration = reduced ? Duration.zero : AppToast._enterDuration
      ..reverseDuration = reduced ? Duration.zero : AppToast._exitDuration;
    if (!_entered) {
      _entered = true;
      _controller.forward();
      _restartTimer();
    }
  }

  @override
  void dispose() {
    if (AppToast._hideCurrent == _hide) AppToast._hideCurrent = null;
    AppToast._forget(widget.spec);
    _timer?.cancel();
    widget.spec.removeListener(_handleSpecChanged);
    widget.spec.dispose();
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleSpecChanged() {
    _restartTimer();
    // If it was on its way out, bring it back: the entry is about to be pulled
    // out from under content that has only just been handed to it.
    _controller.forward();
    setState(() {});
  }

  /// The controller only reaches `dismissed` again by completing a reverse, so
  /// this is the exit finishing and nothing else.
  void _handleStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) widget.onGone();
  }

  void _restartTimer() {
    _timer?.cancel();
    _timer = Timer(widget.spec.value.duration, _hide);
  }

  void _hide() {
    _timer?.cancel();
    if (mounted) _controller.reverse();
  }

  /// A flick already carried the card off screen, so there is no exit left to
  /// play — the entry goes straight away.
  void _handleSwipe() {
    _timer?.cancel();
    widget.onGone();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // Above the keyboard while there is one, above the gesture bar when there
    // is not. A toast the keyboard covers is a toast nobody reads.
    final bottomInset = media.viewInsets.bottom > 0
        ? media.viewInsets.bottom
        : media.viewPadding.bottom;
    final spec = widget.spec.value;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppConstants.space12,
          0,
          AppConstants.space12,
          bottomInset + AppConstants.space12,
        ),
        // Bottom-center on a wide window rather than pinned to one corner. The
        // strip around the card paints nothing and so absorbs nothing: taps
        // beside the toast reach the screen underneath it.
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppToast._maxWidth),
            child: FadeTransition(
              opacity: _curve,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, AppToast._rise),
                  end: Offset.zero,
                ).animate(_curve),
                child: ScaleTransition(
                  scale: Tween<double>(
                    begin: AppToast._enterScale,
                    end: 1,
                  ).animate(_curve),
                  // Grows out of the edge it rose from, not out of its middle.
                  alignment: Alignment.bottomCenter,
                  child: Dismissible(
                    // New content is a new card as far as the drag is
                    // concerned; rekeying clears an offset left by a swipe the
                    // user started and abandoned.
                    key: ObjectKey(spec),
                    // Flick it away sideways, which is what a card at the edge
                    // of the screen invites; down would be into the bezel.
                    direction: DismissDirection.horizontal,
                    // Nothing sits below it to resize into.
                    resizeDuration: null,
                    onDismissed: (_) => _handleSwipe(),
                    child: Semantics(
                      container: true,
                      liveRegion: true,
                      child: Material(
                        // The overlay is outside the app's Material, and the
                        // action button wants one to ink into.
                        type: MaterialType.transparency,
                        // The card resolves its own colors from the context it
                        // is built in. Passing them down from show() looks
                        // equivalent and is not: it builds a frame later, and a
                        // theme that changed in between would leave a
                        // light-palette green on a dark card.
                        child: _ToastCard(
                          message: spec.message,
                          title: spec.title,
                          type: spec.type,
                          actionLabel: spec.actionLabel,
                          onAction: spec.onAction,
                          showClose: spec.showClose,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The card [AppToast] puts in the overlay. Private on purpose: a toast is
/// shown through [AppToast.show], never built by hand.
class _ToastCard extends StatelessWidget {
  const _ToastCard({
    required this.message,
    required this.title,
    required this.type,
    required this.actionLabel,
    required this.onAction,
    required this.showClose,
  });

  final String message;
  final String? title;
  final AppToastType type;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool showClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final (accent, icon) = AppToast._resolve(
      type,
      context.statusColors,
      colorScheme.error,
    );
    final heading = title;
    final hasAction = actionLabel != null && onAction != null;

    return Container(
      padding: const EdgeInsets.all(AppConstants.space12),
      decoration: BoxDecoration(
        // Tinted rather than colored: the status is carried by the icon and the
        // outline, so the text keeps the contrast the theme guarantees it.
        color: Color.alphaBlend(
          accent.withValues(alpha: AppToast._surfaceTint),
          isDark
              ? colorScheme.surfaceContainerHighest
              : colorScheme.surfaceContainerLowest,
        ),
        borderRadius: AppConstants.borderRadius16,
        border: Border.all(
          color: accent.withValues(alpha: AppToast._borderOpacity),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: isDark ? 0.45 : 0.12),
            blurRadius: AppConstants.space24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        // Top, not center: with a title and two lines of body the icon belongs
        // beside the first line, not floating halfway down the card.
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppConstants.space8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: AppToast._chipFill),
              borderRadius: AppConstants.borderRadius8,
            ),
            child: Icon(icon, color: accent, size: AppConstants.iconSmall),
          ),
          const SizedBox(width: AppConstants.space12),
          Expanded(
            child: Padding(
              // Centers a single line against the icon chip without moving a
              // two-line one off the top.
              padding: const EdgeInsets.symmetric(
                vertical: AppConstants.space4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (heading != null)
                    Text(
                      heading,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  Text(
                    message,
                    // A toast is glanceable by definition; anything longer than
                    // this belongs in an AppBanner, which persists.
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: heading == null
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (hasAction) ...[
            const SizedBox(width: AppConstants.space8),
            TextButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                AppToast.dismiss();
                onAction!();
              },
              style: TextButton.styleFrom(
                foregroundColor: accent,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.space12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: AppConstants.borderRadius8,
                ),
              ),
              child: Text(
                actionLabel!,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          if (showClose)
            IconButton(
              onPressed: AppToast.dismiss,
              icon: const Icon(Icons.close, size: AppConstants.iconSmall),
              color: colorScheme.onSurfaceVariant,
              visualDensity: VisualDensity.compact,
              tooltip: 'Fechar',
            ),
        ],
      ),
    );
  }
}
