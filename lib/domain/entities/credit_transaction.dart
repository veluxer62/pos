import 'package:pos/domain/value_objects/credit_transaction_type.dart';

// nullable 필드를 copyWith에서 null로 되돌릴 수 있도록 sentinel 사용
const _absent = Object();

class CreditTransaction {
  const CreditTransaction({
    required this.id,
    required this.creditAccountId,
    required this.type,
    required this.amount,
    required this.createdAt,
    this.orderId,
    this.note,
  });

  final String id;
  final String creditAccountId;
  final CreditTransactionType type;

  /// 거래 금액 (KRW, 양수)
  final int amount;

  /// charge 시 연결된 주문 ID
  final String? orderId;

  final String? note;
  final DateTime createdAt;

  CreditTransaction copyWith({
    String? id,
    String? creditAccountId,
    CreditTransactionType? type,
    int? amount,
    DateTime? createdAt,
    Object? orderId = _absent,
    Object? note = _absent,
  }) => CreditTransaction(
    id: id ?? this.id,
    creditAccountId: creditAccountId ?? this.creditAccountId,
    type: type ?? this.type,
    amount: amount ?? this.amount,
    createdAt: createdAt ?? this.createdAt,
    orderId: identical(orderId, _absent) ? this.orderId : orderId as String?,
    note: identical(note, _absent) ? this.note : note as String?,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CreditTransaction && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
