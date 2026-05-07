import 'package:pos/domain/entities/order.dart';
import 'package:pos/domain/entities/seat.dart';

class SeatWithActiveOrder {
  const SeatWithActiveOrder({required this.seat, this.activeOrder});

  final Seat seat;

  /// PENDING 또는 DELIVERED 상태 주문. 없으면 null.
  final Order? activeOrder;

  bool get hasActiveOrder => activeOrder != null;
}
