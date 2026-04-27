import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pos/domain/exceptions/domain_exceptions.dart';
import 'package:pos/domain/repositories/i_seat_repository.dart';
import 'package:pos/domain/usecases/seat/delete_seat_use_case.dart';

import 'delete_seat_use_case_test.mocks.dart';

@GenerateMocks([ISeatRepository])
void main() {
  late MockISeatRepository mockRepo;
  late DeleteSeatUseCase sut;

  setUp(() {
    mockRepo = MockISeatRepository();
    sut = DeleteSeatUseCase(repository: mockRepo);
  });

  group('DeleteSeatUseCase', () {
    test('활성 주문이 없으면 repository.delete를 호출한다', () async {
      when(mockRepo.delete(any)).thenAnswer((_) async {});

      await sut.execute('seat-1');

      verify(mockRepo.delete('seat-1')).called(1);
    });

    test('활성 주문 연결 중이면 SeatInUseException을 전파한다', () async {
      when(mockRepo.delete(any)).thenThrow(const SeatInUseException());

      await expectLater(
        sut.execute('seat-1'),
        throwsA(isA<SeatInUseException>()),
      );
    });
  });
}
