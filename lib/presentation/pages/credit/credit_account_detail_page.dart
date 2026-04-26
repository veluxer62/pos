import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos/core/utils/currency_formatter.dart';
import 'package:pos/domain/entities/credit_transaction.dart';
import 'package:pos/domain/value_objects/credit_transaction_type.dart';
import 'package:pos/presentation/pages/credit/widgets/credit_payment_dialog.dart';
import 'package:pos/presentation/providers/credit_account_providers.dart';
import 'package:pos/presentation/theme/app_colors.dart';
import 'package:pos/presentation/theme/app_spacing.dart';
import 'package:pos/presentation/theme/app_typography.dart';
import 'package:pos/presentation/widgets/app_button.dart';
import 'package:pos/presentation/widgets/app_error_widget.dart';

class CreditAccountDetailPage extends ConsumerWidget {
  const CreditAccountDetailPage({required this.accountId, super.key});

  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountAsync = ref.watch(creditAccountDetailProvider(accountId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('외상 계좌 상세', style: AppTypography.appBarTitle),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: accountAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(message: e.toString()),
        data: (account) {
          if (account == null) {
            return const Center(
              child: Text('계좌를 찾을 수 없습니다.', style: AppTypography.bodyLarge),
            );
          }

          return Column(
            children: [
              _BalanceHeader(
                customerName: account.customerName,
                balance: account.balance,
              ),
              const Divider(height: 1),
              Expanded(
                child: _TransactionList(accountId: accountId),
              ),
              if (account.balance > 0)
                _PaymentBar(
                  accountId: accountId,
                  onPaid: () {
                    ref.invalidate(creditAccountDetailProvider(accountId));
                    ref.invalidate(creditAccountListProvider);
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

class _BalanceHeader extends StatelessWidget {
  const _BalanceHeader({
    required this.customerName,
    required this.balance,
  });

  final String customerName;
  final int balance;

  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.surface,
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(customerName, style: AppTypography.titleLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '미납 잔액',
                    style: AppTypography.labelMedium
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Text(
              CurrencyFormatter.format(balance),
              style: AppTypography.titleLarge.copyWith(
                color: balance > 0 ? AppColors.error : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
}

class _TransactionList extends ConsumerWidget {
  const _TransactionList({required this.accountId});

  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(creditTransactionListProvider(accountId));

    return txAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AppErrorWidget(message: e.toString()),
      data: (transactions) {
        if (transactions.isEmpty) {
          return const Center(
            child: Text('거래 내역이 없습니다.', style: AppTypography.bodyMedium),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          itemCount: transactions.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) => _TransactionTile(tx: transactions[i]),
        );
      },
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.tx});

  final CreditTransaction tx;

  @override
  Widget build(BuildContext context) {
    final isCharge = tx.type == CreditTransactionType.charge;

    return ListTile(
      title: Text(
        isCharge ? '외상 발생' : '납부',
        style: AppTypography.bodyMedium,
      ),
      subtitle: Text(
        _formatDate(tx.createdAt),
        style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
      ),
      trailing: Text(
        '${isCharge ? '+' : '-'}${CurrencyFormatter.format(tx.amount)}',
        style: AppTypography.bodyMedium.copyWith(
          color: isCharge ? AppColors.error : AppColors.success,
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class _PaymentBar extends StatelessWidget {
  const _PaymentBar({required this.accountId, required this.onPaid});

  final String accountId;
  final VoidCallback onPaid;

  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.surface,
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: SafeArea(
          child: AppButton(
            label: '납부 처리',
            variant: AppButtonVariant.primary,
            onPressed: () => CreditPaymentDialog.show(
              context,
              accountId: accountId,
              onPaid: onPaid,
            ),
          ),
        ),
      );
}
