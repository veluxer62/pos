import 'package:flutter/material.dart';
import 'package:pos/presentation/theme/app_colors.dart';
import 'package:pos/presentation/theme/app_spacing.dart';
import 'package:pos/presentation/theme/app_typography.dart';

class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({
    required this.message,
    super.key,
    this.onRetry,
    this.retryLabel = '다시 시도',
    this.icon = Icons.error_outline,
  });

  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;
  final IconData icon;

  /// 전체 화면을 채우는 에러 위젯
  const factory AppErrorWidget.fullScreen({
    required String message,
    Key? key,
    VoidCallback? onRetry,
    String retryLabel,
  }) = _FullScreenErrorWidget;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: AppSpacing.iconLg,
            color: AppColors.error,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.lg),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(retryLabel),
            ),
          ],
        ],
      ),
    );
  }
}

class _FullScreenErrorWidget extends AppErrorWidget {
  const _FullScreenErrorWidget({
    required super.message,
    super.key,
    super.onRetry,
    super.retryLabel,
  }) : super(icon: Icons.wifi_off_outlined);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: super.build(context),
      ),
    );
  }
}
