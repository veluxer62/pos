import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos/core/di/providers.dart';
import 'package:pos/core/utils/currency_formatter.dart';
import 'package:pos/presentation/providers/credit_account_providers.dart';
import 'package:pos/presentation/theme/app_colors.dart';
import 'package:pos/presentation/theme/app_spacing.dart';
import 'package:pos/presentation/theme/app_typography.dart';
import 'package:pos/presentation/widgets/app_snack_bar.dart';
import 'package:pos/presentation/widgets/confirm_dialog.dart';

class CreditPaymentDialog extends ConsumerStatefulWidget {
  const CreditPaymentDialog({
    required this.accountId,
    required this.onPaid,
    super.key,
  });

  final String accountId;
  final VoidCallback onPaid;

  static Future<void> show(
    BuildContext context, {
    required String accountId,
    required VoidCallback onPaid,
  }) =>
      showDialog<void>(
        context: context,
        builder: (_) => CreditPaymentDialog(
          accountId: accountId,
          onPaid: onPaid,
        ),
      );

  @override
  ConsumerState<CreditPaymentDialog> createState() =>
      _CreditPaymentDialogState();
}

class _CreditPaymentDialogState extends ConsumerState<CreditPaymentDialog> {
  final _controller = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = int.tryParse(_controller.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) return;

    final account =
        await ref.read(creditAccountDetailProvider(widget.accountId).future);
    if (account == null || !mounted) return;

    final balance = account.balance;

    if (amount > balance) {
      final confirmed = await DestructiveConfirmDialog.show(
        context,
        title: '과납 확인',
        message:
            '납부 금액(${CurrencyFormatter.format(amount)})이 잔액(${CurrencyFormatter.format(balance)})보다 많습니다.\n'
            '잔액이 0원으로 처리됩니다. 계속하시겠습니까?',
        confirmLabel: '납부 처리',
      );
      if (confirmed != true || !mounted) return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(creditAccountRepositoryProvider).pay(
            accountId: widget.accountId,
            amount: amount,
          );
      widget.onPaid();
      if (mounted) {
        Navigator.of(context).pop();
        AppSnackBar.success(context, '납부 처리가 완료되었습니다.');
      }
    } on Exception catch (e) {
      if (mounted) AppSnackBar.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountAsync =
        ref.watch(creditAccountDetailProvider(widget.accountId));

    return AlertDialog(
      title: const Text('납부 처리'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          accountAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (account) {
              if (account == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(
                  '잔액: ${CurrencyFormatter.format(account.balance)}',
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.textSecondary),
                ),
              );
            },
          ),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: '납부 금액 (원)',
              suffixText: '원',
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: _isLoading ? null : _submit,
          child: const Text('납부'),
        ),
      ],
    );
  }
}
