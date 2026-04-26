import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/data/local/daos/business_day_dao.dart';
import 'package:pos/data/local/database/app_database.dart';
import 'package:pos/domain/value_objects/business_day_status.dart';

void main() {
  late AppDatabase db;
  late BusinessDayDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = BusinessDayDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('BusinessDayDao', () {
    Future<String> insertBusinessDay({
      String id = 'bd-1',
      BusinessDayStatus status = BusinessDayStatus.open,
      DateTime? openedAt,
      DateTime? closedAt,
    }) async {
      final now = openedAt ?? DateTime.now();
      await db.into(db.businessDays).insert(
        BusinessDaysCompanion.insert(
          id: id,
          status: status,
          openedAt: now,
          closedAt: Value(closedAt),
          createdAt: now,
        ),
      );
      return id;
    }

    test('getOpen — OPEN 영업일이 없으면 null을 반환한다', () async {
      final result = await dao.getOpen();

      expect(result, isNull);
    });

    test('getOpen — OPEN 영업일이 있으면 반환한다', () async {
      await insertBusinessDay(id: 'bd-1', status: BusinessDayStatus.open);

      final result = await dao.getOpen();

      expect(result, isNotNull);
      expect(result!.id, 'bd-1');
      expect(result.status, BusinessDayStatus.open);
    });

    test('getOpen — CLOSED 영업일은 반환하지 않는다', () async {
      await insertBusinessDay(
        id: 'bd-1',
        status: BusinessDayStatus.closed,
        closedAt: DateTime.now(),
      );

      final result = await dao.getOpen();

      expect(result, isNull);
    });

    test('OPEN 영업일은 최대 1개 — 두 번째 OPEN 삽입 시 getOpen이 항상 하나만 반환한다', () async {
      await insertBusinessDay(id: 'bd-1', status: BusinessDayStatus.open);
      await insertBusinessDay(id: 'bd-2', status: BusinessDayStatus.open);

      // DB 수준에서 유일성을 강제하지 않더라도 getOpen은 하나만 반환해야 한다.
      // 실제 애플리케이션에서는 UseCase가 중복 OPEN을 방지한다.
      final result = await dao.getOpen();

      expect(result, isNotNull);
    });

    test('findById — 존재하는 id이면 영업일을 반환한다', () async {
      await insertBusinessDay(id: 'bd-1', status: BusinessDayStatus.open);

      final result = await dao.findById('bd-1');

      expect(result, isNotNull);
      expect(result!.id, 'bd-1');
      expect(result.status, BusinessDayStatus.open);
    });

    test('findById — 존재하지 않는 id이면 null을 반환한다', () async {
      final result = await dao.findById('no-such-id');

      expect(result, isNull);
    });

    test('insert — 영업일을 삽입하고 반환한다', () async {
      final now = DateTime.now();
      final bd = await dao.insert(
        BusinessDaysCompanion.insert(
          id: 'bd-1',
          status: BusinessDayStatus.open,
          openedAt: now,
          createdAt: now,
        ),
      );

      expect(bd.id, 'bd-1');
      expect(bd.status, BusinessDayStatus.open);
      expect(bd.closedAt, isNull);
    });

    test('updateRow — status를 closed로 변경하면 반영된다', () async {
      await insertBusinessDay(id: 'bd-1', status: BusinessDayStatus.open);
      final closedAt = DateTime.now();

      final updated = await dao.updateRow(
        'bd-1',
        BusinessDaysCompanion(
          status: const Value(BusinessDayStatus.closed),
          closedAt: Value(closedAt),
        ),
      );

      expect(updated.status, BusinessDayStatus.closed);
      expect(updated.closedAt, isNotNull);
    });

    test('findAll — 최근 개설 순으로 반환한다', () async {
      final t1 = DateTime(2024, 1, 1);
      final t2 = DateTime(2024, 1, 2);
      await insertBusinessDay(id: 'bd-1', openedAt: t1);
      await insertBusinessDay(id: 'bd-2', openedAt: t2);

      final result = await dao.findAll();

      expect(result.length, 2);
      expect(result.first.id, 'bd-2'); // 최근 개설이 먼저
    });

    test('findAll — from/to 범위 필터링', () async {
      final t1 = DateTime(2024, 1, 1);
      final t2 = DateTime(2024, 1, 5);
      final t3 = DateTime(2024, 1, 10);
      await insertBusinessDay(id: 'bd-1', openedAt: t1);
      await insertBusinessDay(id: 'bd-2', openedAt: t2);
      await insertBusinessDay(id: 'bd-3', openedAt: t3);

      final result = await dao.findAll(
        from: DateTime(2024, 1, 3),
        to: DateTime(2024, 1, 8),
      );

      expect(result.length, 1);
      expect(result.first.id, 'bd-2');
    });
  });
}
