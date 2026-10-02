import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../indicators/app_badge.dart';
import '../inputs/app_input_style.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/extensions.dart';

/// A single destination for [AppBottomNav] — and for the rail and the drawer,
/// which read the same list so an app describes its navigation once.
///
/// A destination can carry a badge. The count is state, so a list that uses one
/// is built where that state is read instead of held `const`:
///
/// ```dart
/// final destinations = [
///   for (var i = 0; i < _tabs.length; i++)
///     AppNavDestination(
///       icon: _tabs[i].icon,
///       selectedIcon: _tabs[i].selectedIcon,
///       label: _tabs[i].label,
///       badgeCount: i == 0 ? unseenMessagesNumber : null,
///     ),
/// ];
/// ```
class AppNavDestination {
  const AppNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badgeCount,
    this.showBadgeDot = false,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;

  /// The number on this destination's icon — unseen messages, items in a cart.
  /// Null or 0 shows none, and past 99 it reads "99+".
  final int? badgeCount;

  /// A plain presence dot instead of a number, for "something is new" with
  /// nothing to count. Only read when [badgeCount] is null — a count wins.
  final bool showBadgeDot;

  /// Whether [badged] draws anything, by the same rule [AppBadge] follows.
  bool get hasBadge => badgeCount == null ? showBadgeDot : badgeCount! > 0;

  /// [icon] wearing this destination's badge, or bare when it has none. The
  /// bar, the rail and the drawer all draw their icons through this so the
  /// badge looks the same on each.
  Widget badged(Widget icon) =>
      AppBadge(count: badgeCount, showDot: showBadgeDot, child: icon);
}

/// How [AppBottomNav] marks the selected destination.
///
/// - [material]: Material 3's own bar — a label under every icon and a pill
///   indicator that slides behind the selected one.
/// - [classic]: the pre-M3 bar — icon over label, the selected pair tinted
///   with the accent and nothing drawn behind it.
/// - [pill]: icons only until selected; the selected one opens into an accent
///   pill with its label beside the icon.
/// - [dot]: icons only, with a dot under the selected one. The quietest of the
///   four, for a bar whose icons speak for themselves.
enum AppBottomNavStyle { material, classic, pill, dot }

/// Where [AppBottomNav] writes its labels, on top of what the
/// [AppBottomNavStyle] says by itself.
///
/// - [auto]: whatever the style does on its own — [AppBottomNavStyle.material]
///   and [AppBottomNavStyle.classic] write the label under every icon,
///   [AppBottomNavStyle.pill] beside the selected one, [AppBottomNavStyle.dot]
///   nowhere.
/// - [below]: every destination carries its label under its icon, whichever
///   style is drawing. The pill then fills behind the icon *and* the label
///   instead of opening sideways; the dot keeps its mark under both.
/// - [none]: icons only. The label still reaches a screen reader, and a long
///   press still names the icon.
enum AppBottomNavLabels { auto, below, none }

/// A corner [AppBottomNav] cuts something with — the floating card it rides in
/// ([AppBottomNav.floatingShape]) and the fill behind the selected destination
/// ([AppBottomNav.pillShape]) are each asked this separately.
///
/// - [full]: a stadium, as round at the ends as the thing is tall.
/// - [rounded]: the corner an elevated card wears.
/// - [square]: sharp corners.
///
/// [AppBottomNav.floatingBorderRadius] and [AppBottomNav.pillBorderRadius]
/// override the three where a project wants a number of its own.
enum AppBottomNavShape { full, rounded, square }

/// How wide the card a floating [AppBottomNav] rides in is. A docked bar spans
/// the bottom edge by definition, so this is only read when
/// [AppBottomNav.floating].
///
/// - [fill]: the width of the screen less the margin around it — the band a
///   bottom bar has always been.
/// - [hug]: only as wide as its destinations need, centered. Two or three
///   destinations spread across a whole phone is mostly empty card; this is the
///   answer to that.
///
/// [AppBottomNav.floatingMaxWidth] caps either of them, which is how a [fill]
/// bar stops short of the edges on a tablet.
enum AppBottomNavWidth { fill, hug }

