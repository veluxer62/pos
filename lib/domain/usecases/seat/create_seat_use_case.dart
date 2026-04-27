import 'package:pos/domain/entities/seat.dart';
import 'package:pos/domain/repositories/i_seat_repository.dart';

class CreateSeatUseCase {
  CreateSeatUseCase({required this.repository});

  final ISeatRepository repository;

  Future<Seat> execute({
    required String seatNumber,
    required int capacity,
  }) async =>
      repository.create(seatNumber: seatNumber, capacity: capacity);
}
