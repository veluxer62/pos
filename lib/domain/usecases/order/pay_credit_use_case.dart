import 'package:pos/domain/entities/order.dart';
import 'package:pos/domain/exceptions/domain_exceptions.dart';
import 'package:pos/domain/repositories/i_credit_account_repository.dart';
import 'package:pos/domain/repositories/i_order_repository.dart';

class PayCreditUseCase {
  PayCreditUseCase({
    required this.orderRepository,
    required this.creditAccountRepository,
  });

  final IOrderRepository orderRepository;
  final ICreditAccountRepository creditAccountRepository;

  Future<Order> execute(String orderId, String creditAccountId) async {
    final order = await orderRepository.findById(orderId);
    if (order == null) throw OrderNotFoundException(orderId);

    await creditAccountRepository.charge(
      accountId: creditAccountId,
      orderId: orderId,
      amount: order.totalAmount,
    );

    return orderRepository.payCredit(orderId, creditAccountId);
  }
}
