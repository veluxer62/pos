class CreditAccount {
  const CreditAccount({
    required this.id,
    required this.customerName,
    required this.balance,
    required this.createdAt,
    required this.updatedAt,
    this.phone,
    this.note,
  });

  final String id;
  final String customerName;

  /// 미납 잔액 (KRW, ≥ 0). CreditTransactions 합산과 일치
  final int balance;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// 연락처 (선택)
  final String? phone;

  /// 메모 (선택)
  final String? note;

  CreditAccount copyWith({
    String? id,
    String? customerName,
    int? balance,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? phone,
    String? note,
  }) =>
      CreditAccount(
        id: id ?? this.id,
        customerName: customerName ?? this.customerName,
        balance: balance ?? this.balance,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        phone: phone ?? this.phone,
        note: note ?? this.note,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CreditAccount && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
