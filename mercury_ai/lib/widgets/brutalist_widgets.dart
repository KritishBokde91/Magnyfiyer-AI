import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─── Brutalist Button ─────────────────────────────────────────────────────────
class BrutalistButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool filled;
  final bool danger;
  final bool small;
  final Color? customBg;

  const BrutalistButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.filled = true,
    this.danger = false,
    this.small = false,
    this.customBg,
  });

  @override
  State<BrutalistButton> createState() => _BrutalistButtonState();
}

class _BrutalistButtonState extends State<BrutalistButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = widget.customBg ??
        (widget.danger
            ? AppColors.error
            : widget.filled
                ? (isDark ? AppColors.accent : AppColors.black)
                : Colors.transparent);
    final fg = widget.danger
        ? AppColors.white
        : widget.filled
            ? (isDark ? AppColors.black : AppColors.white)
            : (isDark ? AppColors.accent : AppColors.black);
    final borderColor = widget.danger
        ? AppColors.error
        : (isDark ? AppColors.accent : AppColors.black);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        transform: _pressed
            ? (Matrix4.identity()..translate(2.0, 2.0))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: borderColor, width: 2),
          boxShadow: _pressed
              ? []
              : [BoxShadow(color: borderColor, offset: const Offset(3, 3), blurRadius: 0)],
        ),
        padding: EdgeInsets.symmetric(
          horizontal: widget.small ? 12 : 18,
          vertical: widget.small ? 8 : 12,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, color: fg, size: widget.small ? 14 : 16),
              const SizedBox(width: 6),
            ],
            Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontWeight: FontWeight.w700,
                fontSize: widget.small ? 11 : 13,
                color: fg,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Brutalist Card ───────────────────────────────────────────────────────────
class BrutalistCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? bg;
  final double shadowOffset;
  final VoidCallback? onTap;

  const BrutalistCard({
    super.key,
    required this.child,
    this.padding,
    this.bg,
    this.shadowOffset = 4,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = bg ?? (isDark ? AppColors.darkCard : AppColors.white);
    final borderColor = isDark ? AppColors.accent.withOpacity(0.4) : AppColors.black;
    final shadowColor = isDark ? AppColors.accent.withOpacity(0.3) : AppColors.black;

    Widget card = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            offset: Offset(shadowOffset, shadowOffset),
            blurRadius: 0,
          )
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }
}

// ─── Brutalist Tag ────────────────────────────────────────────────────────────
class BrutalistTag extends StatelessWidget {
  final String label;
  final Color? color;

  const BrutalistTag({super.key, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = color ?? (isDark ? AppColors.accent : AppColors.black);
    final fg = isDark ? AppColors.black : AppColors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: bg, width: 1),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontFamily: 'SpaceMono',
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ─── Status Indicator ─────────────────────────────────────────────────────────
class StatusDot extends StatelessWidget {
  final bool connected;

  const StatusDot({super.key, required this.connected});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: connected ? AppColors.accent : AppColors.error,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          connected ? 'CONNECTED' : 'OFFLINE',
          style: TextStyle(
            fontFamily: 'SpaceMono',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: connected ? AppColors.accent : AppColors.error,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

// ─── Loading Dots ─────────────────────────────────────────────────────────────
class LoadingDots extends StatefulWidget {
  final Color? color;
  const LoadingDots({super.key, this.color});

  @override
  State<LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = widget.color ?? (isDark ? AppColors.accent : AppColors.black);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final delay = i * 0.33;
          final value = (((_ctrl.value - delay) % 1.0 + 1.0) % 1.0);
          final opacity = value < 0.5
              ? (value * 2).clamp(0.3, 1.0)
              : ((1 - value) * 2).clamp(0.3, 1.0);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Opacity(
              opacity: opacity,
              child: Container(
                width: 6,
                height: 6,
                color: color,
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Section Divider ──────────────────────────────────────────────────────────
class BrutalistDivider extends StatelessWidget {
  final String? label;
  const BrutalistDivider({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? AppColors.mutedDark : AppColors.borderLight;
    if (label == null) {
      return Container(height: 1, color: color, margin: const EdgeInsets.symmetric(vertical: 8));
    }
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: color)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label!.toUpperCase(),
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.muted : AppColors.muted,
              letterSpacing: 2,
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: color)),
      ],
    );
  }
}
