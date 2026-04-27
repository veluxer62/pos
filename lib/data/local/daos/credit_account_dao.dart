import 'package:drift/drift.dart';
import 'package:pos/data/local/database/app_database.dart';
import 'package:pos/data/local/database/tables.dart';
import 'package:pos/domain/entities/credit_account.dart';
import 'package:pos/domain/entities/credit_transaction.dart';
import 'package:pos/domain/exceptions/domain_exceptions.dart';
import 'package:pos/domain/value_objects/credit_transaction_type.dart';
import 'package:pos/domain/value_objects/payment_result.dart';
import 'package:uuid/uuid.dart';

part 'credit_account_dao.g.dart';

@DriftAccessor(tables: [CreditAccounts, CreditTransactions])
class CreditAccountDao extends DatabaseAccessor<AppDatabase>
    with _$CreditAccountDaoMixin {
  CreditAccountDao(super.db);

  Future<List<CreditAccount>> findAll({bool? hasBalance}) async {
    final query = select(creditAccounts)
      ..orderBy([(t) => OrderingTerm.desc(t.balance)]);
    if (hasBalance != null) {
      if (hasBalance) {
        query.where((t) => t.balance.isBiggerThanValue(0));
      } else {
        query.where((t) => t.balance.equals(0));
      }
    }
    final rows = await query.get();
    return rows.map(_toEntity).toList();
  }

  Future<CreditAccount?> findById(String id) async {
    final row = await (select(creditAccounts)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toEntity(row);
  }

  Future<CreditAccount> create(String customerName) async {
    final id = const Uuid().v4();
    final now = DateTime.now();
    await into(creditAccounts).insert(
      CreditAccountsCompanion.insert(
        id: id,
        customerName: customerName,
        createdAt: now,
        updatedAt: now,
      ),
    );
    return (await findById(id))!;
  }

  Future<CreditAccount> updateName(String id, String customerName) async {
    final row = await (select(creditAccounts)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) throw CreditAccountNotFoundException(id);

    final now = DateTime.now();
    await (update(creditAccounts)..where((t) => t.id.equals(id))).write(
      CreditAccountsCompanion(
        customerName: Value(customerName),
        updatedAt: Value(now),
      ),
    );
    return (await findById(id))!;
  }

  Future<void> deleteAccount(String id) async {
    final row = await (select(creditAccounts)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) throw CreditAccountNotFoundException(id);
    if (row.balance > 0) {
      throw CreditAccountHasBalanceException(balance: row.balance);
    }
    await (delete(creditAccounts)..where((t) => t.id.equals(id))).go();
  }

  /// balance += amount, CreditTransaction(charge) 생성 — 원자적 트랜잭션.
  Future<CreditTransaction> charge({
    required String accountId,
    required String orderId,
    required int amount,
  }) =>
      db.transaction(() async {
        final row = await (select(creditAccounts)
              ..where((t) => t.id.equals(accountId)))
            .getSingleOrNull();
        if (row == null) throw CreditAccountNotFoundException(accountId);

        final now = DateTime.now();
        final newBalance = row.balance + amount;

        await (update(creditAccounts)..where((t) => t.id.equals(accountId)))
            .write(
          CreditAccountsCompanion(
            balance: Value(newBalance),
            updatedAt: Value(now),
          ),
        );

        final txId = const Uuid().v4();
        await into(creditTransactions).insert(
          CreditTransactionsCompanion.insert(
            id: txId,
            creditAccountId: accountId,
            type: CreditTransactionType.charge,
            amount: amount,
            orderId: Value(orderId),
            createdAt: now,
          ),
        );

        return _toTransaction(
          await (select(creditTransactions)..where((t) => t.id.equals(txId)))
              .getSingle(),
        );
      });

  /// balance = max(0, balance - amount). 초과 납부 시 잔액 0 — 원자적 트랜잭션.
  Future<PaymentResult> pay({
    required String accountId,
    required int amount,
    String? note,
  }) =>
      db.transaction(() async {
        final row = await (select(creditAccounts)
              ..where((t) => t.id.equals(accountId)))
            .getSingleOrNull();
        if (row == null) throw CreditAccountNotFoundException(accountId);

        final previousBalance = row.balance;
        final appliedAmount =
            amount > previousBalance ? previousBalance : amount;
        final overpaid =
            amount > previousBalance ? amount - previousBalance : 0;
        final newBalance = previousBalance - appliedAmount;
        final now = DateTime.now();

        await (update(creditAccounts)..where((t) => t.id.equals(accountId)))
            .write(
          CreditAccountsCompanion(
            balance: Value(newBalance),
            updatedAt: Value(now),
          ),
        );

        final txId = const Uuid().v4();
        await into(creditTransactions).insert(
          CreditTransactionsCompanion.insert(
            id: txId,
            creditAccountId: accountId,
            type: CreditTransactionType.payment,
            amount: appliedAmount,
            note: Value(note),
            createdAt: now,
          ),
        );

        final tx = _toTransaction(
          await (select(creditTransactions)..where((t) => t.id.equals(txId)))
              .getSingle(),
        );

        return PaymentResult(
          transaction: tx,
          previousBalance: previousBalance,
          appliedAmount: appliedAmount,
          newBalance: newBalance,
          overpaidAmount: overpaid > 0 ? overpaid : null,
        );
      });

  Future<List<CreditTransaction>> getTransactions(
    String accountId, {
    CreditTransactionType? type,
    int limit = 50,
    int offset = 0,
  }) async {
    final query = select(creditTransactions)
      ..where((t) => t.creditAccountId.equals(accountId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(limit, offset: offset);
    if (type != null) {
      query.where((t) => t.type.equals(type.name));
    }
    final rows = await query.get();
    return rows.map(_toTransaction).toList();
  }

  Stream<List<CreditAccount>> watchAll() =>
      (select(creditAccounts)..orderBy([(t) => OrderingTerm.desc(t.balance)]))
          .watch()
          .map((rows) => rows.map(_toEntity).toList());

  CreditAccount _toEntity(CreditAccountRow row) => CreditAccount(
        id: row.id,
        customerName: row.customerName,
        balance: row.balance,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  CreditTransaction _toTransaction(CreditTransactionRow row) =>
      CreditTransaction(
        id: row.id,
        creditAccountId: row.creditAccountId,
        type: row.type,
        amount: row.amount,
        orderId: row.orderId,
        note: row.note,
        createdAt: row.createdAt,
      );
}
