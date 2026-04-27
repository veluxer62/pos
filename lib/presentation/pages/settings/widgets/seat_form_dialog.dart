import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos/domain/entities/seat.dart';
import 'package:pos/presentation/theme/app_colors.dart';
import 'package:pos/presentation/theme/app_spacing.dart';
import 'package:pos/presentation/theme/app_typography.dart';
import 'package:pos/presentation/widgets/app_button.dart';

class SeatFormResult {
  const SeatFormResult({
    required this.seatNumber,
    required this.capacity,
  });

  final String seatNumber;
  final int capacity;
}

class SeatFormDialog extends StatefulWidget {
  const SeatFormDialog({this.initial, super.key});

  final Seat? initial;

  static Future<SeatFormResult?> show(
    BuildContext context, {
    Seat? initial,
  }) =>
      showDialog<SeatFormResult>(
        context: context,
        builder: (_) => SeatFormDialog(initial: initial),
      );

  @override
  State<SeatFormDialog> createState() => _SeatFormDialogState();
}

class _SeatFormDialogState extends State<SeatFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _seatNumberCtrl;
  late final TextEditingController _capacityCtrl;

  @override
  void initState() {
    super.initState();
    _seatNumberCtrl = TextEditingController(
      text: widget.initial?.seatNumber ?? '',
    );
    _capacityCtrl = TextEditingController(
      text: widget.initial != null ? '${widget.initial!.capacity}' : '',
    );
  }

  @override
  void dispose() {
    _seatNumberCtrl.dispose();
    _capacityCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      SeatFormResult(
        seatNumber: _seatNumberCtrl.text.trim(),
        capacity: int.parse(_capacityCtrl.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;

    return AlertDialog(
      title: Text(
        isEdit ? '좌석 수정' : '좌석 추가',
        style: AppTypography.titleMedium,
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _seatNumberCtrl,
              decoration: const InputDecoration(labelText: '좌석 번호'),
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '좌석 번호를 입력하세요.' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _capacityCtrl,
              decoration: const InputDecoration(labelText: '수용 인원'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              validator: (v) {
                if (v == null || v.isEmpty) return '수용 인원을 입력하세요.';
                final n = int.tryParse(v);
                if (n == null || n <= 0) return '1명 이상의 인원을 입력하세요.';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        Semantics(
          button: true,
          label: '좌석 입력 취소',
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
        ),
        AppButton(
          label: isEdit ? '수정' : '추가',
          variant: AppButtonVariant.primary,
          onPressed: _submit,
        ),
      ],
      backgroundColor: AppColors.surface,
    );
  }
}
