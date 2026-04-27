import 'package:pos/domain/repositories/i_seat_repository.dart';

class DeleteSeatUseCase {
  DeleteSeatUseCase({required this.repository});

  final ISeatRepository repository;

  Future<void> execute(String id) async => repository.delete(id);
}
