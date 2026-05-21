import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos/domain/value_objects/order_status.dart';
import 'package:pos/presentation/providers/business_day_providers.dart';
import 'package:pos/presentation/providers/order_providers.dart';
import 'package:pos/presentation/theme/app_colors.dart';
import 'package:pos/presentation/theme/app_spacing.dart';
import 'package:pos/presentation/theme/app_typography.dart';
import 'package:pos/presentation/widgets/app_button.dart';

sealed class CloseDialogResult {}

class CloseDialogResultClose extends CloseDialogResult {
  CloseDialogResultClose({required this.forceClose});
  final bool forceClose;
}

class CloseDialogResultDiscard extends CloseDialogResult {}

class CloseBusinessDayDialog extends ConsumerWidget {
  const CloseBusinessDayDialog({super.key});

  static Future<CloseDialogResult?> show(BuildContext context) =>
      showDialog<CloseDialogResult>(
        context: context,
        builder: (_) => const CloseBusinessDayDialog(),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final openDayAsync = ref.watch(openBusinessDayProvider);

    return openDayAsync.when(
      loading: () => const AlertDialog(
        content: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => AlertDialog(
        title: const Text('오류'),
        content: Text(e.toString()),
        actions: [
          Semantics(
            button: true,
            label: '오류 다이얼로그 닫기',
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('닫기'),
            ),
          ),
        ],
      ),
      data: (openDay) {
        if (openDay == null) {
          return AlertDialog(
            title: const Text('영업 마감'),
            content: const Text('현재 열린 영업일이 없습니다.'),
            actions: [
              Semantics(
                button: true,
                label: '영업일 없음 다이얼로그 닫기',
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('닫기'),
                ),
              ),
            ],
          );
        }

        final ordersAsync = ref.watch(
          activeOrdersByBusinessDayProvider(openDay.id),
        );

        return ordersAsync.when(
          loading: () => const AlertDialog(
            content: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => AlertDialog(content: Text(e.toString())),
          data: (orders) {
            // 주문이 하나도 없으면 기록 여부를 물어본다
            if (orders.isEmpty) {
              return AlertDialog(
                title: const Text('영업 마감'),
                content: const Text('주문 기록이 없습니다.\n영업 기록을 남기시겠습니까?'),
                actions: [
                  Semantics(
                    button: true,
                    label: '영업 마감 취소',
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('취소'),
                    ),
                  ),
                  AppButton(
                    label: '기록 안 함',
                    variant: AppButtonVariant.secondary,
                    onPressed: () => Navigator.of(context)
                        .pop(CloseDialogResultDiscard()),
                  ),
                  AppButton(
                    label: '기록',
                    variant: AppButtonVariant.primary,
                    onPressed: () => Navigator.of(context).pop(
                      CloseDialogResultClose(forceClose: false),
                    ),
                  ),
                ],
              );
            }

            final pending =
                orders.where((o) => o.status is OrderStatusPending).toList();
            final delivered =
                orders.where((o) => o.status is OrderStatusDelivered).toList();
            final hasPending = pending.isNotEmpty || delivered.isNotEmpty;

            return AlertDialog(
              title: const Text('영업 마감'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasPending) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '미처리 주문이 있습니다',
                            style: AppTypography.labelLarge
                                .copyWith(color: AppColors.error),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          if (pending.isNotEmpty)
                            Text(
                              '준비중: ${pending.length}건',
                              style: AppTypography.bodyMedium,
                            ),
                          if (delivered.isNotEmpty)
                            Text(
                              '전달 완료: ${delivered.length}건',
                              style: AppTypography.bodyMedium,
                            ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '강제 마감 시 미처리 주문이 취소됩니다.',
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ] else
                    const Text('마감하시겠습니까?'),
                ],
              ),
              actions: [
                Semantics(
                  button: true,
                  label: '영업 마감 취소',
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('취소'),
                  ),
                ),
                if (hasPending)
                  AppButton(
                    label: '강제 마감',
                    variant: AppButtonVariant.destructive,
                    onPressed: () => Navigator.of(context).pop(
                      CloseDialogResultClose(forceClose: true),
                    ),
                  )
                else
                  AppButton(
                    label: '마감',
                    variant: AppButtonVariant.primary,
                    onPressed: () => Navigator.of(context).pop(
                      CloseDialogResultClose(forceClose: false),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
