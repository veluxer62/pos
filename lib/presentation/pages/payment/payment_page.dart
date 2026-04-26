import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/core/di/providers.dart';
import 'package:pos/core/utils/currency_formatter.dart';
import 'package:pos/domain/entities/credit_account.dart';
import 'package:pos/domain/usecases/order/pay_credit_use_case.dart';
import 'package:pos/domain/usecases/order/pay_immediate_use_case.dart';
import 'package:pos/domain/value_objects/order_status.dart';
import 'package:pos/presentation/pages/payment/widgets/credit_account_select_widget.dart';
import 'package:pos/presentation/providers/order_providers.dart';
import 'package:pos/presentation/theme/app_colors.dart';
import 'package:pos/presentation/theme/app_spacing.dart';
import 'package:pos/presentation/theme/app_typography.dart';
import 'package:pos/presentation/widgets/app_button.dart';
import 'package:pos/presentation/widgets/app_error_widget.dart';
import 'package:pos/presentation/widgets/app_snack_bar.dart';

class PaymentPage extends ConsumerStatefulWidget {
  const PaymentPage({required this.orderId, super.key});

  final String orderId;

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('결제', style: AppTypography.appBarTitle),
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

          final isDelivered = order.status is OrderStatusDelivered;

          return Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.pagePadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('결제 금액', style: AppTypography.titleSmall),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        CurrencyFormatter.format(order.totalAmount),
                        style: AppTypography.amountLarge.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      if (!isDelivered) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          '전달 완료 상태인 주문만 결제할 수 있습니다.',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              _PaymentActionBar(
                isEnabled: isDelivered && !_isProcessing,
                isProcessing: _isProcessing,
                onPayImmediate: () => _payImmediate(context),
                onPayCredit: () => _showCreditSheet(context),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _payImmediate(BuildContext context) async {
    setState(() => _isProcessing = true);
    try {
      final useCase = PayImmediateUseCase(
        orderRepository: ref.read(orderRepositoryProvider),
      );
      await useCase.execute(widget.orderId);
      if (context.mounted) {
        AppSnackBar.success(context, '즉시 결제가 완료되었습니다.');
        context.pop();
      }
    } on Exception catch (e) {
      if (context.mounted) AppSnackBar.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _showCreditSheet(BuildContext context) async {
    final account = await showModalBottomSheet<CreditAccount>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          child: CreditAccountSelectWidget(
            onSelected: (a) => Navigator.of(ctx).pop(a),
          ),
        ),
      ),
    );
    if (account == null) return;
    if (!context.mounted) return;
    await _payCredit(context, account);
  }

  Future<void> _payCredit(BuildContext context, CreditAccount account) async {
    setState(() => _isProcessing = true);
    try {
      final useCase = PayCreditUseCase(
        orderRepository: ref.read(orderRepositoryProvider),
      );
      await useCase.execute(widget.orderId, account.id);
      if (context.mounted) {
        AppSnackBar.success(context, '${account.customerName} 외상 처리가 완료되었습니다.');
        context.pop();
      }
    } on Exception catch (e) {
      if (context.mounted) AppSnackBar.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}

class _PaymentActionBar extends StatelessWidget {
  const _PaymentActionBar({
    required this.isEnabled,
    required this.isProcessing,
    required this.onPayImmediate,
    required this.onPayCredit,
  });

  final bool isEnabled;
  final bool isProcessing;
  final VoidCallback onPayImmediate;
  final VoidCallback onPayCredit;

  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.surface,
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: AppButton(
                  label: isProcessing ? '처리 중...' : '외상 결제',
                  variant: AppButtonVariant.secondary,
                  onPressed: isEnabled ? onPayCredit : null,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppButton(
                  label: isProcessing ? '처리 중...' : '즉시 결제',
                  variant: AppButtonVariant.primary,
                  onPressed: isEnabled ? onPayImmediate : null,
                ),
              ),
            ],
          ),
        ),
      );
}
