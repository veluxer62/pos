import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos/core/di/providers.dart';
import 'package:pos/presentation/providers/credit_account_providers.dart';
import 'package:pos/presentation/theme/app_colors.dart';
import 'package:pos/presentation/theme/app_spacing.dart';
import 'package:pos/presentation/theme/app_typography.dart';
import 'package:pos/presentation/widgets/app_button.dart';

class CreditAccountFormPage extends ConsumerStatefulWidget {
  const CreditAccountFormPage({super.key});

  @override
  ConsumerState<CreditAccountFormPage> createState() =>
      _CreditAccountFormPageState();
}

class _CreditAccountFormPageState extends ConsumerState<CreditAccountFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final name = _nameCtrl.text.trim();
      final phone =
          _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim();
      final note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();

      await ref.read(creditAccountRepositoryProvider).create(
            name,
            phone: phone,
            note: note,
          );

      ref.invalidate(creditAccountListProvider);

      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('외상 계좌 추가', style: AppTypography.appBarTitle),
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            children: [
              TextFormField(
                controller: _nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: '고객 이름',
                  hintText: '이름을 입력하세요',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return '고객 이름을 입력해 주세요.';
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(
                  labelText: '연락처 (선택)',
                  hintText: '010-0000-0000',
                ),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _noteCtrl,
                decoration: const InputDecoration(
                  labelText: '메모 (선택)',
                  hintText: '메모를 입력하세요',
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: '저장',
                variant: AppButtonVariant.primary,
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _submit,
              ),
            ],
          ),
        ),
      );
}
