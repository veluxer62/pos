import 'package:flutter/material.dart';
import 'package:pos/presentation/theme/app_colors.dart';
import 'package:pos/presentation/theme/app_spacing.dart';

enum AppButtonVariant { primary, secondary, destructive, outline, text }

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.enabled = true,
    this.width,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool enabled;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed =
        (enabled && !isLoading) ? onPressed : null;

    return SizedBox(
      width: width,
      height: AppSpacing.minTouchTarget,
      child: Semantics(
        button: true,
        enabled: enabled && !isLoading,
        label: label,
        child: switch (variant) {
          AppButtonVariant.primary => _buildElevated(
              context,
              effectiveOnPressed,
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
          AppButtonVariant.secondary => _buildElevated(
              context,
              effectiveOnPressed,
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.onSecondary,
            ),
          AppButtonVariant.destructive => _buildElevated(
              context,
              effectiveOnPressed,
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.onPrimary,
            ),
          AppButtonVariant.outline => _buildOutlined(
              context,
              effectiveOnPressed,
            ),
          AppButtonVariant.text => _buildText(
              context,
              effectiveOnPressed,
            ),
        },
      ),
    );
  }

  Widget _buildElevated(
    BuildContext context,
    VoidCallback? onPressed, {
    required Color backgroundColor,
    required Color foregroundColor,
  }) =>
      ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          disabledBackgroundColor: AppColors.outline,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
        icon: _buildIconOrLoader(foregroundColor),
        label: Text(label),
      );

  Widget _buildOutlined(BuildContext context, VoidCallback? onPressed) =>
      OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
        icon: _buildIconOrLoader(AppColors.primary),
        label: Text(label),
      );

  Widget _buildText(BuildContext context, VoidCallback? onPressed) =>
      TextButton.icon(
        onPressed: onPressed,
        icon: _buildIconOrLoader(AppColors.primary),
        label: Text(label),
      );

  Widget _buildIconOrLoader(Color color) {
    if (isLoading) {
      return SizedBox(
        width: AppSpacing.iconSm,
        height: AppSpacing.iconSm,
        child: CircularProgressIndicator(
          strokeWidth: AppSpacing.strokeWidthThin,
          color: color,
        ),
      );
    }
    if (icon != null) {
      return Icon(icon, size: AppSpacing.iconMd);
    }
    return const SizedBox.shrink();
  }
}
