import 'package:pos/domain/entities/credit_transaction.dart';

class PaymentResult {
  const PaymentResult({
    required this.transaction,
    required this.previousBalance,
    required this.appliedAmount,
    required this.newBalance,
    this.overpaidAmount,
  });

  final CreditTransaction transaction;
  final int previousBalance;
  final int appliedAmount;
  final int newBalance;

  /// 초과 납부 시만 non-null.
  final int? overpaidAmount;
}
