class OrderItem {
  const OrderItem({
    required this.id,
    required this.orderId,
    required this.menuItemId,
    required this.menuName,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String orderId;
  final String menuItemId;

  /// 주문 시점 메뉴명 스냅샷 — MenuItem 변경에 영향받지 않음
  final String menuName;

  /// 주문 시점 단가 스냅샷 (KRW)
  final int unitPrice;

  final int quantity;

  /// unitPrice × quantity, UseCase에서 보장
  final int subtotal;

  final DateTime createdAt;
  final DateTime updatedAt;

  OrderItem copyWith({
    String? id,
    String? orderId,
    String? menuItemId,
    String? menuName,
    int? unitPrice,
    int? quantity,
    int? subtotal,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => OrderItem(
    id: id ?? this.id,
    orderId: orderId ?? this.orderId,
    menuItemId: menuItemId ?? this.menuItemId,
    menuName: menuName ?? this.menuName,
    unitPrice: unitPrice ?? this.unitPrice,
    quantity: quantity ?? this.quantity,
    subtotal: subtotal ?? this.subtotal,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is OrderItem && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
