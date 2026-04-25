import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/presentation/widgets/confirm_dialog.dart';

void main() {
  Widget buildSubject({
    String title = '제목',
    String message = '메시지',
    String confirmLabel = '확인',
    String cancelLabel = '취소',
    bool isDestructive = false,
  }) =>
      MaterialApp(
        home: Scaffold(
          body: ConfirmDialog(
            title: title,
            message: message,
            confirmLabel: confirmLabel,
            cancelLabel: cancelLabel,
            isDestructive: isDestructive,
          ),
        ),
      );

  group('ConfirmDialog', () {
    testWidgets('title과 message가 표시된다', (tester) async {
      await tester.pumpWidget(
        buildSubject(title: '삭제 확인', message: '정말 삭제하시겠습니까?'),
      );
      expect(find.text('삭제 확인'), findsOneWidget);
      expect(find.text('정말 삭제하시겠습니까?'), findsOneWidget);
    });

    testWidgets('확인 버튼과 취소 버튼이 표시된다', (tester) async {
      await tester.pumpWidget(
        buildSubject(confirmLabel: '확인', cancelLabel: '취소'),
      );
      expect(find.text('확인'), findsOneWidget);
      expect(find.text('취소'), findsOneWidget);
    });

    testWidgets('ConfirmDialog.show — 확인 버튼 탭 시 true 반환', (tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await ConfirmDialog.show(
                    context,
                    title: '주문 취소',
                    message: '계속하시겠습니까?',
                    confirmLabel: '네',
                    cancelLabel: '아니오',
                  );
                },
                child: const Text('열기'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('네'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
    });

    testWidgets('ConfirmDialog.show — 취소 버튼 탭 시 false 반환', (tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await ConfirmDialog.show(
                    context,
                    title: '주문 취소',
                    message: '계속하시겠습니까?',
                    confirmLabel: '네',
                    cancelLabel: '아니오',
                  );
                },
                child: const Text('열기'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('아니오'));
      await tester.pumpAndSettle();
      expect(result, isFalse);
    });

    testWidgets('DestructiveConfirmDialog.show — 기본 confirmLabel은 삭제',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => DestructiveConfirmDialog.show(
                  context,
                  title: '삭제',
                  message: '삭제하시겠습니까?',
                ),
                child: const Text('열기'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();
      expect(find.text('삭제'), findsWidgets);
    });
  });
}
