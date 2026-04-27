import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pos/domain/entities/seat.dart';
import 'package:pos/domain/exceptions/domain_exceptions.dart';
import 'package:pos/domain/repositories/i_seat_repository.dart';
import 'package:pos/domain/usecases/seat/update_seat_use_case.dart';

import 'update_seat_use_case_test.mocks.dart';

@GenerateMocks([ISeatRepository])
void main() {
  late MockISeatRepository mockRepo;
  late UpdateSeatUseCase sut;

  final now = DateTime(2024);

  final seat = Seat(
    id: 'seat-1',
    seatNumber: 'A1',
    capacity: 4,
    createdAt: now,
    updatedAt: now,
  );

  setUp(() {
    mockRepo = MockISeatRepository();
    sut = UpdateSeatUseCase(repository: mockRepo);
  });

  test('정상적으로 좌석을 수정한다', () async {
    final updated = seat.copyWith(capacity: 6);
    when(mockRepo.update('seat-1', capacity: 6))
        .thenAnswer((_) async => updated);

    final result = await sut.execute('seat-1', capacity: 6);

    expect(result.capacity, 6);
    verify(mockRepo.update('seat-1', capacity: 6)).called(1);
  });

  test('SeatNotFoundException을 그대로 전파한다', () async {
    when(mockRepo.update('nonexistent'))
        .thenThrow(const SeatNotFoundException('nonexistent'));

    await expectLater(
      sut.execute('nonexistent'),
      throwsA(isA<SeatNotFoundException>()),
    );
  });

  test('DuplicateSeatNumberException을 그대로 전파한다', () async {
    when(mockRepo.update('seat-1', seatNumber: 'B1'))
        .thenThrow(const DuplicateSeatNumberException('B1'));

    await expectLater(
      sut.execute('seat-1', seatNumber: 'B1'),
      throwsA(isA<DuplicateSeatNumberException>()),
    );
  });
}