/// The app's bottom navigation. Feed it the current [index], the
/// [destinations], and an [onDestinationSelected] callback. For go_router,
/// drive [index] from a `StatefulShellRoute` and switch branch in the callback:
///
/// ```dart
/// AppBottomNav(
///   index: shell.currentIndex,
///   destinations: destinations,
///   onDestinationSelected: shell.goBranch,
///   style: AppBottomNavStyle.pill,
///   labels: AppBottomNavLabels.below,
///   floating: true,
///   floatingShape: AppBottomNavShape.rounded,
///   floatingWidth: AppBottomNavWidth.hug,
/// )
/// ```
///
/// Each knob answers one question and combines freely with the rest: [style] is
/// how the selected destination is marked, [labels] is where the names are
/// written, [floating] is whether the bar is a band across the bottom edge or a
/// card riding above it, [floatingShape] is the corner that card is cut with,
/// [floatingWidth] is how wide it is, [borderColor] is the line drawn around
/// it, and [pillShape] the corner of the fill behind the selection. A floating
/// [pill] is the look most modern apps wear, but every style floats and every
/// style can carry labels.
///
/// A floating bar wants `Scaffold(extendBody: true)` under it, so the content
/// runs through the gap instead of stopping at it. [AppAdaptiveNav] sets that
/// for you.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.index,
    required this.destinations,
    required this.onDestinationSelected,
    this.style = AppBottomNavStyle.material,
    this.labels = AppBottomNavLabels.auto,
    this.floating = false,
    this.floatingShape = AppBottomNavShape.full,
    this.floatingBorderRadius,
    this.floatingWidth = AppBottomNavWidth.fill,
    this.floatingMaxWidth,
    this.borderColor,
    this.pillShape,
    this.pillBorderRadius,
    this.variant,
  });

  final int index;
  final List<AppNavDestination> destinations;
  final ValueChanged<int> onDestinationSelected;

  final AppBottomNavStyle style;

  /// Where the destination names are written. Defaults to whatever [style]
  /// does on its own.
  final AppBottomNavLabels labels;

  /// Detaches the bar from the bottom edge: a card with a margin around it and
  /// a shadow under it. Works with every [style].
  final bool floating;

  /// The corner that card is cut with. Only read when [floating].
  final AppBottomNavShape floatingShape;

  /// A corner of the project's own, overriding [floatingShape]. Only read when
  /// [floating].
  final BorderRadius? floatingBorderRadius;

  /// Whether that card spans the width or shrinks to its destinations. Only
  /// read when [floating] — a docked bar is the width of the screen.
  final AppBottomNavWidth floatingWidth;

  /// A ceiling on that card's width, in logical pixels, whichever
  /// [floatingWidth] it wears. A capped card is centered. Null is uncapped —
  /// which for [AppBottomNavWidth.fill] means the screen less its margin. Only
  /// read when [floating].
  final double? floatingMaxWidth;

  /// The bar's hairline border: around the whole card when [floating], along
  /// the top edge when docked.
  ///
  /// Null leaves each layout as it was — a docked bar keeps the
  /// [ColorScheme.outlineVariant] line it draws between itself and the content,
  /// Material's own bar keeps the none it draws, and a floating card is held up
  /// by its shadow alone. Naming a color is how a flat theme gets an edge in a
  /// dark scheme, where that shadow is invisible.
  final Color? borderColor;

  /// The corner of the fill behind the selected destination: the pill an
  /// [AppBottomNavStyle.pill] draws, and the indicator Material's own bar
  /// slides behind its selection.
  ///
  /// Null leaves each of them the corner it wears by itself — a stadium for a
  /// pill that opens sideways, a card's corner for one stacked over its label,
  /// and the theme's for Material's indicator.
  final AppBottomNavShape? pillShape;

  /// A corner of the project's own for that fill, overriding [pillShape].
  final BorderRadius? pillBorderRadius;

  /// Null follows [AppInputConfig.defaults].
  final AppInputVariant? variant;

  /// The height of the three styles this widget draws itself, before any
  /// safe-area inset: a row of touch targets with a little air around it.
  /// Material's own bar measures itself and is left alone.
  static const double _height = 64;

  /// The width of the indicator Material's [NavigationBar] slides behind its
  /// selected icon — the least a destination of that bar can be.
  static const double _indicatorWidth = 64;

  static BorderRadius _radiusOf(AppBottomNavShape shape) => switch (shape) {
    AppBottomNavShape.full => AppConstants.borderRadiusFull,
    AppBottomNavShape.rounded => AppConstants.borderRadius16,
    AppBottomNavShape.square => BorderRadius.zero,
  };

  /// The corner the floating card is cut with: the project's own where it named
  /// one, the shape's otherwise.
  BorderRadius get _radius => floatingBorderRadius ?? _radiusOf(floatingShape);

  /// The corner asked for behind the selected destination, or null where none
  /// was and every style keeps the one it draws by itself.
  BorderRadius? get _pillRadius {
    final shape = pillShape;
    return pillBorderRadius ?? (shape == null ? null : _radiusOf(shape));
  }

  /// Whether the selected destination opens sideways into a labelled pill. That
  /// is the pill style's own layout, and it is the one thing asking for labels
  /// [AppBottomNavLabels.below] — or for none — takes away.
  bool get _opens =>
      style == AppBottomNavStyle.pill && labels == AppBottomNavLabels.auto;

  /// Whether the bar is sized by its destinations rather than by the screen.
  /// Only a floating bar can be: a docked one is the bottom edge.
  bool get _hug => floating && floatingWidth == AppBottomNavWidth.hug;

  void _select(int i) {
    HapticFeedback.selectionClick();
    onDestinationSelected(i);
  }

  @override
  Widget build(BuildContext context) {
    assert(
      destinations.length >= 2,
      'AppBottomNav: needs at least two destinations — a bar with one of them '
      'is not navigation.',
    );
    assert(
      index >= 0 && index < destinations.length,
      'AppBottomNav: index $index is outside the ${destinations.length} '
      'destinations it was given.',
    );

    final bar = style == AppBottomNavStyle.material
        ? _material(context)
        : _drawn(context);

    return floating ? _floated(context, bar) : bar;
  }

  /// Material's own [NavigationBar] — still the right answer when you want the
  /// platform look, and the only style whose indicator animates between
  /// destinations for free.
  Widget _material(BuildContext context) {
    final accent = AppInputStyle.accentOf(context, variant);
    final pillRadius = _pillRadius;

    final bar = NavigationBar(
      selectedIndex: index,
      // Floating, the card behind it owns the surface and the shadow — a bar
      // painting its own would draw a second edge inside the rounded one.
      backgroundColor: floating ? Colors.transparent : null,
      elevation: floating ? 0 : null,
      // Null without a variant, so the bar's fill and its indicator both come
      // from `navigationBarTheme`. The pill style below still needs a colour
      // it can count on — it paints a surface the theme cannot describe.
      indicatorColor: AppInputStyle.accentOrNull(
        context,
        variant,
      )?.withValues(alpha: AppInputStyle.config.fillOpacity * 2),
      // Material's indicator is the same fill the pill style draws by hand, so
      // a project that named a corner for one means it for both. Null leaves
      // NavigationBarTheme's own.
      indicatorShape: pillRadius == null
          ? null
          : RoundedRectangleBorder(borderRadius: pillRadius),
      // Material's bar writes a label under every icon on its own, so `auto`
      // and `below` are the same answer here — and null is the one that lets a
      // NavigationBarTheme still have its say.
      labelBehavior: switch (labels) {
        AppBottomNavLabels.auto => null,
        AppBottomNavLabels.below =>
          NavigationDestinationLabelBehavior.alwaysShow,
        AppBottomNavLabels.none =>
          NavigationDestinationLabelBehavior.alwaysHide,
      },
      onDestinationSelected: _select,
      destinations: [
        for (final destination in destinations)
          NavigationDestination(
            icon: destination.badged(Icon(destination.icon)),
            selectedIcon: destination.badged(
              Icon(destination.selectedIcon, color: accent),
            ),
            label: destination.label,
          ),
      ],
    );

    // NavigationBar divides whatever width it is handed between its
    // destinations, so it is the one style that cannot shrink to them by
    // itself — and it cannot be asked either: it lays each destination out
    // with a custom delegate, which answers an IntrinsicWidth with zero. So
    // the width is worked out here, and the card's loose constraints still cap
    // it at the room there is.
    final sized = _hug
        ? SizedBox(width: _materialWidth(context), child: bar)
        : bar;

    final border = borderColor;
    if (floating || border == null) return sized;

    // The bar paints its own surface, so the line has to land on top of it —
    // a decoration behind it would be covered by the color it draws.
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: border)),
      ),
      child: sized,
    );
  }

  /// How wide Material's bar is when it hugs. It hands every destination the
  /// same share, so the widest one — its label, or the indicator where that is
  /// wider or no label is written — sets the share for all of them.
  double _materialWidth(BuildContext context) {
    var widest = _indicatorWidth;

    if (labels != AppBottomNavLabels.none) {
      // The selected label is the one a theme makes heavier, so it is the one
      // that has to fit.
      final labelStyle =
          NavigationBarTheme.of(
            context,
          ).labelTextStyle?.resolve(const {WidgetState.selected}) ??
          context.textTheme.labelMedium;
      final textDirection = Directionality.of(context);
      final textScaler = MediaQuery.textScalerOf(context);

      for (final destination in destinations) {
        final painter = TextPainter(
          text: TextSpan(text: destination.label, style: labelStyle),
          textDirection: textDirection,
          textScaler: textScaler,
          maxLines: 1,
        )..layout();
        if (painter.width > widest) widest = painter.width;
        painter.dispose();
      }
    }

    return destinations.length * (widest + AppConstants.space32);
  }

  /// The three styles Material does not ship: one row of items over the bar's
  /// own surface.
  Widget _drawn(BuildContext context) {
    final row = SizedBox(
      height: _height,
      child: Row(
        // Hugging, the row is as wide as its items and the card around it
        // shrinks to match; filling, it takes the width and spreads them.
        mainAxisSize: _hug ? MainAxisSize.min : MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        // Nothing separates the items once the row stops spreading them, so a
        // hugging bar spaces them by hand.
        spacing: _hug ? AppConstants.space4 : 0.0,
        children: [
          for (var i = 0; i < destinations.length; i++)
            // Only a pill that opens sideways grows with its label, so only
            // that one is sized by its content — every other layout divides the
            // width evenly. A stacked pill still hugs its own content inside
            // its even share, which is what keeps it a pill. Hugging, there is
            // no width to divide: every item is its own size.
            if (!_hug && !_opens)
              Expanded(child: _item(i))
            // The open pill is the one item that can want more room than it is
            // given: Flexible lets its label ellipsize on a narrow screen
            // instead of overflowing the row.
            else if (_opens && i == index)
              Flexible(child: _item(i))
            else
              _item(i),
        ],
      ),
    );

    // Floating, the shell around it is the Material, and it has already spent
    // the safe area on the margin under the card.
    if (floating) return row;

    return Material(
      color: context.colorScheme.surface,
      child: DecoratedBox(
        // What separates the bar from the content above it, since this one
        // carries no elevation. Drawn outside the SafeArea so it spans the
        // full width on a notched phone held sideways.
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: borderColor ?? context.colorScheme.outlineVariant,
            ),
          ),
        ),
        child: SafeArea(top: false, child: row),
      ),
    );
  }

  Widget _item(int i) => _AppNavItem(
    destination: destinations[i],
    selected: i == index,
    style: style,
    labels: labels,
    // A pill that opens sideways is a stadium, which is what it has always
    // been. Stacked over a label it is taller than it is wide, and a
    // stadium there is a lozenge — so that one defaults to a card's corner,
    // the same one Material's stacked indicator wears.
    pillRadius:
        _pillRadius ??
        (_opens ? AppConstants.borderRadiusFull : AppConstants.borderRadius16),
    hug: _hug,
    variant: variant,
    onTap: () => _select(i),
  );

  /// The card a floating bar rides in: the margin off the edges, the corner it
  /// is cut with, the width it takes of what is left, and the shadow that lifts
  /// it off the content passing underneath.
  Widget _floated(BuildContext context, Widget bar) {
    // What the system took at the bottom edge: the gesture pill, or Android's
    // three buttons — which are tall enough that a card sitting at exactly the
    // inset reads as a second bar stacked on the first.
    final inset = MediaQuery.paddingOf(context).bottom;
    // So the margin is spent on top of the inset rather than instead of it —
    // a short one where the system already holds the card off the edge, the
    // full one where it does not.
    final bottomMargin =
        inset + (inset > 0 ? AppConstants.space8 : AppConstants.space16);
    final radius = _radius;
    final border = borderColor;

    // A rounded end curves in over the outermost destination, and this is the
    // room that keeps it clear of the curve — so it tracks the corner rather
    // than being spent on a square card that has no curve to clear.
    final clearance = switch (radius.topLeft.x) {
      >= AppConstants.radius24 => AppConstants.space8,
      > 0 => AppConstants.space4,
      _ => 0.0,
    };

    Widget card = DecoratedBox(
      // The same shadow an elevated AppCard casts, so the two read as
      // siblings rather than as two ideas of what "raised" looks like.
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        // A step off `surface`, which is what keeps the card visible in a
        // dark theme, where the shadow under it is not.
        color: context.colorScheme.surfaceContainer,
        clipBehavior: Clip.antiAlias,
        // The corner and the line around it are one shape to Material, and
        // asking it for both a borderRadius and a shape is what it asserts
        // against. `BorderSide.none` is the card that was never given a color.
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: border == null ? BorderSide.none : BorderSide(color: border),
        ),
        // The bar inside must not inset itself as well — NavigationBar wraps
        // itself in a SafeArea, which here would pad the inside of the card.
        child: MediaQuery.removePadding(
          context: context,
          removeBottom: true,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: clearance),
            child: bar,
          ),
        ),
      ),
    );

    final maxWidth = floatingMaxWidth;
    if (maxWidth != null) {
      card = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: card,
      );
    }

    // A card narrower than the room it was given would otherwise sit against
    // the left margin. Filling and uncapped there is nothing to center — the
    // card is already the width of the row.
    //
    // `heightFactor` is what keeps this to the bar's own height: the slot a
    // bottom bar is laid out in is loose, and an Align without it would answer
    // with the whole screen.
    final placed = _hug || maxWidth != null
        ? Align(heightFactor: 1, child: card)
        : card;

    return Padding(
      padding: EdgeInsets.only(
        left: AppConstants.space16,
        right: AppConstants.space16,
        top: AppConstants.space8,
        bottom: bottomMargin,
      ),
      child: placed,
    );
  }
}

