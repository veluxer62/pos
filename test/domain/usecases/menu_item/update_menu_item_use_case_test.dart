import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pos/domain/entities/menu_item.dart';
import 'package:pos/domain/exceptions/domain_exceptions.dart';
import 'package:pos/domain/repositories/i_menu_item_repository.dart';
import 'package:pos/domain/usecases/menu_item/update_menu_item_use_case.dart';

import 'update_menu_item_use_case_test.mocks.dart';

@GenerateMocks([IMenuItemRepository])
void main() {
  late MockIMenuItemRepository mockRepo;
  late UpdateMenuItemUseCase sut;

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
    sut = UpdateMenuItemUseCase(repository: mockRepo);
  });

  group('UpdateMenuItemUseCase', () {
    test('정상 수정 시 업데이트된 MenuItem을 반환한다', () async {
      final updated = item.copyWith(name: '라떼', price: 5000);
      when(
        mockRepo.update(
          any,
          name: anyNamed('name'),
          price: anyNamed('price'),
          category: anyNamed('category'),
          isAvailable: anyNamed('isAvailable'),
        ),
      ).thenAnswer((_) async => updated);

      final result = await sut.execute('item-1', name: '라떼', price: 5000);

      expect(result.name, '라떼');
      expect(result.price, 5000);
    });

    test('존재하지 않는 ID 수정 시 MenuItemNotFoundException을 전파한다', () async {
      when(
        mockRepo.update(
          any,
          name: anyNamed('name'),
          price: anyNamed('price'),
          category: anyNamed('category'),
          isAvailable: anyNamed('isAvailable'),
        ),
      ).thenThrow(const MenuItemNotFoundException('item-999'));

      await expectLater(
        sut.execute('item-999', name: '라떼'),
        throwsA(isA<MenuItemNotFoundException>()),
      );
    });

    test('isAvailable=false로 수정하면 판매 불가 상태가 된다', () async {
      final updated = item.copyWith(isAvailable: false);
      when(
        mockRepo.update(
          any,
          name: anyNamed('name'),
          price: anyNamed('price'),
          category: anyNamed('category'),
          isAvailable: anyNamed('isAvailable'),
        ),
      ).thenAnswer((_) async => updated);

      final result = await sut.execute('item-1', isAvailable: false);

      expect(result.isAvailable, isFalse);
    });
  });
}
