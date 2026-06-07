import 'dart:convert';

import 'package:pos/core/utils/currency_formatter.dart';
import 'package:pos/domain/entities/daily_sales_report.dart';
import 'package:pos/domain/entities/sales_analysis.dart';
import 'package:pos/domain/repositories/i_sales_analysis_service.dart';

class SalesAnalysisService implements ISalesAnalysisService {
  static const _dowNames = ['', '월', '화', '수', '목', '금', '토', '일'];

  @override
  SalesAnalysis analyze(List<DailySalesReport> reports) {
    if (reports.isEmpty) return SalesAnalysis.empty();

    final sorted = List.of(reports)
      ..sort((a, b) => a.closedAt.compareTo(b.closedAt));

    final revenueTrend = _buildRevenueTrend(sorted);
    final dayOfWeekAverages = _buildDayOfWeekAverages(sorted);
    final hourlyAverages = _buildHourlyAverages(sorted);
    final topMenus = _buildTopMenus(sorted);
    final insights = _buildInsights(
      reports: sorted,
      revenueTrend: revenueTrend,
      dayOfWeekAverages: dayOfWeekAverages,
      hourlyAverages: hourlyAverages,
    );

    return SalesAnalysis(
      revenueTrend: revenueTrend,
      dayOfWeekAverages: dayOfWeekAverages,
      hourlyAverages: hourlyAverages,
      topMenus: topMenus,
      insights: insights,
      reportCount: reports.length,
    );
  }

  RevenueTrend _buildRevenueTrend(List<DailySalesReport> sorted) {
    final dailyRevenues = sorted
        .map((r) => DailyRevenue(date: r.closedAt, revenue: r.netRevenue))
        .toList();

    final recent7 =
        sorted.length >= 7 ? sorted.sublist(sorted.length - 7) : sorted;
    final ma7 = recent7.isEmpty
        ? 0
        : recent7.map((r) => r.netRevenue).reduce((a, b) => a + b) ~/
            recent7.length;

    double wowChange = 0;
    if (sorted.length >= 14) {
      final thisWeekTotal = sorted
          .sublist(sorted.length - 7)
          .map((r) => r.netRevenue)
          .reduce((a, b) => a + b);
      final lastWeekTotal = sorted
          .sublist(sorted.length - 14, sorted.length - 7)
          .map((r) => r.netRevenue)
          .reduce((a, b) => a + b);
      if (lastWeekTotal > 0) {
        wowChange = (thisWeekTotal - lastWeekTotal) / lastWeekTotal * 100;
      }
    }

    final TrendDirection direction;
    if (wowChange > 5) {
      direction = TrendDirection.up;
    } else if (wowChange < -5) {
      direction = TrendDirection.down;
    } else {
      direction = TrendDirection.stable;
    }

    return RevenueTrend(
      dailyRevenues: dailyRevenues,
      movingAverage7Day: ma7,
      weekOverWeekChangePercent: wowChange,
      direction: direction,
    );
  }

  Map<int, int> _buildDayOfWeekAverages(List<DailySalesReport> sorted) {
    final buckets = <int, List<int>>{};
    for (final r in sorted) {
      buckets.putIfAbsent(r.closedAt.weekday, () => []).add(r.netRevenue);
    }
    return {
      for (final e in buckets.entries)
        e.key: e.value.reduce((a, b) => a + b) ~/ e.value.length,
    };
  }

  Map<int, double> _buildHourlyAverages(List<DailySalesReport> sorted) {
    final buckets = <int, List<int>>{};
    for (final r in sorted) {
      try {
        final items = jsonDecode(r.hourlySummaryJson) as List<dynamic>;
        for (final item in items) {
          final map = item as Map<String, dynamic>;
          final count = map['orderCount'] as int;
          if (count > 0) {
            buckets
                .putIfAbsent(map['hour'] as int, () => [])
                .add(count);
          }
        }
      } on FormatException {
        continue;
      }
    }
    return {
      for (final e in buckets.entries)
        e.key: e.value.reduce((a, b) => a + b) / e.value.length,
    };
  }

  List<MenuRankItem> _buildTopMenus(List<DailySalesReport> sorted) {
    final acc = <String, _MenuAcc>{};
    for (final r in sorted) {
      try {
        final items = jsonDecode(r.menuSummaryJson) as List<dynamic>;
        for (final item in items) {
          final map = item as Map<String, dynamic>;
          final name = map['menuName'] as String;
          acc.putIfAbsent(name, _MenuAcc.new)
            ..quantity += map['quantity'] as int
            ..amount += map['totalAmount'] as int;
        }
      } on FormatException {
        continue;
      }
    }

    return (acc.entries
          .map(
            (e) => MenuRankItem(
              menuName: e.key,
              totalQuantity: e.value.quantity,
              totalAmount: e.value.amount,
            ),
          )
          .toList()
          ..sort((a, b) => b.totalQuantity.compareTo(a.totalQuantity)))
        .take(5)
        .toList();
  }

  List<SalesInsight> _buildInsights({
    required List<DailySalesReport> reports,
    required RevenueTrend revenueTrend,
    required Map<int, int> dayOfWeekAverages,
    required Map<int, double> hourlyAverages,
  }) {
    final insights = <SalesInsight>[];

    // 매출 추세
    final pct = revenueTrend.weekOverWeekChangePercent;
    if (reports.length >= 14) {
      switch (revenueTrend.direction) {
        case TrendDirection.up:
          insights.add(
            SalesInsight(
              type: InsightType.positive,
              message: '지난주 대비 매출이 ${pct.abs().toStringAsFixed(1)}% 상승했습니다.',
            ),
          );
        case TrendDirection.down:
          insights.add(
            SalesInsight(
              type: InsightType.warning,
              message: '지난주 대비 매출이 ${pct.abs().toStringAsFixed(1)}% 하락했습니다.',
            ),
          );
        case TrendDirection.stable:
          insights.add(
            const SalesInsight(
              type: InsightType.info,
              message: '지난주와 비슷한 매출 수준을 유지하고 있습니다.',
            ),
          );
      }
    }

    // 최고 요일
    if (dayOfWeekAverages.isNotEmpty) {
      final best = dayOfWeekAverages.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      insights.add(
        SalesInsight(
          type: InsightType.info,
          message:
              '${_dowNames[best.key]}요일 매출이 가장 높습니다. (평균 ${CurrencyFormatter.format(best.value)})',
        ),
      );
    }

    // 피크 시간대
    if (hourlyAverages.isNotEmpty) {
      final peak =
          hourlyAverages.entries.reduce((a, b) => a.value > b.value ? a : b);
      insights.add(
        SalesInsight(
          type: InsightType.info,
          message: '${peak.key}시대가 하루 중 가장 바쁜 시간대입니다.',
        ),
      );
    }

    // 외상 비율 경고
    if (reports.length >= 5) {
      final totalRevenue =
          reports.map((r) => r.totalRevenue).reduce((a, b) => a + b);
      final totalCredit =
          reports.map((r) => r.creditedAmount).reduce((a, b) => a + b);
      if (totalRevenue > 0 && totalCredit / totalRevenue > 0.3) {
        final ratio = totalCredit / totalRevenue * 100;
        insights.add(
          SalesInsight(
            type: InsightType.warning,
            message:
                '외상 비율이 ${ratio.toStringAsFixed(1)}%로 높습니다. 미수금 관리가 필요합니다.',
          ),
        );
      }
    }

    return insights;
  }
}

class _MenuAcc {
  int quantity = 0;
  int amount = 0;
}
