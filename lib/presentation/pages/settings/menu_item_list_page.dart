import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos/core/utils/currency_formatter.dart';
import 'package:pos/domain/entities/menu_item.dart';
import 'package:pos/domain/exceptions/domain_exceptions.dart';
import 'package:pos/presentation/pages/settings/widgets/menu_item_form_dialog.dart';
import 'package:pos/presentation/providers/settings_providers.dart';
import 'package:pos/presentation/theme/app_colors.dart';
import 'package:pos/presentation/theme/app_spacing.dart';
import 'package:pos/presentation/theme/app_typography.dart';
import 'package:pos/presentation/widgets/app_error_widget.dart';
import 'package:pos/presentation/widgets/app_snack_bar.dart';
import 'package:pos/presentation/widgets/confirm_dialog.dart';

class MenuItemListPage extends ConsumerWidget {
  const MenuItemListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(menuItemStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('메뉴 관리', style: AppTypography.appBarTitle),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          Semantics(
            button: true,
            label: '메뉴 추가',
            child: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _addItem(context, ref),
            ),
          ),
        ],
      ),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(message: e.toString()),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text('등록된 메뉴가 없습니다.', style: AppTypography.bodyMedium),
            );
          }

          final byCategory = <String, List<MenuItem>>{};
          for (final item in items) {
            byCategory.putIfAbsent(item.category, () => []).add(item);
          }
          final categories = byCategory.keys.toList()..sort();

          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, i) {
              final category = categories[i];
              final categoryItems = byCategory[category]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.xs,
                    ),
                    child: Text(
                      category,
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  ...categoryItems.map(
                    (item) => _MenuItemTile(
                      item: item,
                      onEdit: () => _editItem(context, ref, item),
                      onDelete: () => _deleteItem(context, ref, item),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _addItem(BuildContext context, WidgetRef ref) async {
    final result = await MenuItemFormDialog.show(context);
    if (result == null || !context.mounted) return;

    try {
      await ref.read(createMenuItemUseCaseProvider).execute(
            name: result.name,
            price: result.price,
            category: result.category,
          );
      if (context.mounted) AppSnackBar.success(context, '메뉴가 추가되었습니다.');
    } on Exception catch (e) {
      if (context.mounted) AppSnackBar.error(context, e.toString());
    }
  }

  Future<void> _editItem(
    BuildContext context,
    WidgetRef ref,
    MenuItem item,
  ) async {
    final result = await MenuItemFormDialog.show(context, initial: item);
    if (result == null || !context.mounted) return;

    try {
      await ref.read(updateMenuItemUseCaseProvider).execute(
            item.id,
            name: result.name,
            price: result.price,
            category: result.category,
          );
      if (context.mounted) AppSnackBar.success(context, '메뉴가 수정되었습니다.');
    } on Exception catch (e) {
      if (context.mounted) AppSnackBar.error(context, e.toString());
    }
  }

  Future<void> _deleteItem(
    BuildContext context,
    WidgetRef ref,
    MenuItem item,
  ) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: '메뉴 삭제',
      message: '"${item.name}"을(를) 삭제하시겠습니까?\n'
          '진행 중인 주문이 있으면 판매 불가 처리됩니다.',
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(deleteMenuItemUseCaseProvider).execute(item.id);
      if (context.mounted) AppSnackBar.success(context, '메뉴가 삭제되었습니다.');
    } on MenuItemInUseException {
      if (context.mounted) {
        AppSnackBar.error(
          context,
          '진행 중인 주문에서 사용 중입니다. 주문 완료 후 다시 시도하세요.',
        );
      }
    } on Exception catch (e) {
      if (context.mounted) AppSnackBar.error(context, e.toString());
    }
  }
}

class _MenuItemTile extends StatelessWidget {
  const _MenuItemTile({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final MenuItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => ListTile(
        tileColor: AppColors.surface,
        title: Text(
          item.name,
          style: AppTypography.bodyLarge.copyWith(
            color: item.isAvailable ? null : AppColors.textDisabled,
          ),
        ),
        subtitle: Text(
          CurrencyFormatter.format(item.price),
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        trailing: item.isAvailable
            ? null
            : Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  '판매 불가',
                  style: AppTypography.labelSmall
                      .copyWith(color: AppColors.error),
                ),
              ),
        onTap: onEdit,
        onLongPress: onDelete,
      );
}
