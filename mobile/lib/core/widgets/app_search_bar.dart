import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

class AppSearchBar extends StatelessWidget {
  final String hint;
  final String? hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;
  final TextEditingController? controller;

  const AppSearchBar({
    super.key,
    this.hint = 'Search...',
    this.hintText,
    required this.onChanged,
    this.onClear,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveHint = hintText ?? hint;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final hintColor = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(fontSize: 14, color: textColor),
        decoration: InputDecoration(
          hintText: effectiveHint,
          hintStyle: TextStyle(color: hintColor, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: hintColor, size: 20),
          suffixIcon: controller != null && controller!.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close, size: 18, color: hintColor),
                  onPressed: () {
                    controller!.clear();
                    onChanged('');
                    if (onClear != null) onClear!();
                  },
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}
