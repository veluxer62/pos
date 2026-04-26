import 'package:flutter/material.dart';
import 'package:pos/core/utils/currency_formatter.dart';
import 'package:pos/domain/entities/order.dart';
import 'package:pos/domain/entities/seat.dart';
import 'package:pos/domain/value_objects/order_status.dart';
import 'package:pos/presentation/theme/app_colors.dart';
import 'package:pos/presentation/theme/app_spacing.dart';
import 'package:pos/presentation/theme/app_typography.dart';

class SeatGridWidget extends StatelessWidget {
  const SeatGridWidget({
    required this.seat,
    required this.onTap,
    super.key,
    this.activeOrder,
  });

  final Seat seat;
  final Order? activeOrder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = _resolveStyle();

    return Semantics(
      label: _semanticsLabel(style.statusLabel),
      button: true,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Ink(
          decoration: BoxDecoration(
            color: style.bgColor,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: style.accentColor,
              width: AppSpacing.strokeWidthThin,
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: AppSpacing.minTouchTarget,
              minHeight: AppSpacing.minTouchTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    seat.seatNumber,
                    style: AppTypography.titleLarge.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${seat.capacity}인석',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (style.statusLabel != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _StatusChip(
                      label: style.statusLabel!,
                      color: style.accentColor,
                    ),
                  ],
                  if (activeOrder != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      CurrencyFormatter.format(activeOrder!.totalAmount),
                      style: AppTypography.labelMedium.copyWith(
                        color: style.accentColor,
                      ),
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

  _SeatStyle _resolveStyle() => switch (activeOrder?.status) {
        OrderStatusPending() => const _SeatStyle(
            bgColor: AppColors.statusPendingBg,
            accentColor: AppColors.statusPending,
            statusLabel: '준비중',
          ),
        OrderStatusDelivered() => const _SeatStyle(
            bgColor: AppColors.statusDeliveredBg,
            accentColor: AppColors.statusDelivered,
            statusLabel: '전달 완료',
          ),
        _ => const _SeatStyle(
            bgColor: AppColors.surface,
            accentColor: AppColors.outline,
            statusLabel: null,
          ),
      };

  String _semanticsLabel(String? statusLabel) {
    final status = statusLabel ?? '비어있음';
    return '${seat.seatNumber} ${seat.capacity}인석 $status';
  }
}

class _SeatStyle {
  const _SeatStyle({
    required this.bgColor,
    required this.accentColor,
    required this.statusLabel,
  });

  final Color bgColor;
  final Color accentColor;
  final String? statusLabel;
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(color: color),
        ),
      );
}
