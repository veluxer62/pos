import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pos/domain/entities/business_day.dart';
import 'package:pos/domain/exceptions/domain_exceptions.dart';
import 'package:pos/domain/repositories/i_business_day_repository.dart';
import 'package:pos/domain/usecases/business_day/open_business_day_use_case.dart';
import 'package:pos/domain/value_objects/business_day_status.dart';

import 'open_business_day_use_case_test.mocks.dart';

@GenerateMocks([IBusinessDayRepository])
void main() {
  late MockIBusinessDayRepository mockRepo;
  late OpenBusinessDayUseCase sut;

  final now = DateTime(2024);

  final openDay = BusinessDay(
    id: 'bd-1',
    status: BusinessDayStatus.open,
    openedAt: now,
    createdAt: now,
  );

  setUp(() {
    mockRepo = MockIBusinessDayRepository();
    sut = OpenBusinessDayUseCase(repository: mockRepo);
  });

  group('OpenBusinessDayUseCase', () {
    test('정상 개시 시 OPEN 상태의 BusinessDay를 반환한다', () async {
      when(mockRepo.open()).thenAnswer((_) async => openDay);

      final result = await sut.execute();

      expect(result.status, BusinessDayStatus.open);
      verify(mockRepo.open()).called(1);
    });

    test('이미 OPEN 영업일이 있으면 BusinessDayAlreadyOpenException을 전파한다', () async {
      when(mockRepo.open()).thenThrow(const BusinessDayAlreadyOpenException());

      await expectLater(
        sut.execute(),
        throwsA(isA<BusinessDayAlreadyOpenException>()),
      );
    });
  });
}
