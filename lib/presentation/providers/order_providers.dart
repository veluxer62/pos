import 'package:pos/core/di/providers.dart';
import 'package:pos/domain/entities/menu_item.dart';
import 'package:pos/domain/entities/order.dart';
import 'package:pos/domain/entities/seat.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'order_providers.g.dart';

@riverpod
Future<List<MenuItem>> menuItemList(Ref ref, {bool onlyAvailable = true}) {
  final repo = ref.watch(menuItemRepositoryProvider);
  return repo.findAll(onlyAvailable: onlyAvailable);
}

@riverpod
Future<List<Seat>> seatList(Ref ref) {
  final repo = ref.watch(seatRepositoryProvider);
  return repo.findAll();
}

/// 특정 좌석의 활성 주문(PENDING/DELIVERED). 없으면 null.
@riverpod
Future<Order?> activeOrderBySeat(Ref ref, String seatId) {
  final repo = ref.watch(orderRepositoryProvider);
  return repo.findActiveOrderBySeat(seatId);
}

@riverpod
Future<Order?> orderDetail(Ref ref, String orderId) {
  final repo = ref.watch(orderRepositoryProvider);
  return repo.findById(orderId);
}
