import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/data/local/daos/credit_account_dao.dart';
import 'package:pos/data/local/database/app_database.dart';
import 'package:pos/domain/exceptions/domain_exceptions.dart';
import 'package:pos/domain/value_objects/business_day_status.dart';
import 'package:pos/domain/value_objects/credit_transaction_type.dart';
import 'package:pos/domain/value_objects/order_status.dart';

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

  Future<void> insertOrder(String orderId) async {
    final now = DateTime.now();
    await db.into(db.businessDays).insert(
      BusinessDaysCompanion.insert(
        id: 'bd-1',
        status: BusinessDayStatus.open,
        openedAt: now,
        createdAt: now,
      ),
    );
    await db.into(db.seats).insert(
      SeatsCompanion.insert(
        id: 'seat-1',
        seatNumber: '1',
        capacity: 4,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await db.into(db.orders).insert(
      OrdersCompanion.insert(
        id: orderId,
        businessDayId: 'bd-1',
        seatId: 'seat-1',
        status: const OrderStatusDelivered(),
        totalAmount: 10000,
        orderedAt: now,
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

    group('create', () {
      test('계좌를 생성하고 반환한다', () async {
        final account = await dao.create('신규고객');

        expect(account.customerName, '신규고객');
        expect(account.balance, 0);
        expect(account.id, isNotEmpty);
      });
    });

    group('charge', () {
      setUp(() async {
        await insertAccount(id: 'a1', name: '홍길동', balance: 0);
        await insertOrder('order-1');
      });

      test('charge 후 balance가 증가하고 CreditTransaction이 생성된다', () async {
        final tx = await dao.charge(
          accountId: 'a1',
          orderId: 'order-1',
          amount: 5000,
        );

        final account = await dao.findById('a1');
        expect(account!.balance, 5000);
        expect(tx.type, CreditTransactionType.charge);
        expect(tx.amount, 5000);
        expect(tx.orderId, 'order-1');
      });

      test('charge는 원자적으로 처리된다 — balance와 transaction이 함께 변경된다', () async {
        await dao.charge(accountId: 'a1', orderId: 'order-1', amount: 3000);

        final account = await dao.findById('a1');
        final transactions = await dao.getTransactions('a1');

        expect(account!.balance, 3000);
        expect(transactions.length, 1);
        expect(transactions.first.amount, 3000);
      });
    });

    group('pay', () {
      setUp(() async {
        await insertAccount(id: 'a1', name: '홍길동', balance: 10000);
      });

      test('정상 납부 시 balance가 감소하고 PaymentResult를 반환한다', () async {
        final result = await dao.pay(accountId: 'a1', amount: 4000);

        final account = await dao.findById('a1');
        expect(account!.balance, 6000);
        expect(result.previousBalance, 10000);
        expect(result.appliedAmount, 4000);
        expect(result.newBalance, 6000);
        expect(result.overpaidAmount, isNull);
      });

      test('과납 시 잔액이 0이 되고 overpaidAmount가 설정된다', () async {
        final result = await dao.pay(accountId: 'a1', amount: 15000);

        final account = await dao.findById('a1');
        expect(account!.balance, 0);
        expect(result.newBalance, 0);
        expect(result.overpaidAmount, 5000);
        expect(result.appliedAmount, 10000);
      });

      test('pay 후 CreditTransaction(payment)이 생성된다', () async {
        await dao.pay(accountId: 'a1', amount: 4000);

        final transactions = await dao.getTransactions('a1');
        expect(transactions.length, 1);
        expect(transactions.first.type, CreditTransactionType.payment);
        expect(transactions.first.amount, 4000);
      });
    });

    group('deleteAccount', () {
      test('잔액이 0인 계좌는 삭제할 수 있다', () async {
        await insertAccount(id: 'a1', name: '홍길동', balance: 0);

        await dao.deleteAccount('a1');

        expect(await dao.findById('a1'), isNull);
      });

      test('잔액이 있는 계좌 삭제 시 CreditAccountHasBalanceException 발생', () async {
        await insertAccount(id: 'a1', name: '홍길동', balance: 5000);

        await expectLater(
          dao.deleteAccount('a1'),
          throwsA(isA<CreditAccountHasBalanceException>()),
        );
      });
    });

    group('getTransactions', () {
      setUp(() async {
        await insertAccount(id: 'a1', name: '홍길동', balance: 0);
        await insertOrder('order-1');
      });

      test('type 필터로 charge만 조회할 수 있다', () async {
        await dao.charge(accountId: 'a1', orderId: 'order-1', amount: 5000);
        await dao.pay(accountId: 'a1', amount: 2000);

        final charges =
            await dao.getTransactions('a1', type: CreditTransactionType.charge);
        final payments = await dao.getTransactions(
          'a1',
          type: CreditTransactionType.payment,
        );

        expect(charges.length, 1);
        expect(payments.length, 1);
      });

      test('limit/offset으로 페이징 처리가 된다', () async {
        await dao.charge(accountId: 'a1', orderId: 'order-1', amount: 1000);
        await dao.pay(accountId: 'a1', amount: 500);

        final first = await dao.getTransactions('a1', limit: 1, offset: 0);
        final second = await dao.getTransactions('a1', limit: 1, offset: 1);

        expect(first.length, 1);
        expect(second.length, 1);
        expect(first.first.id, isNot(second.first.id));
      });
    });
  });
}
