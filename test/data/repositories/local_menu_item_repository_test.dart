import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/data/local/daos/menu_item_dao.dart';
import 'package:pos/data/local/database/app_database.dart';
import 'package:pos/data/local/repositories/local_menu_item_repository.dart';
import 'package:pos/domain/exceptions/domain_exceptions.dart';

void main() {
  late AppDatabase db;
  late LocalMenuItemRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = LocalMenuItemRepository(MenuItemDao(db));
  });

  tearDown(() async => db.close());

  group('LocalMenuItemRepository', () {
    test('create — 메뉴를 생성한다', () async {
      final item = await repository.create(
        name: '김치찌개',
        price: 8000,
        category: '찌개',
      );

      expect(item.name, '김치찌개');
      expect(item.price, 8000);
      expect(item.isAvailable, isTrue);
    });

    test('findAll — 전체 메뉴를 반환한다', () async {
      await repository.create(name: '김치찌개', price: 8000, category: '찌개');
      await repository.create(name: '된장찌개', price: 7000, category: '찌개');

      final items = await repository.findAll();

      expect(items.length, 2);
    });

    test('findAll — onlyAvailable=true이면 판매 가능 메뉴만 반환한다', () async {
      final item = await repository.create(
        name: '김치찌개',
        price: 8000,
        category: '찌개',
      );
      await repository.update(item.id, isAvailable: false);
      await repository.create(name: '된장찌개', price: 7000, category: '찌개');

      final items = await repository.findAll(onlyAvailable: true);

      expect(items.length, 1);
      expect(items.first.name, '된장찌개');
    });

    test('findById — 메뉴를 반환한다', () async {
      final item = await repository.create(
        name: '김치찌개',
        price: 8000,
        category: '찌개',
      );

      final found = await repository.findById(item.id);

      expect(found?.id, item.id);
    });

    test('findById — 없으면 null을 반환한다', () async {
      final result = await repository.findById('nonexistent');

      expect(result, isNull);
    });

    test('update — 메뉴 정보를 수정한다', () async {
      final item = await repository.create(
        name: '김치찌개',
        price: 8000,
        category: '찌개',
      );

      final updated = await repository.update(item.id, price: 9000);

      expect(updated.price, 9000);
    });

    test('update — 존재하지 않으면 MenuItemNotFoundException이 발생한다', () async {
      await expectLater(
        repository.update('nonexistent', name: '테스트'),
        throwsA(isA<MenuItemNotFoundException>()),
      );
    });

    test('delete — 메뉴를 soft delete한다 (isAvailable=false)', () async {
      final item = await repository.create(
        name: '김치찌개',
        price: 8000,
        category: '찌개',
      );
      await repository.delete(item.id);

      final found = await repository.findById(item.id);

      expect(found?.isAvailable, isFalse);
    });

    test('watchAll — 메뉴 스트림을 반환한다', () async {
      await repository.create(name: '김치찌개', price: 8000, category: '찌개');

      final stream = repository.watchAll();
      final items = await stream.first;

      expect(items.length, 1);
    });
  });
}
