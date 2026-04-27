import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/data/local/daos/menu_item_dao.dart';
import 'package:pos/data/local/database/app_database.dart';

void main() {
  late AppDatabase db;
  late MenuItemDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = MenuItemDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('MenuItemDao', () {
    Future<String> insertMenu({
      String id = 'menu-1',
      String name = '아메리카노',
      int price = 4500,
      String category = '음료',
      bool isAvailable = true,
    }) async {
      final now = DateTime.now();
      await db.into(db.menuItems).insert(
            MenuItemsCompanion.insert(
              id: id,
              name: name,
              price: price,
              category: category,
              isAvailable: Value(isAvailable),
              createdAt: now,
              updatedAt: now,
            ),
          );
      return id;
    }

    test('findAll — 전체 메뉴를 반환한다', () async {
      await insertMenu(id: 'menu-1', name: '아메리카노');
      await insertMenu(id: 'menu-2', name: '라떼');

      final result = await dao.findAll();

      expect(result.length, 2);
    });

    test('findAll(onlyAvailable: true) — 판매 가능 메뉴만 반환한다', () async {
      await insertMenu(id: 'menu-1', isAvailable: true);
      await insertMenu(id: 'menu-2', isAvailable: false);

      final result = await dao.findAll(onlyAvailable: true);

      expect(result.length, 1);
      expect(result.first.id, 'menu-1');
    });

    test('findAll(onlyAvailable: false) — 불가 메뉴 포함 전체 반환한다', () async {
      await insertMenu(id: 'menu-1', isAvailable: true);
      await insertMenu(id: 'menu-2', isAvailable: false);

      final result = await dao.findAll();

      expect(result.length, 2);
    });

    test('findById — 존재하는 id이면 메뉴를 반환한다', () async {
      await insertMenu(id: 'menu-1', name: '에스프레소', price: 3500);

      final result = await dao.findById('menu-1');

      expect(result, isNotNull);
      expect(result!.name, '에스프레소');
      expect(result.price, 3500);
    });

    test('findById — 존재하지 않는 id이면 null을 반환한다', () async {
      final result = await dao.findById('no-such-id');

      expect(result, isNull);
    });

    test('insert — 메뉴를 삽입하고 반환한다', () async {
      final now = DateTime.now();
      final menu = await dao.insert(
        MenuItemsCompanion.insert(
          id: 'menu-1',
          name: '에스프레소',
          price: 3500,
          category: '음료',
          createdAt: now,
          updatedAt: now,
        ),
      );

      expect(menu.id, 'menu-1');
      expect(menu.name, '에스프레소');
      expect(menu.price, 3500);
      expect(menu.isAvailable, isTrue);
    });

    test('updateRow — name을 수정하면 반영된다', () async {
      await insertMenu(id: 'menu-1', name: '아메리카노', price: 4500);

      final updated = await dao.updateRow(
        'menu-1',
        MenuItemsCompanion(
          name: const Value('콜드브루'),
          updatedAt: Value(DateTime.now()),
        ),
      );

      expect(updated.name, '콜드브루');
      expect(updated.price, 4500);
    });

    test('softDelete — isAvailable을 false로 변경한다', () async {
      await insertMenu(id: 'menu-1', isAvailable: true);

      await dao.softDelete('menu-1');

      final result = await dao.findById('menu-1');
      expect(result, isNotNull);
      expect(result!.isAvailable, isFalse);
    });

    test('softDelete — findAll(onlyAvailable: true)에서 제외된다', () async {
      await insertMenu(id: 'menu-1', isAvailable: true);
      await insertMenu(id: 'menu-2', isAvailable: true);

      await dao.softDelete('menu-1');

      final result = await dao.findAll(onlyAvailable: true);
      expect(result.length, 1);
      expect(result.first.id, 'menu-2');
    });
  });
}
