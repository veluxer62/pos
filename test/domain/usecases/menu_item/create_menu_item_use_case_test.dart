import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pos/domain/entities/menu_item.dart';
import 'package:pos/domain/repositories/i_menu_item_repository.dart';
import 'package:pos/domain/usecases/menu_item/create_menu_item_use_case.dart';

import 'create_menu_item_use_case_test.mocks.dart';

@GenerateMocks([IMenuItemRepository])
void main() {
  late MockIMenuItemRepository mockRepo;
  late CreateMenuItemUseCase sut;

  final now = DateTime(2024);

  final item = MenuItem(
    id: 'item-1',
    name: '아메리카노',
    price: 4500,
    category: '음료',
    isAvailable: true,
    createdAt: now,
    updatedAt: now,
  );

  setUp(() {
    mockRepo = MockIMenuItemRepository();
    sut = CreateMenuItemUseCase(repository: mockRepo);
  });

  group('CreateMenuItemUseCase', () {
    test('정상 생성 시 MenuItem을 반환한다', () async {
      when(
        mockRepo.create(
          name: anyNamed('name'),
          price: anyNamed('price'),
          category: anyNamed('category'),
        ),
      ).thenAnswer((_) async => item);

      final result = await sut.execute(
        name: '아메리카노',
        price: 4500,
        category: '음료',
      );

      expect(result.name, '아메리카노');
      expect(result.price, 4500);
      expect(result.isAvailable, isTrue);
    });

    test('repository.create를 name/price/category와 함께 호출한다', () async {
      when(
        mockRepo.create(
          name: anyNamed('name'),
          price: anyNamed('price'),
          category: anyNamed('category'),
        ),
      ).thenAnswer((_) async => item);

      await sut.execute(name: '아메리카노', price: 4500, category: '음료');

      verify(
        mockRepo.create(
          name: '아메리카노',
          price: 4500,
          category: '음료',
        ),
      ).called(1);
    });
  });
}
