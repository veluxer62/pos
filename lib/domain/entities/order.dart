import 'package:pos/domain/value_objects/order_status.dart';
import 'package:pos/domain/value_objects/payment_type.dart';

// nullable 필드를 copyWith에서 null로 되돌릴 수 있도록 sentinel 사용
const _absent = Object();

class Order {
  const Order({
    required this.id,
    required this.businessDayId,
    required this.seatId,
    required this.status,
    required this.totalAmount,
    required this.orderedAt,
    required this.createdAt,
    required this.updatedAt,
    this.paymentType,
    this.creditAccountId,
    this.deliveredAt,
    this.paidAt,
    this.creditedAt,
    this.cancelledAt,
    this.refundedAt,
  });

  final String id;
  final String businessDayId;
  final String seatId;
  final OrderStatus status;
  final int totalAmount;
  final DateTime orderedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final PaymentType? paymentType;
  final String? creditAccountId;
  final DateTime? deliveredAt;
  final DateTime? paidAt;
  final DateTime? creditedAt;
  final DateTime? cancelledAt;
  final DateTime? refundedAt;

  Order copyWith({
    String? id,
    String? businessDayId,
    String? seatId,
    OrderStatus? status,
    int? totalAmount,
    DateTime? orderedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? paymentType = _absent,
    Object? creditAccountId = _absent,
    Object? deliveredAt = _absent,
    Object? paidAt = _absent,
    Object? creditedAt = _absent,
    Object? cancelledAt = _absent,
    Object? refundedAt = _absent,
  }) =>
      Order(
        id: id ?? this.id,
        businessDayId: businessDayId ?? this.businessDayId,
        seatId: seatId ?? this.seatId,
        status: status ?? this.status,
        totalAmount: totalAmount ?? this.totalAmount,
        orderedAt: orderedAt ?? this.orderedAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        paymentType: identical(paymentType, _absent)
            ? this.paymentType
            : paymentType as PaymentType?,
        creditAccountId: identical(creditAccountId, _absent)
            ? this.creditAccountId
            : creditAccountId as String?,
        deliveredAt: identical(deliveredAt, _absent)
            ? this.deliveredAt
            : deliveredAt as DateTime?,
        paidAt: identical(paidAt, _absent) ? this.paidAt : paidAt as DateTime?,
        creditedAt: identical(creditedAt, _absent)
            ? this.creditedAt
            : creditedAt as DateTime?,
        cancelledAt: identical(cancelledAt, _absent)
            ? this.cancelledAt
            : cancelledAt as DateTime?,
        refundedAt: identical(refundedAt, _absent)
            ? this.refundedAt
            : refundedAt as DateTime?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Order && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
