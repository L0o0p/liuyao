import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 浅绿底加圆点纹理的页面背景。
class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: const _DotPainter(), child: child);
  }
}

class _DotPainter extends CustomPainter {
  const _DotPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.page);
    final dot = Paint()..color = AppColors.pageDot;
    const step = 20.0;
    for (var y = step / 2; y < size.height; y += step) {
      for (var x = step / 2; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 1.5, dot);
      }
    }
  }

  @override
  bool shouldRepaint(_DotPainter oldDelegate) => false;
}

/// 描边加实色下投影的卡片。传了 [onTap] 时按下会下沉。
class TactileCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color borderColor;
  final Color? shadowColor;
  final double borderWidth;
  final double radius;
  final double depth;
  final VoidCallback? onTap;

  /// 子组件超出圆角时裁掉，用于带装饰底纹的卡片。
  final bool clip;

  const TactileCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = AppColors.card,
    this.borderColor = AppColors.border,
    this.shadowColor,
    this.borderWidth = 2,
    this.radius = 24,
    this.depth = 4,
    this.onTap,
    this.clip = false,
  });

  @override
  State<TactileCard> createState() => _TactileCardState();
}

class _TactileCardState extends State<TactileCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null || _pressed == value) return;
    setState(() {
      _pressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final shadow =
        widget.shadowColor ?? AppColors.border.withValues(alpha: 0.18);
    final sink = _pressed ? widget.depth / 2 : 0.0;
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(0, sink, 0),
      padding: widget.padding,
      clipBehavior: widget.clip ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(widget.radius),
        border: Border.all(
          color: widget.borderColor,
          width: widget.borderWidth,
        ),
        boxShadow: [
          BoxShadow(color: shadow, offset: Offset(0, widget.depth - sink)),
          BoxShadow(
            color: AppColors.border.withValues(alpha: 0.06),
            offset: const Offset(0, 8),
            blurRadius: 16,
          ),
        ],
      ),
      child: widget.child,
    );
    final padded = Padding(
      padding: EdgeInsets.only(bottom: widget.depth),
      child: card,
    );
    if (widget.onTap == null) return padded;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: padded,
    );
  }
}

enum TactileButtonStyle { primary, secondary, danger }

/// 胶囊按钮。按下时下沉，投影收起。[onPressed] 为空时变淡且不可点。
class TactileButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final IconData? trailingIcon;
  final VoidCallback? onPressed;
  final TactileButtonStyle style;
  final bool large;

  const TactileButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.style = TactileButtonStyle.primary,
    this.large = false,
  });

  @override
  State<TactileButton> createState() => _TactileButtonState();
}

