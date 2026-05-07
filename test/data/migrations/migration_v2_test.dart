import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/data/local/database/app_database.dart';

/// v1 → v2 마이그레이션 검증:
/// creditAccounts 테이블에 phone, note 컬럼 추가 후
/// 기존 데이터(phone=null, note=null)가 정상 조회되는지 확인.
void main() {
  group('Migration v1 → v2', () {
    test('phone/note 컬럼이 추가되고 기존 계좌가 null 값으로 조회된다', () async {
      // v1 스키마를 수동으로 생성하는 in-memory executor
      final executor = NativeDatabase.memory(
        setup: (db) {
          // v1 스키마 수동 생성 (phone, note 없음)
          db.execute('''
            CREATE TABLE IF NOT EXISTS credit_accounts (
              id TEXT NOT NULL PRIMARY KEY,
              customer_name TEXT NOT NULL CHECK(LENGTH(customer_name) >= 1 AND LENGTH(customer_name) <= 100),
              balance INTEGER NOT NULL DEFAULT 0,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL
            )
          ''');

          // drift의 schema_version pragma를 1로 설정
          db.execute('PRAGMA user_version = 1');

          // v1 기존 계좌 데이터 삽입
          final now = DateTime.now().millisecondsSinceEpoch;
          db.execute('''
            INSERT INTO credit_accounts (id, customer_name, balance, created_at, updated_at)
            VALUES ('acc-001', '홍길동', 5000, $now, $now)
          ''');
        },
      );

      // AppDatabase 열기 — schemaVersion=2이므로 onUpgrade(from=1, to=2) 실행됨
      final db = AppDatabase(executor);

      // 마이그레이션 후 계좌 조회
      final rows = await db.select(db.creditAccounts).get();
      expect(rows.length, 1);

      final row = rows.first;
      expect(row.id, 'acc-001');
      expect(row.customerName, '홍길동');
      expect(row.balance, 5000);
      // 마이그레이션으로 추가된 컬럼은 null
      expect(row.phone, isNull);
      expect(row.note, isNull);

      // 새 계좌 생성 시 phone/note 지정 가능
      final now = DateTime.now();
      await db.into(db.creditAccounts).insert(
            CreditAccountsCompanion.insert(
              id: 'acc-002',
              customerName: '김철수',
              phone: const Value('010-1234-5678'),
              note: const Value('단골 손님'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      final newRow = await (db.select(db.creditAccounts)
            ..where((t) => t.id.equals('acc-002')))
          .getSingle();
      expect(newRow.phone, '010-1234-5678');
      expect(newRow.note, '단골 손님');

      await db.close();
    });
  });
}
