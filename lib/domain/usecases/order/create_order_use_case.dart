import 'package:pos/domain/entities/order.dart';
import 'package:pos/domain/exceptions/domain_exceptions.dart';
import 'package:pos/domain/repositories/i_business_day_repository.dart';
import 'package:pos/domain/repositories/i_order_repository.dart';

class CreateOrderUseCase {
  CreateOrderUseCase({
    required this.orderRepository,
    required this.businessDayRepository,
  });

  final IOrderRepository orderRepository;
  final IBusinessDayRepository businessDayRepository;

  Future<Order> execute({
    required String seatId,
    required List<OrderItemInput> items,
  }) async {
    if (items.isEmpty) {
      throw ArgumentError.value(items, 'items', 'must not be empty');
    }

    final businessDay = await businessDayRepository.getOpen();
    if (businessDay == null) throw const BusinessDayNotFoundException();

    return orderRepository.create(
      businessDayId: businessDay.id,
      seatId: seatId,
      items: items,
    );
  }
}
