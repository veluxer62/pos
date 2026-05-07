import 'package:pos/domain/entities/order.dart';
import 'package:pos/domain/exceptions/domain_exceptions.dart';
import 'package:pos/domain/repositories/i_order_repository.dart';
import 'package:pos/domain/value_objects/order_status.dart';

class RemoveOrderItemUseCase {
  RemoveOrderItemUseCase({required this.orderRepository});

  final IOrderRepository orderRepository;

  Future<Order> execute({
    required String orderId,
    required String orderItemId,
  }) async {
    final order = await orderRepository.findById(orderId);
    if (order == null) throw OrderNotFoundException(orderId);

    if (order.status is! OrderStatusPending) {
      throw OrderNotEditableException(
        orderId: orderId,
        currentStatus: order.status.name,
      );
    }

    final items = await orderRepository.watchItemsByOrder(orderId).first;
    if (items.length <= 1) {
      throw MinimumOrderItemException(orderId: orderId);
    }

    return orderRepository.removeItem(orderId, orderItemId);
  }
}
