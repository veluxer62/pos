import 'package:pos/domain/entities/order.dart';
import 'package:pos/domain/exceptions/domain_exceptions.dart';
import 'package:pos/domain/repositories/i_menu_item_repository.dart';
import 'package:pos/domain/repositories/i_order_repository.dart';
import 'package:pos/domain/value_objects/order_status.dart';

class AddOrderItemUseCase {
  AddOrderItemUseCase({
    required this.orderRepository,
    required this.menuItemRepository,
  });

  final IOrderRepository orderRepository;
  final IMenuItemRepository menuItemRepository;

  Future<Order> execute({
    required String orderId,
    required String menuItemId,
    required int quantity,
  }) async {
    if (quantity < 1) {
      throw ArgumentError.value(quantity, 'quantity', 'must be >= 1');
    }

    final order = await orderRepository.findById(orderId);
    if (order == null) throw OrderNotFoundException(orderId);

    if (order.status is! OrderStatusPending) {
      throw OrderNotEditableException(
        orderId: orderId,
        currentStatus: order.status.name,
      );
    }

    final menuItem = await menuItemRepository.findById(menuItemId);
    if (menuItem == null) throw MenuItemNotFoundException(menuItemId);

    if (!menuItem.isAvailable) {
      throw MenuNotAvailableException(menuItemId: menuItemId);
    }

    return orderRepository.addItem(
      orderId,
      OrderItemInput(menuItemId: menuItemId, quantity: quantity),
    );
  }
}
