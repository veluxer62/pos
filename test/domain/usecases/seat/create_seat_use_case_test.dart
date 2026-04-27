import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pos/domain/entities/seat.dart';
import 'package:pos/domain/exceptions/domain_exceptions.dart';
import 'package:pos/domain/repositories/i_seat_repository.dart';
import 'package:pos/domain/usecases/seat/create_seat_use_case.dart';

import 'create_seat_use_case_test.mocks.dart';

@GenerateMocks([ISeatRepository])
void main() {
  late MockISeatRepository mockRepo;
  late CreateSeatUseCase sut;

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
    sut = CreateSeatUseCase(repository: mockRepo);
  });

  group('CreateSeatUseCase', () {
    test('정상 생성 시 Seat을 반환한다', () async {
      when(
        mockRepo.create(
          seatNumber: anyNamed('seatNumber'),
          capacity: anyNamed('capacity'),
        ),
      ).thenAnswer((_) async => seat);

      final result = await sut.execute(seatNumber: 'A1', capacity: 4);

      expect(result.seatNumber, 'A1');
      expect(result.capacity, 4);
    });

    test('중복 좌석 번호 시 DuplicateSeatNumberException을 전파한다', () async {
      when(
        mockRepo.create(
          seatNumber: anyNamed('seatNumber'),
          capacity: anyNamed('capacity'),
        ),
      ).thenThrow(const DuplicateSeatNumberException('A1'));

      await expectLater(
        sut.execute(seatNumber: 'A1', capacity: 4),
        throwsA(isA<DuplicateSeatNumberException>()),
      );
    });
  });
}
