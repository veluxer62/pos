import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos/core/utils/currency_formatter.dart';
import 'package:pos/domain/entities/sales_analysis.dart';
import 'package:pos/domain/entities/sales_forecast.dart';
import 'package:pos/presentation/providers/sales_analysis_providers.dart';
import 'package:pos/presentation/providers/sales_forecast_providers.dart';
import 'package:pos/presentation/theme/app_colors.dart';
import 'package:pos/presentation/theme/app_spacing.dart';
import 'package:pos/presentation/theme/app_typography.dart';
import 'package:pos/presentation/widgets/app_error_widget.dart';

class ReportPage extends ConsumerWidget {
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysisAsync = ref.watch(salesAnalysisProvider());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('매출 분석', style: AppTypography.appBarTitle),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: analysisAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget.fromError(e),
        data: (analysis) => _ReportBody(analysis: analysis),
      ),
    );
  }
}

class _ReportBody extends ConsumerWidget {
  const _ReportBody({required this.analysis});

  final SalesAnalysis analysis;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!analysis.hasEnoughData) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.pagePadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bar_chart, size: 64, color: AppColors.textDisabled),
              SizedBox(height: AppSpacing.lg),
              Text(
                '데이터가 부족합니다',
                style: AppTypography.headlineSmall,
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                '3일 이상 영업 마감 후 분석이 가능합니다.',
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final forecastAsync = ref.watch(salesForecastProvider);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        _InsightsCard(insights: analysis.insights),
        const SizedBox(height: AppSpacing.lg),
        _RevenueTrendCard(trend: analysis.revenueTrend),
        const SizedBox(height: AppSpacing.lg),
        _DayOfWeekCard(averages: analysis.dayOfWeekAverages),
        const SizedBox(height: AppSpacing.lg),
        _HourlyCard(averages: analysis.hourlyAverages),
        const SizedBox(height: AppSpacing.lg),
        _TopMenusCard(menus: analysis.topMenus),
        const SizedBox(height: AppSpacing.lg),
        forecastAsync.when(
          loading: () => const _SectionCard(
            title: '매출 예측 (다음 7일)',
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (forecast) => _ForecastCard(forecast: forecast),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

// ── 인사이트 카드 ─────────────────────────────────────────────

class _InsightsCard extends StatelessWidget {
  const _InsightsCard({required this.insights});

  final List<SalesInsight> insights;

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) return const SizedBox.shrink();

    return _SectionCard(
      title: 'AI 인사이트',
      child: Column(
        children: insights
            .map((insight) => _InsightRow(insight: insight))
            .toList(),
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({required this.insight});

  final SalesInsight insight;

  @override
  Widget build(BuildContext context) {
    final (icon, color, bgColor) = switch (insight.type) {
      InsightType.positive => (
          Icons.trending_up,
          AppColors.success,
          AppColors.successLight,
        ),
      InsightType.warning => (
          Icons.warning_amber_rounded,
          AppColors.warning,
          AppColors.warningLight,
        ),
      InsightType.info => (
          Icons.info_outline,
          AppColors.info,
          AppColors.infoLight,
        ),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: AppSpacing.iconMd),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(insight.message, style: AppTypography.bodyMedium),
          ),
        ],
      ),
    );
  }
}

// ── 매출 추세 카드 ────────────────────────────────────────────

class _RevenueTrendCard extends StatelessWidget {
  const _RevenueTrendCard({required this.trend});

  final RevenueTrend trend;

