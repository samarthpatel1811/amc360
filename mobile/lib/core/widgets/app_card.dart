import 'dart:ui';
import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

class AppCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final Gradient? gradient;
  final Border? border;
  final BorderRadius? borderRadius;
  final bool hasShadow;
  final bool isGlass;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.margin,
    this.onTap,
    this.color,
    this.gradient,
    this.border,
    this.borderRadius,
    this.hasShadow = true,
    this.isGlass = false,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final radius = widget.borderRadius ?? AppRadius.cardRadius;

    final defaultBg = widget.color ?? (isDark ? AppTheme.darkCard : AppTheme.lightCard);
    final defaultBorder = widget.border ??
        Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          width: 1,
        );

    Widget cardBody = Container(
      decoration: BoxDecoration(
        color: widget.gradient == null ? defaultBg : null,
        gradient: widget.gradient,
        borderRadius: radius,
        border: defaultBorder,
        boxShadow: widget.hasShadow ? AppShadows.card(isDark: isDark) : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: radius,
          splashColor: theme.primaryColor.withAlpha(20),
          highlightColor: theme.primaryColor.withAlpha(10),
          child: Padding(
            padding: widget.padding,
            child: widget.child,
          ),
        ),
      ),
    );

    if (widget.isGlass) {
      cardBody = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: cardBody,
        ),
      );
    }

    if (widget.margin != null) {
      cardBody = Padding(
        padding: widget.margin!,
        child: cardBody,
      );
    }

    if (widget.onTap != null) {
      return GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        behavior: HitTestBehavior.translucent,
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: cardBody,
        ),
      );
    }

    return cardBody;
  }
}
