import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos/core/utils/currency_formatter.dart';
import 'package:pos/domain/entities/daily_sales_report.dart';
import 'package:pos/presentation/providers/business_day_providers.dart';
import 'package:pos/presentation/theme/app_colors.dart';
import 'package:pos/presentation/theme/app_spacing.dart';
import 'package:pos/presentation/theme/app_typography.dart';
import 'package:pos/presentation/widgets/app_error_widget.dart';

class DailySalesReportPage extends ConsumerWidget {
  const DailySalesReportPage({required this.businessDayId, super.key});

  final String businessDayId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(businessDayReportProvider(businessDayId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('일일 매출 보고서', style: AppTypography.appBarTitle),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: reportAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(message: e.toString()),
        data: (report) {
          if (report == null) {
            return const Center(
              child: Text('보고서를 찾을 수 없습니다.', style: AppTypography.bodyLarge),
            );
          }
          return _ReportBody(report: report);
        },
      ),
    );
  }
}

class _ReportBody extends StatelessWidget {
  const _ReportBody({required this.report});

  final DailySalesReport report;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          _SummaryCard(report: report),
          const SizedBox(height: AppSpacing.lg),
          _MenuSummaryCard(jsonStr: report.menuSummaryJson),
          const SizedBox(height: AppSpacing.lg),
          _HourlySummaryCard(jsonStr: report.hourlySummaryJson),
        ],
      );
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.report});

  final DailySalesReport report;

  @override
  Widget build(BuildContext context) => _Card(
        title: '요약',
        children: [
          _Row(
            '확정 매출',
            CurrencyFormatter.format(report.totalRevenue),
            highlight: true,
          ),
          _Row('순 매출', CurrencyFormatter.format(report.netRevenue)),
          _Row(
            '외상 발생 (미수금)',
            CurrencyFormatter.format(report.creditedAmount),
          ),
          _Row('결제 완료 주문', '${report.paidOrderCount}건'),
          _Row('외상 주문', '${report.creditedOrderCount}건'),
          _Row('취소', '${report.cancelledOrderCount}건'),
          _Row('환불', '${report.refundedOrderCount}건 '
              '(${CurrencyFormatter.format(report.refundedAmount)})'),
        ],
      );
}

class _MenuSummaryCard extends StatelessWidget {
  const _MenuSummaryCard({required this.jsonStr});

  final String jsonStr;

  @override
  Widget build(BuildContext context) {
    final List<dynamic> items;
    try {
      items = jsonDecode(jsonStr) as List<dynamic>;
    } on FormatException {
      return const SizedBox.shrink();
    }

    if (items.isEmpty) {
      return const _Card(
        title: '메뉴별 판매',
        children: [
          Text('판매 데이터가 없습니다.', style: AppTypography.bodyMedium),
        ],
      );
    }

    return _Card(
      title: '메뉴별 판매',
      children: items.map((item) {
        final map = item as Map<String, dynamic>;
        return _Row(
          map['menuName'] as String,
          '${map['quantity']}개 · ${CurrencyFormatter.format(map['totalAmount'] as int)}',
        );
      }).toList(),
    );
  }
}

class _HourlySummaryCard extends StatelessWidget {
  const _HourlySummaryCard({required this.jsonStr});

  final String jsonStr;

  @override
  Widget build(BuildContext context) {
    final List<dynamic> items;
    try {
      items = jsonDecode(jsonStr) as List<dynamic>;
    } on FormatException {
      return const SizedBox.shrink();
    }

    final active = items
        .where((e) => (e as Map<String, dynamic>)['orderCount'] as int > 0)
        .toList();

    if (active.isEmpty) {
      return const _Card(
        title: '시간대별 분포',
        children: [
          Text('주문 데이터가 없습니다.', style: AppTypography.bodyMedium),
        ],
      );
    }

    return _Card(
      title: '시간대별 분포',
      children: active.map((item) {
        final map = item as Map<String, dynamic>;
        final hour = map['hour'] as int;
        return _Row(
          '${hour.toString().padLeft(2, '0')}:00',
          '${map['orderCount']}건 · ${CurrencyFormatter.format(map['totalAmount'] as int)}',
        );
      }).toList(),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTypography.titleSmall),
            const SizedBox(height: AppSpacing.md),
            ...children,
          ],
        ),
      );
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.highlight = false});

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),
            Text(
              value,
              style: highlight
                  ? AppTypography.titleMedium
                  : AppTypography.bodyMedium,
            ),
          ],
        ),
      );
}
