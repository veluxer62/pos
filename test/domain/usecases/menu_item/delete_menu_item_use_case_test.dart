import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pos/domain/exceptions/domain_exceptions.dart';
import 'package:pos/domain/repositories/i_menu_item_repository.dart';
import 'package:pos/domain/usecases/menu_item/delete_menu_item_use_case.dart';

import 'delete_menu_item_use_case_test.mocks.dart';

@GenerateMocks([IMenuItemRepository])
void main() {
  late MockIMenuItemRepository mockRepo;
  late DeleteMenuItemUseCase sut;

  setUp(() {
    mockRepo = MockIMenuItemRepository();
    sut = DeleteMenuItemUseCase(repository: mockRepo);
  });

  group('DeleteMenuItemUseCase', () {
    test('활성 주문이 없으면 repository.delete를 호출한다', () async {
      when(mockRepo.delete(any)).thenAnswer((_) async {});

      await sut.execute('item-1');

      verify(mockRepo.delete('item-1')).called(1);
    });

    test('활성 주문 참조 중이면 MenuItemInUseException을 전파한다', () async {
      when(mockRepo.delete(any)).thenThrow(const MenuItemInUseException());

      await expectLater(
        sut.execute('item-1'),
        throwsA(isA<MenuItemInUseException>()),
      );
    });
  });
}
