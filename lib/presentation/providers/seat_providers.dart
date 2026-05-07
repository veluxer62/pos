import 'package:pos/core/di/providers.dart';
import 'package:pos/data/local/daos/seat_dao.dart';
import 'package:pos/domain/value_objects/seat_with_active_order.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'seat_providers.g.dart';

@Riverpod(keepAlive: true)
SeatDao seatDao(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return SeatDao(db);
}

@riverpod
Stream<List<SeatWithActiveOrder>> seatsWithActiveOrders(Ref ref) {
  return ref.watch(seatDaoProvider).watchAllWithActiveOrders();
}
