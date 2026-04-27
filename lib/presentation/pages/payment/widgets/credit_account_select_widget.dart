import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos/core/utils/currency_formatter.dart';
import 'package:pos/domain/entities/credit_account.dart';
import 'package:pos/presentation/providers/credit_account_providers.dart';
import 'package:pos/presentation/theme/app_colors.dart';
import 'package:pos/presentation/theme/app_spacing.dart';
import 'package:pos/presentation/theme/app_typography.dart';
import 'package:pos/presentation/widgets/app_error_widget.dart';

class CreditAccountSelectWidget extends ConsumerWidget {
  const CreditAccountSelectWidget({
    required this.onSelected,
    super.key,
  });

  final ValueChanged<CreditAccount> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(creditAccountListProvider());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            AppSpacing.pagePadding,
            AppSpacing.pagePadding,
            AppSpacing.sm,
          ),
          child: Text('외상 계좌 선택', style: AppTypography.titleMedium),
        ),
        accountsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.pagePadding),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => AppErrorWidget(message: e.toString()),
          data: (accounts) {
            if (accounts.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.pagePadding),
                child: Text(
                  '등록된 외상 계좌가 없습니다.',
                  style: AppTypography.bodyMedium,
                ),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: accounts.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final account = accounts[i];
                return ListTile(
                  title: Text(
                    account.customerName,
                    style: AppTypography.bodyLarge,
                  ),
                  trailing: Text(
                    CurrencyFormatter.format(account.balance),
                    style: AppTypography.bodyMedium.copyWith(
                      color: account.balance > 0
                          ? AppColors.error
                          : AppColors.textSecondary,
                    ),
                  ),
                  onTap: () => onSelected(account),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
