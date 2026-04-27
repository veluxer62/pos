import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/core/di/providers.dart';
import 'package:pos/core/router/router.dart';
import 'package:pos/core/utils/currency_formatter.dart';
import 'package:pos/domain/entities/order_item.dart';
import 'package:pos/domain/usecases/order/cancel_order_use_case.dart';
import 'package:pos/domain/usecases/order/deliver_order_use_case.dart';
import 'package:pos/domain/value_objects/order_status.dart';
import 'package:pos/presentation/providers/order_providers.dart';
import 'package:pos/presentation/theme/app_colors.dart';
import 'package:pos/presentation/theme/app_spacing.dart';
import 'package:pos/presentation/theme/app_typography.dart';
import 'package:pos/presentation/widgets/app_button.dart';
import 'package:pos/presentation/widgets/app_error_widget.dart';
import 'package:pos/presentation/widgets/app_snack_bar.dart';
import 'package:pos/presentation/widgets/confirm_dialog.dart';

class OrderDetailPage extends ConsumerWidget {
  const OrderDetailPage({required this.orderId, super.key});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('주문 상세', style: AppTypography.appBarTitle),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(message: e.toString()),
        data: (order) {
          if (order == null) {
            return const Center(
              child: Text('주문을 찾을 수 없습니다.', style: AppTypography.bodyLarge),
            );
          }

          final isPending = order.status is OrderStatusPending;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.pagePadding),
                  children: [
                    _StatusBadge(status: order.status),
                    const SizedBox(height: AppSpacing.lg),
                    _OrderItemList(items: const [], editable: isPending),
                  ],
                ),
              ),
              _ActionBar(
                onDeliver: isPending ? () => _deliver(context, ref) : null,
                onPay: order.status is OrderStatusDelivered
                    ? () => context.go(AppRoutes.orderPaymentPath(orderId))
                    : null,
                onCancel: (isPending || order.status is OrderStatusDelivered)
                    ? () => _confirmCancel(context, ref)
                    : null,
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deliver(BuildContext context, WidgetRef ref) async {
    try {
      final useCase = DeliverOrderUseCase(
        orderRepository: ref.read(orderRepositoryProvider),
      );
      await useCase.execute(orderId);
      ref.invalidate(orderDetailProvider(orderId));
      if (context.mounted) AppSnackBar.success(context, '전달 완료 처리되었습니다.');
    } on Exception catch (e) {
      if (context.mounted) AppSnackBar.error(context, e.toString());
    }
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await DestructiveConfirmDialog.show(
      context,
      title: '주문 취소',
      message: '이 주문을 취소하시겠습니까? 취소 후에는 되돌릴 수 없습니다.',
      confirmLabel: '취소 처리',
    );
    if (confirmed != true) return;

    try {
      final useCase = CancelOrderUseCase(
        orderRepository: ref.read(orderRepositoryProvider),
      );
      await useCase.execute(orderId);
      ref.invalidate(orderDetailProvider(orderId));
      if (context.mounted) {
        AppSnackBar.success(context, '주문이 취소되었습니다.');
        context.pop();
      }
    } on Exception catch (e) {
      if (context.mounted) AppSnackBar.error(context, e.toString());
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (status) {
      OrderStatusPending() => (
          '준비중',
          AppColors.statusPending,
          AppColors.statusPendingBg
        ),
      OrderStatusDelivered() => (
          '전달 완료',
          AppColors.statusDelivered,
          AppColors.statusDeliveredBg
        ),
      OrderStatusPaid() => (
          '결제 완료',
          AppColors.statusPaid,
          AppColors.statusPaidBg
        ),
      OrderStatusCredited() => (
          '외상',
          AppColors.statusCredited,
          AppColors.statusCreditedBg
        ),
      OrderStatusCancelled() => (
          '취소',
          AppColors.statusCancelled,
          AppColors.statusCancelledBg
        ),
      OrderStatusRefunded() => (
          '환불',
          AppColors.statusRefunded,
          AppColors.statusRefundedBg
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        label,
        style: AppTypography.labelLarge.copyWith(color: color),
      ),
    );
  }
}

class _OrderItemList extends StatelessWidget {
  const _OrderItemList({required this.items, required this.editable});

  final List<OrderItem> items;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Text(
        '주문 항목을 불러오는 중...',
        style: AppTypography.bodyMedium,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('주문 항목', style: AppTypography.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              children: [
                Expanded(
                  child: Text(item.menuName, style: AppTypography.bodyMedium),
                ),
                Text('×${item.quantity}', style: AppTypography.bodyMedium),
                const SizedBox(width: AppSpacing.md),
                Text(
                  CurrencyFormatter.format(item.subtotal),
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.onDeliver,
    required this.onPay,
    required this.onCancel,
  });

  final VoidCallback? onDeliver;
  final VoidCallback? onPay;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.surface,
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: SafeArea(
          child: Row(
            children: [
              if (onCancel != null)
                Expanded(
                  child: AppButton(
                    label: '주문 취소',
                    variant: AppButtonVariant.destructive,
                    onPressed: onCancel,
                  ),
                ),
              if (onCancel != null && (onDeliver != null || onPay != null))
                const SizedBox(width: AppSpacing.md),
              if (onDeliver != null)
                Expanded(
                  child: AppButton(
                    label: '전달 완료',
                    variant: AppButtonVariant.primary,
                    onPressed: onDeliver,
                  ),
                ),
              if (onPay != null)
                Expanded(
                  child: AppButton(
                    label: '결제하기',
                    variant: AppButtonVariant.primary,
                    onPressed: onPay,
                  ),
                ),
            ],
          ),
        ),
      );
}
