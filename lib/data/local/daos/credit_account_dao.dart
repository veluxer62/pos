import 'package:drift/drift.dart';
import 'package:pos/data/local/database/app_database.dart';
import 'package:pos/data/local/database/tables.dart';
import 'package:pos/domain/entities/credit_account.dart';

part 'credit_account_dao.g.dart';

@DriftAccessor(tables: [CreditAccounts])
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
    final row = await (select(creditAccounts)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toEntity(row);
  }

  CreditAccount _toEntity(CreditAccountRow row) => CreditAccount(
        id: row.id,
        customerName: row.customerName,
        balance: row.balance,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );
}
