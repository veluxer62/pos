import 'package:pos/domain/entities/seat.dart';

abstract interface class ISeatRepository {
  /// seatNumber 오름차순 정렬.
  Future<List<Seat>> findAll();
  Future<Seat?> findById(String id);
  Future<Seat?> findBySeatNumber(String seatNumber);

  /// [seatNumber] 중복 시 [DuplicateSeatNumberException].
  Future<Seat> create({
    required String seatNumber,
    required int capacity,
  });
  Future<Seat> update(
    String id, {
    String? seatNumber,
    int? capacity,
  });

  /// 활성 주문(PENDING/DELIVERED) 연결 중이면 [SeatInUseException].
  Future<void> delete(String id);
  Stream<List<Seat>> watchAll();
}
