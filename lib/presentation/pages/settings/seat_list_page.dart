import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos/domain/entities/seat.dart';
import 'package:pos/domain/exceptions/domain_exceptions.dart';
import 'package:pos/presentation/pages/settings/widgets/seat_form_dialog.dart';
import 'package:pos/presentation/providers/settings_providers.dart';
import 'package:pos/presentation/theme/app_colors.dart';
import 'package:pos/presentation/theme/app_spacing.dart';
import 'package:pos/presentation/theme/app_typography.dart';
import 'package:pos/presentation/widgets/app_error_widget.dart';
import 'package:pos/presentation/widgets/app_snack_bar.dart';
import 'package:pos/presentation/widgets/confirm_dialog.dart';

class SeatListPage extends ConsumerWidget {
  const SeatListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seatsAsync = ref.watch(seatStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('좌석 관리', style: AppTypography.appBarTitle),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          Semantics(
            button: true,
            label: '좌석 추가',
            child: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _addSeat(context, ref),
            ),
          ),
        ],
      ),
      body: seatsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(message: e.toString()),
        data: (seats) {
          if (seats.isEmpty) {
            return const Center(
              child: Text('등록된 좌석이 없습니다.', style: AppTypography.bodyMedium),
            );
          }

          return ListView.separated(
            itemCount: seats.length,
            separatorBuilder: (_, __) =>
                const Divider(height: AppSpacing.borderWidth),
            itemBuilder: (context, i) => _SeatTile(
              seat: seats[i],
              onEdit: () => _editSeat(context, ref, seats[i]),
              onDelete: () => _deleteSeat(context, ref, seats[i]),
            ),
          );
        },
      ),
    );
  }

  Future<void> _addSeat(BuildContext context, WidgetRef ref) async {
    final result = await SeatFormDialog.show(context);
    if (result == null || !context.mounted) return;

    try {
      await ref.read(createSeatUseCaseProvider).execute(
            seatNumber: result.seatNumber,
            capacity: result.capacity,
          );
      if (context.mounted) AppSnackBar.success(context, '좌석이 추가되었습니다.');
    } on DuplicateSeatNumberException {
      if (context.mounted) {
        AppSnackBar.error(context, '이미 사용 중인 좌석 번호입니다. 다른 번호를 입력하세요.');
      }
    } on Exception catch (e) {
      if (context.mounted) AppSnackBar.error(context, e.toString());
    }
  }

  Future<void> _editSeat(
    BuildContext context,
    WidgetRef ref,
    Seat seat,
  ) async {
    final result = await SeatFormDialog.show(context, initial: seat);
    if (result == null || !context.mounted) return;

    try {
      await ref.read(updateSeatUseCaseProvider).execute(
            seat.id,
            seatNumber: result.seatNumber,
            capacity: result.capacity,
          );
      if (context.mounted) AppSnackBar.success(context, '좌석이 수정되었습니다.');
    } on DuplicateSeatNumberException {
      if (context.mounted) {
        AppSnackBar.error(context, '이미 사용 중인 좌석 번호입니다. 다른 번호를 입력하세요.');
      }
    } on Exception catch (e) {
      if (context.mounted) AppSnackBar.error(context, e.toString());
    }
  }

  Future<void> _deleteSeat(
    BuildContext context,
    WidgetRef ref,
    Seat seat,
  ) async {
    final confirmed = await DestructiveConfirmDialog.show(
      context,
      title: '좌석 삭제',
      message: '"${seat.seatNumber}" 좌석을 삭제하시겠습니까?',
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(deleteSeatUseCaseProvider).execute(seat.id);
      if (context.mounted) AppSnackBar.success(context, '좌석이 삭제되었습니다.');
    } on SeatInUseException {
      if (context.mounted) {
        AppSnackBar.error(
          context,
          '진행 중인 주문이 연결된 좌석은 삭제할 수 없습니다. 주문 완료 후 다시 시도하세요.',
        );
      }
    } on Exception catch (e) {
      if (context.mounted) AppSnackBar.error(context, e.toString());
    }
  }
}

class _SeatTile extends StatelessWidget {
  const _SeatTile({
    required this.seat,
    required this.onEdit,
    required this.onDelete,
  });

  final Seat seat;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => ListTile(
        tileColor: AppColors.surface,
        title: Text(seat.seatNumber, style: AppTypography.bodyLarge),
        subtitle: Text(
          '${seat.capacity}인석',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              button: true,
              label: '${seat.seatNumber} 좌석 수정',
              child: IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: onEdit,
              ),
            ),
            Semantics(
              button: true,
              label: '${seat.seatNumber} 좌석 삭제',
              child: IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                ),
                onPressed: onDelete,
              ),
            ),
          ],
        ),
      );
}
