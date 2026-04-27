import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/core/router/router.dart';
import 'package:pos/core/utils/currency_formatter.dart';
import 'package:pos/core/utils/date_formatter.dart';
import 'package:pos/domain/entities/business_day.dart';
import 'package:pos/presentation/providers/business_day_providers.dart';
import 'package:pos/presentation/theme/app_colors.dart';
import 'package:pos/presentation/theme/app_spacing.dart';
import 'package:pos/presentation/theme/app_typography.dart';
import 'package:pos/presentation/widgets/app_error_widget.dart';

class SalesHistoryPage extends ConsumerWidget {
  const SalesHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(businessDayHistoryProvider());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('매출 내역', style: AppTypography.appBarTitle),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(message: e.toString()),
        data: (days) {
          if (days.isEmpty) {
            return const Center(
              child: Text(
                '매출 내역이 없습니다.',
                style: AppTypography.bodyMedium,
              ),
            );
          }

          return ListView.separated(
            itemCount: days.length,
            separatorBuilder: (_, __) =>
                const Divider(height: AppSpacing.borderWidth),
            itemBuilder: (context, i) {
              final day = days[i];
              return _HistoryTile(
                businessDay: day,
                onTap: day.closedAt != null
                    ? () => context.go(AppRoutes.businessDayReportPath(day.id))
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}

class _HistoryTile extends ConsumerWidget {
  const _HistoryTile({required this.businessDay, required this.onTap});

  final BusinessDay businessDay;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(businessDayReportProvider(businessDay.id));

    return ListTile(
      tileColor: AppColors.surface,
      title: Text(
        DateFormatter.formatDate(businessDay.openedAt),
        style: AppTypography.bodyLarge,
      ),
      subtitle: reportAsync.when(
        loading: () => null,
        error: (_, __) => null,
        data: (report) {
          if (report == null) return null;
          return Text(
            '${CurrencyFormatter.format(report.totalRevenue)} · '
            '${report.paidOrderCount}건',
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textSecondary),
          );
        },
      ),
      trailing: businessDay.closedAt != null
          ? const Icon(Icons.chevron_right, color: AppColors.textSecondary)
          : Semantics(
              label: '현재 영업중',
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.statusDeliveredBg,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  '영업중',
                  style: AppTypography.labelSmall
                      .copyWith(color: AppColors.statusDelivered),
                ),
              ),
            ),
      onTap: onTap,
    );
  }
}
