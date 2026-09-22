import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

enum AppButtonType { primary, secondary, outline, danger, subtle }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final AppButtonType type;
  final double? width;
  final double height;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.type = AppButtonType.primary,
    this.width,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;

    Widget content;
    if (isLoading) {
      content = SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          valueColor: AlwaysStoppedAnimation<Color>(
            type == AppButtonType.outline || type == AppButtonType.subtle
                ? primaryColor
                : Colors.white,
          ),
        ),
      );
    } else if (icon != null) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.1),
            ),
          ),
        ],
      );
    } else {
      content = Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.1),
      );
    }

    if (type == AppButtonType.primary) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: AppRadius.buttonRadius,
          gradient: const LinearGradient(
            colors: [Color(0xFF1E40AF), Color(0xFF2563EB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: onPressed != null && !isLoading
              ? AppShadows.primaryButton(primaryColor)
              : null,
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
          ),
          child: content,
        ),
      );
    }

    final buttonStyle = switch (type) {
      AppButtonType.secondary => ElevatedButton.styleFrom(
          backgroundColor: AppTheme.secondaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
        ),
      AppButtonType.outline => OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder, width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
        ),
      AppButtonType.danger => ElevatedButton.styleFrom(
          backgroundColor: AppTheme.error,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
        ),
      AppButtonType.subtle => TextButton.styleFrom(
          foregroundColor: primaryColor,
          backgroundColor: primaryColor.withAlpha(isDark ? 35 : 15),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
        ),
      AppButtonType.primary => null,
    };

    return SizedBox(
      width: width,
      height: height,
      child: type == AppButtonType.outline
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: buttonStyle,
              child: content,
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: buttonStyle,
              child: content,
            ),
    );
  }
}
