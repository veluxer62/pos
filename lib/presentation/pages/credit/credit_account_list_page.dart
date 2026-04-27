import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/core/di/providers.dart';
import 'package:pos/core/router/router.dart';
import 'package:pos/core/utils/currency_formatter.dart';
import 'package:pos/domain/entities/credit_account.dart';
import 'package:pos/presentation/providers/credit_account_providers.dart';
import 'package:pos/presentation/theme/app_colors.dart';
import 'package:pos/presentation/theme/app_spacing.dart';
import 'package:pos/presentation/theme/app_typography.dart';
import 'package:pos/presentation/widgets/app_error_widget.dart';

class CreditAccountListPage extends ConsumerWidget {
  const CreditAccountListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(creditAccountListProvider());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('외상 장부', style: AppTypography.appBarTitle),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '계좌 추가',
            onPressed: () => _showCreateDialog(context, ref),
          ),
        ],
      ),
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(message: e.toString()),
        data: (accounts) {
          if (accounts.isEmpty) {
            return const Center(
              child: Text(
                '등록된 외상 계좌가 없습니다.\n우측 상단 + 버튼으로 계좌를 추가하세요.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium,
              ),
            );
          }

          final withBalance = accounts.where((a) => a.balance > 0).toList();
          final cleared = accounts.where((a) => a.balance == 0).toList();

          return ListView(
            children: [
              if (withBalance.isNotEmpty) ...[
                _SectionHeader(
                  title: '미납 계좌',
                  count: withBalance.length,
                ),
                ...withBalance.map((a) => _AccountTile(account: a)),
              ],
              if (cleared.isNotEmpty) ...[
                _SectionHeader(
                  title: '완납 계좌',
                  count: cleared.length,
                ),
                ...cleared.map((a) => _AccountTile(account: a)),
              ],
            ],
          );
        },
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (_) => _CreateAccountDialog(
        onCreated: () => ref.invalidate(creditAccountListProvider),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          AppSpacing.lg,
          AppSpacing.pagePadding,
          AppSpacing.xs,
        ),
        child: Text(
          '$title ($count)',
          style:
              AppTypography.labelLarge.copyWith(color: AppColors.textSecondary),
        ),
      );
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({required this.account});

  final CreditAccount account;

  @override
  Widget build(BuildContext context) => ListTile(
        tileColor: AppColors.surface,
        title: Text(account.customerName, style: AppTypography.bodyLarge),
        trailing: Text(
          CurrencyFormatter.format(account.balance),
          style: AppTypography.bodyMedium.copyWith(
            color:
                account.balance > 0 ? AppColors.error : AppColors.textSecondary,
          ),
        ),
        onTap: () => context.go(AppRoutes.creditDetailPath(account.id)),
      );
}

class _CreateAccountDialog extends ConsumerStatefulWidget {
  const _CreateAccountDialog({required this.onCreated});

  final VoidCallback onCreated;

  @override
  ConsumerState<_CreateAccountDialog> createState() =>
      _CreateAccountDialogState();
}

class _CreateAccountDialogState extends ConsumerState<_CreateAccountDialog> {
  final _controller = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(creditAccountRepositoryProvider).create(name);
      widget.onCreated();
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('외상 계좌 추가'),
        content: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: '고객 이름'),
          onSubmitted: (_) => _submit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: _isLoading ? null : _submit,
            child: const Text('추가'),
          ),
        ],
      );
}
