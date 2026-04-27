class CreditAccount {
  const CreditAccount({
    required this.id,
    required this.customerName,
    required this.balance,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String customerName;

  /// 미납 잔액 (KRW, ≥ 0). CreditTransactions 합산과 일치
  final int balance;

  final DateTime createdAt;
  final DateTime updatedAt;

  CreditAccount copyWith({
    String? id,
    String? customerName,
    int? balance,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      CreditAccount(
        id: id ?? this.id,
        customerName: customerName ?? this.customerName,
        balance: balance ?? this.balance,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CreditAccount && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
