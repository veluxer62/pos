import 'package:pos/domain/entities/order.dart';
import 'package:pos/domain/repositories/i_order_repository.dart';

class CancelOrderUseCase {
  CancelOrderUseCase({required this.orderRepository});

  final IOrderRepository orderRepository;

  Future<Order> execute(String orderId) async => orderRepository.cancel(orderId);
}
