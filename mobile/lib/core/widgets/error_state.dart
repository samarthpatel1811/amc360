import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';
import 'app_button.dart';

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48, color: AppTheme.error),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 18),
              AppButton(
                label: 'Try Again',
                icon: Icons.refresh,
                onPressed: onRetry,
                width: 150,
                height: 40,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
