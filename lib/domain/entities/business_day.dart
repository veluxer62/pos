import 'package:pos/domain/value_objects/business_day_status.dart';

// nullable 필드를 copyWith에서 null로 되돌릴 수 있도록 sentinel 사용
const _absent = Object();

class BusinessDay {
  const BusinessDay({
    required this.id,
    required this.status,
    required this.openedAt,
    required this.createdAt,
    this.closedAt,
  });

  final String id;
  final BusinessDayStatus status;
  final DateTime openedAt;
  final DateTime createdAt;
  final DateTime? closedAt;

  BusinessDay copyWith({
    String? id,
    BusinessDayStatus? status,
    DateTime? openedAt,
    DateTime? createdAt,
    Object? closedAt = _absent,
  }) =>
      BusinessDay(
        id: id ?? this.id,
        status: status ?? this.status,
        openedAt: openedAt ?? this.openedAt,
        createdAt: createdAt ?? this.createdAt,
        closedAt: identical(closedAt, _absent)
            ? this.closedAt
            : closedAt as DateTime?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BusinessDay && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
