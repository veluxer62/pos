import 'package:flutter/material.dart';
import 'package:pos/presentation/theme/app_spacing.dart';
import 'package:pos/presentation/widgets/app_button.dart';

class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    required this.title,
    required this.message,
    super.key,
    this.confirmLabel = '확인',
    this.cancelLabel = '취소',
    this.isDestructive = false,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;

  /// true이면 확인 버튼을 destructive(빨간색)로 표시
  final bool isDestructive;

  /// [context]에서 다이얼로그를 표시하고 사용자 선택을 반환한다.
  /// 확인 → true, 취소/닫기 → false
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = '확인',
    String cancelLabel = '취소',
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      contentPadding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.sm,
      ),
      actionsPadding: const EdgeInsets.all(AppSpacing.lg),
      actions: [
        AppButton(
          label: cancelLabel,
          variant: AppButtonVariant.outline,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        const SizedBox(width: AppSpacing.sm),
        AppButton(
          label: confirmLabel,
          variant: isDestructive
              ? AppButtonVariant.destructive
              : AppButtonVariant.primary,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}

/// 파괴적 액션(취소·환불·삭제·마감) 전용 확인 다이얼로그
class DestructiveConfirmDialog {
  const DestructiveConfirmDialog._();

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = '삭제',
  }) =>
      ConfirmDialog.show(
        context,
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        isDestructive: true,
      );
}

extension ConfirmDialogExtension on BuildContext {
  Future<bool> showConfirmDialog({
    required String title,
    required String message,
    String confirmLabel = '확인',
    String cancelLabel = '취소',
    bool isDestructive = false,
  }) =>
      ConfirmDialog.show(
        this,
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
      );
}
