import 'package:pos/domain/entities/seat.dart';
import 'package:pos/domain/repositories/i_seat_repository.dart';

class UpdateSeatUseCase {
  UpdateSeatUseCase({required this.repository});

  final ISeatRepository repository;

  Future<Seat> execute(
    String id, {
    String? seatNumber,
    int? capacity,
  }) async =>
      repository.update(id, seatNumber: seatNumber, capacity: capacity);
}
