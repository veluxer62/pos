enum InsightType { positive, warning, info }

enum TrendDirection { up, down, stable }

class SalesInsight {
  const SalesInsight({required this.type, required this.message});

  final InsightType type;
  final String message;
}

class DailyRevenue {
  const DailyRevenue({required this.date, required this.revenue});

  final DateTime date;
  final int revenue;
}

class MenuRankItem {
  const MenuRankItem({
    required this.menuName,
    required this.totalQuantity,
    required this.totalAmount,
  });

  final String menuName;
  final int totalQuantity;
  final int totalAmount;
}

class RevenueTrend {
  const RevenueTrend({
    required this.dailyRevenues,
    required this.movingAverage7Day,
    required this.weekOverWeekChangePercent,
    required this.direction,
  });

  final List<DailyRevenue> dailyRevenues;
  final int movingAverage7Day;
  final double weekOverWeekChangePercent;
  final TrendDirection direction;
}

class SalesAnalysis {
  const SalesAnalysis({
    required this.revenueTrend,
    required this.dayOfWeekAverages,
    required this.hourlyAverages,
    required this.topMenus,
    required this.insights,
    required this.reportCount,
  });

  /// 요일별 평균 순매출 (1=월, 7=일)
  final Map<int, int> dayOfWeekAverages;

  /// 시간대별 평균 주문 건수 (0–23)
  final Map<int, double> hourlyAverages;

  final RevenueTrend revenueTrend;
  final List<MenuRankItem> topMenus;
  final List<SalesInsight> insights;
  final int reportCount;

  bool get hasEnoughData => reportCount >= 3;

  SalesAnalysis copyWith({
    RevenueTrend? revenueTrend,
    Map<int, int>? dayOfWeekAverages,
    Map<int, double>? hourlyAverages,
    List<MenuRankItem>? topMenus,
    List<SalesInsight>? insights,
    int? reportCount,
  }) =>
      SalesAnalysis(
        revenueTrend: revenueTrend ?? this.revenueTrend,
        dayOfWeekAverages: dayOfWeekAverages ?? this.dayOfWeekAverages,
        hourlyAverages: hourlyAverages ?? this.hourlyAverages,
        topMenus: topMenus ?? this.topMenus,
        insights: insights ?? this.insights,
        reportCount: reportCount ?? this.reportCount,
      );

  static SalesAnalysis empty() => const SalesAnalysis(
        revenueTrend: RevenueTrend(
          dailyRevenues: [],
          movingAverage7Day: 0,
          weekOverWeekChangePercent: 0,
          direction: TrendDirection.stable,
        ),
        dayOfWeekAverages: {},
        hourlyAverages: {},
        topMenus: [],
        insights: [],
        reportCount: 0,
      );
}
