import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos/domain/entities/menu_item.dart';
import 'package:pos/presentation/theme/app_colors.dart';
import 'package:pos/presentation/theme/app_spacing.dart';
import 'package:pos/presentation/theme/app_typography.dart';
import 'package:pos/presentation/widgets/app_button.dart';

class MenuItemFormResult {
  const MenuItemFormResult({
    required this.name,
    required this.price,
    required this.category,
  });

  final String name;
  final int price;
  final String category;
}

class MenuItemFormDialog extends StatefulWidget {
  const MenuItemFormDialog({this.initial, super.key});

  final MenuItem? initial;

  static Future<MenuItemFormResult?> show(
    BuildContext context, {
    MenuItem? initial,
  }) =>
      showDialog<MenuItemFormResult>(
        context: context,
        builder: (_) => MenuItemFormDialog(initial: initial),
      );

  @override
  State<MenuItemFormDialog> createState() => _MenuItemFormDialogState();
}

class _MenuItemFormDialogState extends State<MenuItemFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _categoryCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initial?.name ?? '');
    _priceCtrl = TextEditingController(
      text: widget.initial != null ? '${widget.initial!.price}' : '',
    );
    _categoryCtrl = TextEditingController(
      text: widget.initial?.category ?? '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      MenuItemFormResult(
        name: _nameCtrl.text.trim(),
        price: int.parse(_priceCtrl.text),
        category: _categoryCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;

    return AlertDialog(
      title: Text(
        isEdit ? '메뉴 수정' : '메뉴 추가',
        style: AppTypography.titleMedium,
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: '메뉴 이름'),
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '메뉴 이름을 입력하세요.' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _priceCtrl,
              decoration: const InputDecoration(
                labelText: '가격 (원)',
                prefixText: '₩ ',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.isEmpty) return '가격을 입력하세요.';
                final price = int.tryParse(v);
                if (price == null || price <= 0) return '올바른 금액을 입력하세요.';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _categoryCtrl,
              decoration: const InputDecoration(labelText: '카테고리'),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '카테고리를 입력하세요.' : null,
            ),
          ],
        ),
      ),
      actions: [
        Semantics(
          button: true,
          label: '메뉴 입력 취소',
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
        ),
        AppButton(
          label: isEdit ? '수정' : '추가',
          variant: AppButtonVariant.primary,
          onPressed: _submit,
        ),
      ],
      backgroundColor: AppColors.surface,
    );
  }
}
