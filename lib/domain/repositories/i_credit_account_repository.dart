import 'package:pos/domain/entities/credit_account.dart';
import 'package:pos/domain/entities/credit_transaction.dart';
import 'package:pos/domain/value_objects/credit_transaction_type.dart';
import 'package:pos/domain/value_objects/payment_result.dart';

export 'package:pos/domain/value_objects/payment_result.dart';

abstract interface class ICreditAccountRepository {
  /// hasBalance=true: 잔액 있는 계좌만 / false: 완납 계좌만 / null: 전체.
  Future<List<CreditAccount>> findAll({bool? hasBalance});
  Future<CreditAccount?> findById(String id);
  Future<CreditAccount> create(String customerName);
  Future<CreditAccount> updateName(String id, String customerName);

  /// balance > 0이면 [CreditAccountHasBalanceException].
  Future<void> delete(String id);

  /// balance += amount, CreditTransaction(charge) 생성.
  /// Order와 CreditAccount 업데이트는 동일 트랜잭션 내 원자적 수행.
  Future<CreditTransaction> charge({
    required String accountId,
    required String orderId,
    required int amount,
  });

  /// balance = max(0, balance - amount). 초과 납부 시 잔액 0.
  Future<PaymentResult> pay({
    required String accountId,
    required int amount,
    String? note,
  });
  Future<List<CreditTransaction>> getTransactions(
    String accountId, {
    CreditTransactionType? type,
    int limit = 50,
    int offset = 0,
  });
  Stream<List<CreditAccount>> watchAll();
}
