import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/core/router/router.dart';
import 'package:pos/presentation/pages/order/widgets/seat_grid_widget.dart';
import 'package:pos/presentation/providers/order_providers.dart';
import 'package:pos/presentation/theme/app_colors.dart';
import 'package:pos/presentation/theme/app_spacing.dart';
import 'package:pos/presentation/theme/app_typography.dart';
import 'package:pos/presentation/widgets/app_error_widget.dart';

class SeatGridPage extends ConsumerWidget {
  const SeatGridPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seatsAsync = ref.watch(seatListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('좌석 현황', style: AppTypography.appBarTitle),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: seatsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(message: e.toString()),
        data: (seats) {
          if (seats.isEmpty) {
            return const Center(
              child: Text('등록된 좌석이 없습니다.', style: AppTypography.bodyLarge),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                mainAxisSpacing: AppSpacing.lg,
                crossAxisSpacing: AppSpacing.lg,
                childAspectRatio: 1.0,
              ),
              itemCount: seats.length,
              itemBuilder: (context, index) {
                final seat = seats[index];
                final activeOrderAsync =
                    ref.watch(activeOrderBySeatProvider(seat.id));

                final activeOrder = switch (activeOrderAsync) {
                  AsyncData(:final value) => value,
                  _ => null,
                };

                return SeatGridWidget(
                  seat: seat,
                  activeOrder: activeOrder,
                  onTap: () => _onSeatTap(context, seat.id, activeOrder?.id),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _onSeatTap(BuildContext context, String seatId, String? activeOrderId) {
    if (activeOrderId != null) {
      context.go(AppRoutes.orderDetailPath(activeOrderId));
    } else {
      context.go('${AppRoutes.orderCreate}?seatId=$seatId');
    }
  }
}