/// One destination in the styles [AppBottomNav] draws itself.
class _AppNavItem extends StatelessWidget {
  const _AppNavItem({
    required this.destination,
    required this.selected,
    required this.style,
    required this.labels,
    required this.pillRadius,
    required this.hug,
    required this.variant,
    required this.onTap,
  });

  final AppNavDestination destination;
  final bool selected;
  final AppBottomNavStyle style;
  final AppBottomNavLabels labels;

  /// The corner of the fill behind a selected [AppBottomNavStyle.pill].
  final BorderRadius pillRadius;

  /// Whether the bar is sized by its items, so this one is as wide as its
  /// content rather than its share of the screen.
  final bool hug;

  final AppInputVariant? variant;
  final VoidCallback onTap;

  /// The mark under a selected [AppBottomNavStyle.dot] icon. Small enough to
  /// read as a mark rather than as a second icon.
  static const double _dotSize = 6;

  /// How far Material's [Badge] reaches past the top and end of the icon it is
  /// drawn on.
  static const double _badgeOverhang = 4;

  /// Whether this destination's name is written on screen — which decides both
  /// whether the layouts below make room for it and whether a tooltip naming
  /// the icon would be repeating what is already there.
  bool get _labelled => switch (labels) {
    AppBottomNavLabels.none => false,
    AppBottomNavLabels.below => true,
    AppBottomNavLabels.auto => switch (style) {
      AppBottomNavStyle.material || AppBottomNavStyle.classic => true,
      // The pill writes its label only once it has opened to hold it.
      AppBottomNavStyle.pill => selected,
      AppBottomNavStyle.dot => false,
    },
  };

