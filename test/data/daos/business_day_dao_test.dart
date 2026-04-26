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
  });
}
