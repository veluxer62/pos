class DailySalesReport {
  const DailySalesReport({
    required this.id,
    required this.businessDayId,
    required this.openedAt,
    required this.closedAt,
    required this.totalRevenue,
    required this.paidOrderCount,
    required this.creditedAmount,
    required this.creditedOrderCount,
    required this.cancelledOrderCount,
    required this.refundedOrderCount,
    required this.refundedAmount,
    required this.netRevenue,
    required this.menuSummaryJson,
    required this.hourlySummaryJson,
    required this.createdAt,
  });

  final String id;
  final String businessDayId;

  /// 영업 시작 시각 스냅샷
  final DateTime openedAt;

  /// 영업 마감 시각 스냅샷
  final DateTime closedAt;

  /// PAID 주문 합산 매출 (KRW)
  final int totalRevenue;

  final int paidOrderCount;

  /// CREDITED 주문 합산 미수금 (KRW)
  final int creditedAmount;

  final int creditedOrderCount;
  final int cancelledOrderCount;
  final int refundedOrderCount;

  /// 환불 합산 금액 (KRW)
  final int refundedAmount;

  /// totalRevenue - refundedAmount
  final int netRevenue;

  /// `List<MenuSalesItem>` JSON 인코딩 — 마감 시점 스냅샷
  final String menuSummaryJson;

  /// `List<HourlySalesItem>` JSON 인코딩 — 마감 시점 스냅샷
  final String hourlySummaryJson;

  final DateTime createdAt;

  DailySalesReport copyWith({
    String? id,
    String? businessDayId,
    DateTime? openedAt,
    DateTime? closedAt,
    int? totalRevenue,
    int? paidOrderCount,
    int? creditedAmount,
    int? creditedOrderCount,
    int? cancelledOrderCount,
    int? refundedOrderCount,
    int? refundedAmount,
    int? netRevenue,
    String? menuSummaryJson,
    String? hourlySummaryJson,
    DateTime? createdAt,
  }) => DailySalesReport(
    id: id ?? this.id,
    businessDayId: businessDayId ?? this.businessDayId,
    openedAt: openedAt ?? this.openedAt,
    closedAt: closedAt ?? this.closedAt,
    totalRevenue: totalRevenue ?? this.totalRevenue,
    paidOrderCount: paidOrderCount ?? this.paidOrderCount,
    creditedAmount: creditedAmount ?? this.creditedAmount,
    creditedOrderCount: creditedOrderCount ?? this.creditedOrderCount,
    cancelledOrderCount: cancelledOrderCount ?? this.cancelledOrderCount,
    refundedOrderCount: refundedOrderCount ?? this.refundedOrderCount,
    refundedAmount: refundedAmount ?? this.refundedAmount,
    netRevenue: netRevenue ?? this.netRevenue,
    menuSummaryJson: menuSummaryJson ?? this.menuSummaryJson,
    hourlySummaryJson: hourlySummaryJson ?? this.hourlySummaryJson,
    createdAt: createdAt ?? this.createdAt,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DailySalesReport && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