  /// Whether this item is a pill that opens sideways on selection, as opposed
  /// to one stacked over its label or holding an icon alone.
  bool get _opens =>
      style == AppBottomNavStyle.pill && labels == AppBottomNavLabels.auto;

  @override
  Widget build(BuildContext context) {
    final accent = AppInputStyle.accentOf(context, variant);
    final idle = context.colorScheme.onSurfaceVariant;
    final pill = style == AppBottomNavStyle.pill;

    // The pill is the one style that fills a surface behind its icon, so it is
    // the one style whose selected icon is drawn *on* the accent.
    final selectedColor = pill
        ? AppInputStyle.onAccentOf(context, variant)
        : accent;

    // Reduce-motion reaches the same layouts, just instantly.
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppConstants.duration200;

    final icon = destination.badged(
      Icon(
        selected ? destination.selectedIcon : destination.icon,
        size: AppConstants.iconMedium,
        color: selected ? selectedColor : idle,
      ),
    );

    // A badge hangs `_badgeOverhang` past its icon's top and end edges, and the
    // opening pill's AnimatedSize clips to its own box. A badged destination
    // moves that much of the pill's padding inside the box, so the badge is
    // drawn and the pill still lands exactly where it would have.
    final overhang = destination.hasBadge ? _badgeOverhang : 0.0;
    final pillHorizontal = _opens && selected
        ? AppConstants.space16
        : AppConstants.space12;
    final pillVertical = _labelled && !_opens
        ? AppConstants.space4
        : AppConstants.space8;

    final label = Text(
      destination.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: context.textTheme.labelMedium?.copyWith(
        color: selected ? selectedColor : idle,
        fontWeight: selected ? FontWeight.bold : null,
      ),
    );

    // Icon over name, or the icon alone where the name is not written. What
    // every layout here but the opening pill is built from.
    // The label is not Flexible here the way it is inside an open pill: down
    // the column, flex would hand it the leftover height instead of letting it
    // ellipsize, and the width it has to fit is the item's own either way.
    final stacked = <Widget>[
      icon,
      if (_labelled) ...[const SizedBox(height: AppConstants.space4), label],
    ];

    final Widget content = switch (style) {
      // The material style is a NavigationBar, not a row of these, so it never
      // arrives here — answering with the nearest layout beats an empty box if
      // that ever stops being true.
      AppBottomNavStyle.classic || AppBottomNavStyle.material => Column(
        mainAxisSize: MainAxisSize.min,
        children: stacked,
      ),
      AppBottomNavStyle.dot => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...stacked,
          // Closer under a label than under a bare icon, so the dot reads as
          // this destination's mark either way.
          SizedBox(
            height: _labelled ? AppConstants.space4 : AppConstants.space8,
          ),
          // The dot's room is held whether or not it is drawn, so the icons
          // do not hop as the selection moves.
          SizedBox(
            width: _dotSize,
            height: _dotSize,
            child: AnimatedOpacity(
              duration: duration,
              opacity: selected ? 1 : 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
      AppBottomNavStyle.pill => AnimatedContainer(
        duration: duration,
        curve: Curves.easeOut,
        // Stacked, the label is inside the fill, and the air an open pill
        // wears above and below it would push the whole thing past the
        // height of the bar.
        padding: _opens
            ? EdgeInsetsDirectional.fromSTEB(
                pillHorizontal,
                pillVertical - overhang,
                pillHorizontal - overhang,
                pillVertical,
              )
            : EdgeInsets.symmetric(
                horizontal: pillHorizontal,
                vertical: pillVertical,
              ),
        decoration: BoxDecoration(
          color: selected ? accent : Colors.transparent,
          borderRadius: pillRadius,
        ),
        child: _opens
            // The label is only in the tree while selected; AnimatedSize is
            // what turns its arrival into the pill opening rather than a
            // jump.
            ? AnimatedSize(
                duration: duration,
                curve: Curves.easeOut,
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                    top: overhang,
                    end: overhang,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      icon,
                      if (selected) ...[
                        const SizedBox(width: AppConstants.space8),
                        Flexible(child: label),
                      ],
                    ],
                  ),
                ),
              )
            // Stacked, every item holds the same layout whether or not it is
            // selected, so there is nothing to animate but the fill.
            : Column(mainAxisSize: MainAxisSize.min, children: stacked),
      ),
    };

