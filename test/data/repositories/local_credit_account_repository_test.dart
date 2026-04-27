import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/data/local/daos/business_day_dao.dart';
import 'package:pos/data/local/daos/credit_account_dao.dart';
import 'package:pos/data/local/daos/order_dao.dart';
import 'package:pos/data/local/database/app_database.dart';
import 'package:pos/data/local/repositories/local_credit_account_repository.dart';

void main() {
  late AppDatabase db;
  late LocalCreditAccountRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = LocalCreditAccountRepository(CreditAccountDao(db));
  });

  tearDown(() async => db.close());

  group('LocalCreditAccountRepository', () {
    test('create — 외상 계좌를 생성한다', () async {
      final account = await repository.create('홍길동');

      expect(account.customerName, '홍길동');
      expect(account.balance, 0);
    });

    test('findAll — 전체 계좌를 반환한다', () async {
      await repository.create('홍길동');
      await repository.create('김철수');

      final accounts = await repository.findAll();

      expect(accounts.length, 2);
    });

    test('findAll hasBalance=true — 잔액 있는 계좌만 반환한다', () async {
      final account = await repository.create('홍길동');
      await repository.create('김철수');

      final businessDayDao = BusinessDayDao(db);
      final orderDao = OrderDao(db);
      final creditAccountDao = CreditAccountDao(db);

      final businessDay = await businessDayDao.open();
      await db.into(db.seats).insert(
            SeatsCompanion.insert(
              id: 'seat-1',
              seatNumber: 'A1',
              capacity: 4,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
      final order = await orderDao.create(
        businessDayId: businessDay.id,
        seatId: 'seat-1',
        items: const [],
      );

      await creditAccountDao.charge(
        accountId: account.id,
        orderId: order.id,
        amount: 10000,
      );

      final accounts = await repository.findAll(hasBalance: true);

      expect(accounts.length, 1);
      expect(accounts.first.customerName, '홍길동');
    });

    test('findById — 계좌를 반환한다', () async {
      final account = await repository.create('홍길동');

      final found = await repository.findById(account.id);

      expect(found?.id, account.id);
    });

    test('findById — 없으면 null을 반환한다', () async {
      final result = await repository.findById('nonexistent');

      expect(result, isNull);
    });

    test('updateName — 고객명을 수정한다', () async {
      final account = await repository.create('홍길동');

      final updated = await repository.updateName(account.id, '홍길순');

      expect(updated.customerName, '홍길순');
    });

    test('delete — 계좌를 삭제한다', () async {
      final account = await repository.create('홍길동');
      await repository.delete(account.id);

      final found = await repository.findById(account.id);

      expect(found, isNull);
    });

    test('getTransactions — 거래 내역을 반환한다', () async {
      final account = await repository.create('홍길동');

      final txList = await repository.getTransactions(account.id);

      expect(txList, isEmpty);
    });

    test('watchAll — 계좌 스트림을 반환한다', () async {
      await repository.create('홍길동');

      final stream = repository.watchAll();
      final accounts = await stream.first;

      expect(accounts.length, 1);
    });
  });
}
