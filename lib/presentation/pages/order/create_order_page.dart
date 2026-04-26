import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/core/di/providers.dart';
import 'package:pos/core/utils/currency_formatter.dart';
import 'package:pos/domain/entities/menu_item.dart';
import 'package:pos/domain/repositories/i_order_repository.dart';
import 'package:pos/domain/usecases/order/create_order_use_case.dart';
import 'package:pos/presentation/providers/order_providers.dart';
import 'package:pos/presentation/theme/app_colors.dart';
import 'package:pos/presentation/theme/app_spacing.dart';
import 'package:pos/presentation/theme/app_typography.dart';
import 'package:pos/presentation/widgets/app_button.dart';
import 'package:pos/presentation/widgets/app_error_widget.dart';
import 'package:pos/presentation/widgets/app_snack_bar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'create_order_page.g.dart';

// 카트: menuItemId → quantity
@riverpod
class OrderCart extends _$OrderCart {
  @override
  Map<String, int> build() => {};

  void increment(String menuItemId) {
    state = {...state, menuItemId: (state[menuItemId] ?? 0) + 1};
  }

  void decrement(String menuItemId) {
    final current = state[menuItemId] ?? 0;
    if (current <= 1) {
      final next = Map<String, int>.from(state);
      next.remove(menuItemId);
      state = next;
    } else {
      state = {...state, menuItemId: current - 1};
    }
  }

  void clear() => state = {};
}

class CreateOrderPage extends ConsumerStatefulWidget {
  const CreateOrderPage({required this.seatId, super.key});

  final String seatId;

  @override
  ConsumerState<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends ConsumerState<CreateOrderPage> {
  String? _selectedCategory;
  bool _isSubmitting = false;

  @override
  void dispose() {
    ref.read(orderCartProvider.notifier).clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final menuAsync = ref.watch(menuItemListProvider());
    final cart = ref.watch(orderCartProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('주문 생성', style: AppTypography.appBarTitle),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: menuAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(message: e.toString()),
        data: (menus) {
          final categories = menus.map((m) => m.category).toSet().toList()..sort();
          final filtered = _selectedCategory == null
              ? menus
              : menus.where((m) => m.category == _selectedCategory).toList();

          return Column(
            children: [
              _CategoryFilterBar(
                categories: categories,
                selected: _selectedCategory,
                onSelected: (cat) => setState(
                  () => _selectedCategory = _selectedCategory == cat ? null : cat,
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.pagePadding),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (_, i) => _MenuItemTile(
                    menu: filtered[i],
                    quantity: cart[filtered[i].id] ?? 0,
                    onIncrement: () =>
                        ref.read(orderCartProvider.notifier).increment(filtered[i].id),
                    onDecrement: () =>
                        ref.read(orderCartProvider.notifier).decrement(filtered[i].id),
                  ),
                ),
              ),
              _OrderSummaryBar(
                cart: cart,
                menus: menus,
                isSubmitting: _isSubmitting,
                onConfirm: cart.isEmpty ? null : () => _submitOrder(context, cart, menus),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _submitOrder(
    BuildContext context,
    Map<String, int> cart,
    List<MenuItem> menus,
  ) async {
    setState(() => _isSubmitting = true);
    try {
      final useCase = CreateOrderUseCase(
        orderRepository: ref.read(orderRepositoryProvider),
        businessDayRepository: ref.read(businessDayRepositoryProvider),
      );
      final items = cart.entries
          .map((e) => OrderItemInput(menuItemId: e.key, quantity: e.value))
          .toList();

      await useCase.execute(seatId: widget.seatId, items: items);

      ref.read(orderCartProvider.notifier).clear();
      if (context.mounted) {
        AppSnackBar.success(context, '주문이 접수되었습니다.');
        context.pop();
      }
    } on Exception catch (e) {
      if (context.mounted) {
        AppSnackBar.error(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class _CategoryFilterBar extends StatelessWidget {
  const _CategoryFilterBar({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.surface,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pagePadding,
          vertical: AppSpacing.sm,
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: categories
                .map(
                  (cat) => Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: FilterChip(
                      label: Text(cat),
                      selected: selected == cat,
                      onSelected: (_) => onSelected(cat),
                      selectedColor: AppColors.primaryLight.withValues(alpha: 0.3),
                      checkmarkColor: AppColors.primary,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      );
}

class _MenuItemTile extends StatelessWidget {
  const _MenuItemTile({
    required this.menu,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  final MenuItem menu;
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.cardPadding,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(menu.name, style: AppTypography.titleSmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    CurrencyFormatter.format(menu.price),
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            _QuantityControl(
              quantity: quantity,
              onIncrement: onIncrement,
              onDecrement: onDecrement,
            ),
          ],
        ),
      );
}

class _QuantityControl extends StatelessWidget {
  const _QuantityControl({
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Semantics(
            label: '수량 감소',
            button: true,
            child: InkWell(
              onTap: quantity > 0 ? onDecrement : null,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              child: SizedBox(
                width: AppSpacing.minTouchTarget,
                height: AppSpacing.minTouchTarget,
                child: Icon(
                  Icons.remove_circle_outline,
                  color: quantity > 0 ? AppColors.primary : AppColors.textDisabled,
                ),
              ),
            ),
          ),
          SizedBox(
            width: AppSpacing.xxl,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium,
            ),
          ),
          Semantics(
            label: '수량 증가',
            button: true,
            child: InkWell(
              onTap: onIncrement,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              child: const SizedBox(
                width: AppSpacing.minTouchTarget,
                height: AppSpacing.minTouchTarget,
                child: Icon(Icons.add_circle_outline, color: AppColors.primary),
              ),
            ),
          ),
        ],
      );
}

class _OrderSummaryBar extends StatelessWidget {
  const _OrderSummaryBar({
    required this.cart,
    required this.menus,
    required this.isSubmitting,
    required this.onConfirm,
  });

  final Map<String, int> cart;
  final List<MenuItem> menus;
  final bool isSubmitting;
  final VoidCallback? onConfirm;

  int get _totalAmount {
    final priceMap = {for (final m in menus) m.id: m.price};
    return cart.entries.fold(
      0,
      (sum, e) => sum + (priceMap[e.key] ?? 0) * e.value,
    );
  }

  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.surface,
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('총 금액', style: AppTypography.labelMedium),
                    Text(
                      CurrencyFormatter.format(_totalAmount),
                      style: AppTypography.amountMedium.copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              AppButton(
                label: isSubmitting ? '처리 중...' : '주문 확정',
                onPressed: isSubmitting ? null : onConfirm,
                variant: AppButtonVariant.primary,
              ),
            ],
          ),
        ),
      );
}