    // Hugging, nothing divides the width between the items, so a written label
    // would sit against its neighbour's. The pill is left alone: it carries
    // its own padding inside the fill.
    final gutter = hug && _labelled && !pill ? AppConstants.space8 : 0.0;

    final target = ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: AppConstants.touchTarget,
        minHeight: AppConstants.touchTarget,
      ),
      // Shrink-wraps where the item is sized by its content — a pill that
      // stretched to the free space beside it would not be a pill. Ignored
      // where the row hands down a tight width.
      child: Center(
        widthFactor: 1,
        heightFactor: 1,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          // The label below carries the same string as the Semantics above,
          // and reading a destination out twice is what excluding it here
          // avoids.
          child: ExcludeSemantics(child: content),
        ),
      ),
    );

    return MergeSemantics(
      child: Semantics(
        selected: selected,
        // Some of these layouts never draw the label, and a row of unnamed
        // icons is unusable with a screen reader.
        label: destination.label,
        // The badge is inside the excluded content, so its count is said here.
        value: (destination.badgeCount ?? 0) > 0
            ? '${destination.badgeCount}'
            : null,
        child: _tooltipped(
          // The ripple follows the fill it lands on where there is one, so a
          // squared-off pill is not tapped with a round splash.
          child: InkWell(
            onTap: onTap,
            borderRadius: style == AppBottomNavStyle.pill
                ? pillRadius
                : AppConstants.borderRadiusFull,
            child: target,
          ),
        ),
      ),
    );
  }

  /// Names the icon on a long press — but only where the label is not already
  /// written beside it, so a tooltip never repeats what is on screen.
  Widget _tooltipped({required Widget child}) {
    if (_labelled) return child;
    return Tooltip(message: destination.label, child: child);
  }
}