class _TactileButtonState extends State<TactileButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onPressed == null || _pressed == value) return;
    setState(() {
      _pressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (
      Color fill,
      Color border,
      Color shadow,
      Color foreground,
    ) = switch (widget.style) {
      TactileButtonStyle.primary => (
        AppColors.cheese,
        AppColors.shadow,
        AppColors.shadow,
        scheme.primary,
      ),
      TactileButtonStyle.secondary => (
        scheme.surface,
        AppColors.border,
        AppColors.border,
        scheme.primary,
      ),
      TactileButtonStyle.danger => (
        AppColors.wrongBg,
        AppColors.wrong,
        AppColors.wrongShadow,
        AppColors.wrong,
      ),
    };
    final depth = widget.large ? 4.0 : 3.0;
    final sink = _pressed ? depth : 0.0;
    final textStyle =
        (widget.large
                ? Theme.of(context).textTheme.headlineMedium
                : Theme.of(context).textTheme.labelLarge)
            ?.copyWith(color: foreground, letterSpacing: widget.large ? 1 : 0);
    final iconSize = widget.large ? 26.0 : 18.0;
    final enabled = widget.onPressed != null;

    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onPressed,
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: Padding(
            padding: EdgeInsets.only(bottom: depth),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
              transform: Matrix4.translationValues(0, sink, 0),
              padding: EdgeInsets.symmetric(
                horizontal: widget.large ? 24 : 14,
                vertical: widget.large ? 14 : 10,
              ),
              decoration: ShapeDecoration(
                color: fill,
                shape: StadiumBorder(side: BorderSide(color: border, width: 2)),
                shadows: [
                  BoxShadow(color: shadow, offset: Offset(0, depth - sink)),
                  if (widget.large && !_pressed)
                    BoxShadow(
                      color: AppColors.shadow.withValues(alpha: 0.18),
                      offset: const Offset(0, 8),
                      blurRadius: 16,
                    ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, size: iconSize, color: foreground),
                    SizedBox(width: widget.large ? 8 : 6),
                  ],
                  Flexible(
                    child: Text(
                      widget.label,
                      style: textStyle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (widget.trailingIcon != null) ...[
                    SizedBox(width: widget.large ? 8 : 6),
                    Icon(
                      widget.trailingIcon,
                      size: iconSize,
                      color: foreground,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 小胶囊标签。
class Pill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color background;
  final Color foreground;
  final Color? border;
  final Color? iconColor;

  const Pill({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
    this.border,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: ShapeDecoration(
        color: background,
        shape: StadiumBorder(
          side: border == null
              ? BorderSide.none
              : BorderSide(color: border!, width: 1.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: iconColor ?? foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}

/// 卡片内标题：左侧一个色点，右侧可放附加信息。
class SectionTitle extends StatelessWidget {
  final String title;
  final Color? dotColor;
  final IconData? icon;
  final Widget? trailing;

  const SectionTitle({
    super.key,
    required this.title,
    this.dotColor,
    this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        if (icon != null)
          Icon(icon, size: 20, color: scheme.primary)
        else
          Container(
            width: 10,
            height: 16,
            decoration: BoxDecoration(
              color: dotColor ?? scheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: scheme.primary),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// 描边圆形图标按钮，用在详情页顶栏。
class RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final button = TactileCard(
      onTap: onPressed,
      padding: const EdgeInsets.all(8),
      radius: 20,
      depth: 3,
      color: scheme.surfaceContainerLowest,
      shadowColor: AppColors.border,
      child: Icon(icon, size: 20, color: scheme.primary),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

/// 二级页面顶栏：返回键、居中的标题胶囊、右侧操作。
class DetailHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget? trailing;

  const DetailHeader({
    super.key,
    required this.title,
    this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          RoundIconButton(
            icon: Icons.arrow_back,
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Center(
              child: TactileCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 6,
                ),
                radius: 999,
                depth: 3,
                color: scheme.surfaceContainerLowest,
                shadowColor: AppColors.border,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon ?? Icons.menu_book,
                      size: 18,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          trailing ?? const SizedBox(width: 40),
        ],
      ),
    );
  }
}

/// 一级页面的大标题行。
class PageHeader extends StatelessWidget {
  final String title;
  final Widget? badge;
  final Widget? trailing;

  const PageHeader({super.key, required this.title, this.badge, this.trailing});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineLarge?.copyWith(color: scheme.primary),
          ),
          if (badge != null) ...[const SizedBox(width: 8), badge!],
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}

class AppNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const AppNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// 底部导航：圆角顶边，选中项用薄荷绿胶囊包住。
class AppBottomNav extends StatelessWidget {
  final List<AppNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(
          top: BorderSide(
            color: AppColors.border.withValues(alpha: 0.2),
            width: 2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.border.withValues(alpha: 0.1),
            offset: const Offset(0, -4),
            blurRadius: 16,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < items.length; i++)
                _NavButton(
                  item: items[i],
                  active: i == currentIndex,
                  onTap: () => onTap(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final AppNavItem item;
  final bool active;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = active ? scheme.onSecondaryFixed : scheme.onSurfaceVariant;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          horizontal: active ? 20 : 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: active ? scheme.secondaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: active
              ? const [BoxShadow(color: AppColors.shadow, offset: Offset(0, 2))]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              active ? item.activeIcon : item.icon,
              size: 22,
              color: active ? scheme.secondary : color,
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 带描边的圆角进度条。
class TactileProgressBar extends StatelessWidget {
  final double value;
  final Color color;
  final double height;

  const TactileProgressBar({
    super.key,
    required this.value,
    required this.color,
    this.height = 12,
  });

  @override
  Widget build(BuildContext context) {
    return TactileSegmentBar(
      segments: [(value.clamp(0.0, 1.0), color)],
      height: height,
    );
  }
}

/// 多段进度条，各段比例之和不超过 1，剩下的露出底色。
class TactileSegmentBar extends StatelessWidget {
  final List<(double, Color)> segments;
  final double height;

  const TactileSegmentBar({
    super.key,
    required this.segments,
    this.height = 14,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: height,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(height),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Row(
              children: [
                for (final (ratio, color) in segments)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    width: constraints.maxWidth * ratio.clamp(0.0, 1.0),
                    color: color,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
