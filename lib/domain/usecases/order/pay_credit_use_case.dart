import 'package:pos/domain/entities/order.dart';
import 'package:pos/domain/repositories/i_order_repository.dart';

class PayCreditUseCase {
  PayCreditUseCase({required this.orderRepository});

  final IOrderRepository orderRepository;

  Future<Order> execute(String orderId, String creditAccountId) async =>
      orderRepository.payCredit(orderId, creditAccountId);
}
