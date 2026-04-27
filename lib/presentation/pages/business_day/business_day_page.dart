import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/core/router/router.dart';
import 'package:pos/domain/entities/business_day.dart';
import 'package:pos/domain/exceptions/domain_exceptions.dart';
import 'package:pos/presentation/pages/business_day/widgets/close_business_day_dialog.dart';
import 'package:pos/presentation/providers/business_day_providers.dart';
import 'package:pos/presentation/theme/app_colors.dart';
import 'package:pos/presentation/theme/app_spacing.dart';
import 'package:pos/presentation/theme/app_typography.dart';
import 'package:pos/presentation/widgets/app_button.dart';
import 'package:pos/presentation/widgets/app_error_widget.dart';
import 'package:pos/presentation/widgets/app_snack_bar.dart';

/// 영업 시작이 필요한 경우 라우트 가드가 이 페이지로 리다이렉트한다.
class BusinessDayPage extends ConsumerWidget {
  const BusinessDayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final openDayAsync = ref.watch(openBusinessDayProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('영업 관리', style: AppTypography.appBarTitle),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: openDayAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(message: e.toString()),
        data: (openDay) => _BusinessDayBody(openDay: openDay),
      ),
    );
  }
}

class _BusinessDayBody extends ConsumerWidget {
  const _BusinessDayBody({required this.openDay});

  final BusinessDay? openDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOpen = openDay != null;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StatusCard(isOpen: isOpen, openDay: openDay),
          const SizedBox(height: AppSpacing.xl),
          if (!isOpen)
            AppButton(
              label: '영업 시작',
              variant: AppButtonVariant.primary,
              onPressed: () => _openBusinessDay(context, ref),
            )
          else ...[
            AppButton(
              label: '주문 관리로 이동',
              variant: AppButtonVariant.secondary,
              onPressed: () => context.go(AppRoutes.order),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: '영업 마감',
              variant: AppButtonVariant.destructive,
              onPressed: () => _closeBusinessDay(context, ref),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openBusinessDay(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(openBusinessDayUseCaseProvider).execute();
      ref.invalidate(openBusinessDayProvider);
      if (context.mounted) {
        AppSnackBar.success(context, '영업이 시작되었습니다.');
        context.go(AppRoutes.order);
      }
    } on BusinessDayAlreadyOpenException catch (e) {
      if (context.mounted) AppSnackBar.error(context, e.message);
    } on Exception catch (e) {
      if (context.mounted) AppSnackBar.error(context, e.toString());
    }
  }

  Future<void> _closeBusinessDay(BuildContext context, WidgetRef ref) async {
    final result = await CloseBusinessDayDialog.show(context);
    if (result == null || !context.mounted) return;

    try {
      final closeResult = await ref
          .read(closeBusinessDayUseCaseProvider)
          .execute(forceClose: result.forceClose);
      ref.invalidate(openBusinessDayProvider);
      if (context.mounted) {
        AppSnackBar.success(context, '영업이 마감되었습니다.');
        context.go(
          AppRoutes.businessDayReportPath(closeResult.businessDay.id),
        );
      }
    } on PendingOrdersExistException catch (e) {
      if (context.mounted) AppSnackBar.error(context, e.message);
    } on Exception catch (e) {
      if (context.mounted) AppSnackBar.error(context, e.toString());
    }
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.isOpen, required this.openDay});

  final bool isOpen;
  final BusinessDay? openDay;

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
            Row(
              children: [
                Semantics(
                  label: isOpen ? '영업중' : '영업 종료',
                  child: Container(
                    width: AppSpacing.statusDotSize,
                    height: AppSpacing.statusDotSize,
                    decoration: BoxDecoration(
                      color: isOpen ? AppColors.success : AppColors.textDisabled,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  isOpen ? '영업중' : '영업 종료',
                  style: AppTypography.titleMedium.copyWith(
                    color: isOpen ? AppColors.success : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            if (openDay != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                '개시 시각: ${_formatTime(openDay!.openedAt)}',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      );

  String _formatTime(DateTime dt) =>
      '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
