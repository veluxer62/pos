import 'package:drift/drift.dart';
import 'package:pos/data/local/database/app_database.dart';
import 'package:pos/data/local/database/tables.dart';
import 'package:pos/domain/entities/credit_transaction.dart';
import 'package:pos/domain/value_objects/credit_transaction_type.dart';

part 'credit_transaction_dao.g.dart';

@DriftAccessor(tables: [CreditTransactions])
class CreditTransactionDao extends DatabaseAccessor<AppDatabase>
    with _$CreditTransactionDaoMixin {
  CreditTransactionDao(super.db);

  Future<List<CreditTransaction>> findByAccount(
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
    return rows.map(_toEntity).toList();
  }

  CreditTransaction _toEntity(CreditTransactionRow row) => CreditTransaction(
        id: row.id,
        creditAccountId: row.creditAccountId,
        type: row.type,
        amount: row.amount,
        orderId: row.orderId,
        note: row.note,
        createdAt: row.createdAt,
      );
}
