import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/data/local/daos/credit_account_dao.dart';
import 'package:pos/data/local/database/app_database.dart';

void main() {
  late AppDatabase db;
  late CreditAccountDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = CreditAccountDao(db);
  });

  tearDown(() async => db.close());

  Future<void> insertAccount({
    required String id,
    required String name,
    required int balance,
  }) async {
    final now = DateTime.now();
    await db.into(db.creditAccounts).insert(
      CreditAccountsCompanion.insert(
        id: id,
        customerName: name,
        balance: Value(balance),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  group('CreditAccountDao', () {
    group('findAll', () {
      setUp(() async {
        await insertAccount(id: 'a1', name: '홍길동', balance: 10000);
        await insertAccount(id: 'a2', name: '이순신', balance: 0);
        await insertAccount(id: 'a3', name: '강감찬', balance: 5000);
      });

      test('hasBalance=null이면 전체 계좌를 잔액 내림차순으로 반환한다', () async {
        final result = await dao.findAll();

        expect(result.length, 3);
        expect(result[0].balance, 10000);
        expect(result[1].balance, 5000);
        expect(result[2].balance, 0);
      });

      test('hasBalance=true이면 잔액이 있는 계좌만 반환한다', () async {
        final result = await dao.findAll(hasBalance: true);

        expect(result.length, 2);
        expect(result.every((a) => a.balance > 0), isTrue);
      });

      test('hasBalance=false이면 잔액이 0인 계좌만 반환한다', () async {
        final result = await dao.findAll(hasBalance: false);

        expect(result.length, 1);
        expect(result.first.balance, 0);
        expect(result.first.customerName, '이순신');
      });
    });

    group('findById', () {
      test('존재하는 ID이면 계좌를 반환한다', () async {
        await insertAccount(id: 'a1', name: '홍길동', balance: 3000);

        final result = await dao.findById('a1');

        expect(result, isNotNull);
        expect(result!.id, 'a1');
        expect(result.customerName, '홍길동');
        expect(result.balance, 3000);
      });

      test('존재하지 않는 ID이면 null을 반환한다', () async {
        final result = await dao.findById('nonexistent');

        expect(result, isNull);
      });
    });
  });
}
