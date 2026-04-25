import 'package:flutter/material.dart';
import 'package:pos/presentation/theme/app_colors.dart';
import 'package:pos/presentation/theme/app_spacing.dart';
import 'package:pos/presentation/theme/app_typography.dart';
import 'package:pos/presentation/widgets/app_button.dart';

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
      child: _buildContent(context),
    );
  }

  // _FullScreenErrorWidget에서도 재사용되므로 별도 메서드로 분리
  Column _buildContent(BuildContext context) {
    return Column(
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
          AppButton(
            label: retryLabel,
            variant: AppButtonVariant.text,
            icon: Icons.refresh,
            onPressed: onRetry,
          ),
        ],
      ],
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
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: _buildContent(context),
        ),
      ),
    );
  }
}