  @override
  Widget build(BuildContext context) {
    final (trendIcon, trendColor) = switch (trend.direction) {
      TrendDirection.up => (Icons.trending_up, AppColors.success),
      TrendDirection.down => (Icons.trending_down, AppColors.error),
      TrendDirection.stable => (Icons.trending_flat, AppColors.textSecondary),
    };

    return _SectionCard(
      title: '매출 추세 (최근 30일)',
      headerTrailing: Row(
        children: [
          Icon(trendIcon, color: trendColor, size: AppSpacing.iconMd),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '7일 평균 ${CurrencyFormatter.format(trend.movingAverage7Day)}',
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
      child: SizedBox(
        height: 180,
        child: _RevenueLineChart(dailyRevenues: trend.dailyRevenues),
      ),
    );
  }
}

class _RevenueLineChart extends StatelessWidget {
  const _RevenueLineChart({required this.dailyRevenues});

  final List<DailyRevenue> dailyRevenues;

  @override
  Widget build(BuildContext context) {
    if (dailyRevenues.isEmpty) return const SizedBox.shrink();

    final spots = dailyRevenues
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.revenue.toDouble()))
        .toList();

    final maxY = dailyRevenues
        .map((r) => r.revenue)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (dailyRevenues.length / 5).ceilToDouble(),
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= dailyRevenues.length) {
                  return const SizedBox.shrink();
                }
                final date = dailyRevenues[idx].date;
                return Text(
                  '${date.month}/${date.day}',
                  style: AppTypography.labelSmall
                      .copyWith(color: AppColors.textSecondary),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (dailyRevenues.length - 1).toDouble(),
        minY: 0,
        maxY: maxY * 1.2,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.primary,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 요일별 분석 카드 ──────────────────────────────────────────

class _DayOfWeekCard extends StatelessWidget {
  const _DayOfWeekCard({required this.averages});

  final Map<int, int> averages;

  static const _dowLabels = ['', '월', '화', '수', '목', '금', '토', '일'];

  @override
  Widget build(BuildContext context) {
    if (averages.isEmpty) return const SizedBox.shrink();

    final maxVal =
        averages.values.reduce((a, b) => a > b ? a : b).toDouble();
    final bestDow =
        averages.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    final groups = List.generate(7, (i) {
      final dow = i + 1;
      final val = averages[dow]?.toDouble() ?? 0;
      return BarChartGroupData(
        x: dow,
        barRods: [
          BarChartRodData(
            toY: val,
            color: dow == bestDow ? AppColors.secondary : AppColors.primary,
            width: 28,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusSm),
            ),
          ),
        ],
      );
    });

    return _SectionCard(
      title: '요일별 평균 매출',
      child: SizedBox(
        height: 160,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxVal * 1.3,
            barGroups: groups,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) => Text(
                    _dowLabels[value.toInt()],
                    style: AppTypography.labelSmall.copyWith(
                      color: value.toInt() == bestDow
                          ? AppColors.secondary
                          : AppColors.textSecondary,
                      fontWeight: value.toInt() == bestDow
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                    BarTooltipItem(
                  CurrencyFormatter.format(rod.toY.toInt()),
                  AppTypography.labelSmall.copyWith(
                    color: AppColors.textOnDark,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── 시간대별 분석 카드 ────────────────────────────────────────

class _HourlyCard extends StatelessWidget {
  const _HourlyCard({required this.averages});

  final Map<int, double> averages;

  @override
  Widget build(BuildContext context) {
    if (averages.isEmpty) return const SizedBox.shrink();

    final maxVal =
        averages.values.reduce((a, b) => a > b ? a : b);
    final peakHour =
        averages.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    final groups = averages.entries.map((e) {
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: e.value,
            color:
                e.key == peakHour ? AppColors.secondary : AppColors.primaryLight,
            width: 14,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusSm),
            ),
          ),
        ],
      );
    }).toList()
      ..sort((a, b) => a.x.compareTo(b.x));

    return _SectionCard(
      title: '시간대별 평균 주문',
      headerTrailing: Text(
        '피크: $peakHour시대',
        style:
            AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
      ),
      child: SizedBox(
        height: 140,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxVal * 1.3,
            barGroups: groups,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) => Text(
                    '${value.toInt()}시',
                    style: AppTypography.labelSmall.copyWith(
                      color: value.toInt() == peakHour
                          ? AppColors.secondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── 메뉴 랭킹 카드 ────────────────────────────────────────────

class _TopMenusCard extends StatelessWidget {
  const _TopMenusCard({required this.menus});

  final List<MenuRankItem> menus;

  @override
  Widget build(BuildContext context) {
    if (menus.isEmpty) return const SizedBox.shrink();

    final maxQty = menus.first.totalQuantity;

    return _SectionCard(
      title: '인기 메뉴 TOP ${menus.length}',
      child: Column(
        children: menus.asMap().entries.map((e) {
          final rank = e.key + 1;
          final menu = e.value;
          final ratio = maxQty > 0 ? menu.totalQuantity / maxQty : 0.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    '$rank',
                    style: AppTypography.titleSmall.copyWith(
                      color: rank == 1
                          ? AppColors.secondary
                          : AppColors.textSecondary,
                      fontWeight:
                          rank == 1 ? FontWeight.bold : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              menu.menuName,
                              style: AppTypography.bodyMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${menu.totalQuantity}개 · ${CurrencyFormatter.format(menu.totalAmount)}',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusFull),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 6,
                          backgroundColor: AppColors.surfaceVariant,
                          valueColor: AlwaysStoppedAnimation(
                            rank == 1 ? AppColors.secondary : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── 7일 예측 카드 ─────────────────────────────────────────────

class _ForecastCard extends StatelessWidget {
  const _ForecastCard({required this.forecast});

  final SalesForecast forecast;

  @override
  Widget build(BuildContext context) {
    if (forecast.forecastDays.isEmpty) {
      return const _SectionCard(
        title: '매출 예측 (다음 7일)',
        child: Text(
          '예측에 필요한 데이터가 부족합니다. (최소 7일)',
          style: AppTypography.bodyMedium,
        ),
      );
    }

    final maxPredicted = forecast.forecastDays
        .map((d) => d.predictedRevenue)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    final sourceBadge = forecast.source == ForecastSource.tflite
        ? 'TFLite'
        : 'Dart 회귀';
    final badgeColor = forecast.source == ForecastSource.tflite
        ? AppColors.success
        : AppColors.info;

    final groups = forecast.forecastDays.asMap().entries.map((e) {
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: e.value.predictedRevenue.toDouble(),
            color: AppColors.primaryLight,
            width: 28,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusSm),
            ),
          ),
        ],
      );
    }).toList();

    return _SectionCard(
      title: '매출 예측 (다음 7일)',
      headerTrailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!forecast.isReliable)
            const Padding(
              padding: EdgeInsets.only(right: AppSpacing.xs),
              child: Tooltip(
                message: '14일 미만 데이터 — 예측 신뢰도가 낮습니다',
                child: Icon(
                  Icons.info_outline,
                  size: AppSpacing.iconSm,
                  color: AppColors.warning,
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Text(
              sourceBadge,
              style: AppTypography.labelSmall.copyWith(color: badgeColor),
            ),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxPredicted * 1.3,
                barGroups: groups,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= forecast.forecastDays.length) {
                          return const SizedBox.shrink();
                        }
                        final date = forecast.forecastDays[idx].date;
                        return Text(
                          '${date.month}/${date.day}',
                          style: AppTypography.labelSmall
                              .copyWith(color: AppColors.textSecondary),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                      CurrencyFormatter.format(rod.toY.toInt()),
                      AppTypography.labelSmall.copyWith(
                        color: AppColors.textOnDark,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text(
                '학습 데이터: ${forecast.trainedOnDays}일',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
              const Spacer(),
              Text(
                '예측 총액: ${CurrencyFormatter.format(forecast.forecastDays.map((d) => d.predictedRevenue).reduce((a, b) => a + b))}',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 공통 섹션 카드 ─────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.headerTrailing,
  });

  final String title;
  final Widget child;
  final Widget? headerTrailing;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: AppTypography.titleSmall),
                ),
                if (headerTrailing != null) headerTrailing!,
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      );
}
