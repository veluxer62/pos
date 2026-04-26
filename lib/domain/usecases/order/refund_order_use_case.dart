import 'package:pos/domain/entities/order.dart';
import 'package:pos/domain/repositories/i_order_repository.dart';

class RefundOrderUseCase {
  RefundOrderUseCase({required this.orderRepository});

  final IOrderRepository orderRepository;

  Future<Order> execute(String orderId) async =>
      orderRepository.refund(orderId);
}
