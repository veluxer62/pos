import 'package:pos/data/local/daos/credit_account_dao.dart';
import 'package:pos/domain/entities/credit_account.dart';
import 'package:pos/domain/entities/credit_transaction.dart';
import 'package:pos/domain/repositories/i_credit_account_repository.dart';
import 'package:pos/domain/value_objects/credit_transaction_type.dart';

class LocalCreditAccountRepository implements ICreditAccountRepository {
  LocalCreditAccountRepository(this._dao);

  final CreditAccountDao _dao;

  @override
  Future<List<CreditAccount>> findAll({bool? hasBalance}) =>
      _dao.findAll(hasBalance: hasBalance);

  @override
  Future<CreditAccount?> findById(String id) => _dao.findById(id);

  @override
  Future<CreditAccount> create(String customerName) =>
      _dao.create(customerName);

  @override
  Future<CreditAccount> updateName(String id, String customerName) =>
      _dao.updateName(id, customerName);

  @override
  Future<void> delete(String id) => _dao.deleteAccount(id);

  @override
  Future<CreditTransaction> charge({
    required String accountId,
    required String orderId,
    required int amount,
  }) => _dao.charge(accountId: accountId, orderId: orderId, amount: amount);

  @override
  Future<PaymentResult> pay({
    required String accountId,
    required int amount,
    String? note,
  }) => _dao.pay(accountId: accountId, amount: amount, note: note);

  @override
  Future<List<CreditTransaction>> getTransactions(
    String accountId, {
    CreditTransactionType? type,
    int limit = 50,
    int offset = 0,
  }) => _dao.getTransactions(
        accountId,
        type: type,
        limit: limit,
        offset: offset,
      );

  @override
  Stream<List<CreditAccount>> watchAll() => _dao.watchAll();
}
