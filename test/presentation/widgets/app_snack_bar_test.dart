import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/presentation/theme/app_colors.dart';
import 'package:pos/presentation/widgets/app_snack_bar.dart';

void main() {
  Future<void> showPumpAssertAndDismiss(
    WidgetTester tester,
    SnackBarType type,
    String message,
    void Function() assertions,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  AppSnackBar.show(context, message: message, type: type),
              child: const Text('show'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('show'));
    await tester.pump();
    assertions();
    // 3초 딜레이 타이머 소진 + 300ms 역방향 애니메이션 완료
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
  }

  Finder findToastWithColor(Color expectedColor) => find.byWidgetPredicate(
        (widget) =>
            widget is DecoratedBox &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).color == expectedColor,
      );

  group('AppSnackBar', () {
    testWidgets('success 타입 — 메시지가 표시된다', (tester) async {
      await showPumpAssertAndDismiss(tester, SnackBarType.success, '성공', () {
        expect(find.text('성공'), findsOneWidget);
      });
    });

    testWidgets('error 타입 — 메시지가 표시된다', (tester) async {
      await showPumpAssertAndDismiss(tester, SnackBarType.error, '오류', () {
        expect(find.text('오류'), findsOneWidget);
      });
    });

    testWidgets('success 타입 — 배경색이 AppColors.success이다', (tester) async {
      await showPumpAssertAndDismiss(tester, SnackBarType.success, '성공', () {
        expect(findToastWithColor(AppColors.success), findsOneWidget);
      });
    });

    testWidgets('error 타입 — 배경색이 AppColors.error이다', (tester) async {
      await showPumpAssertAndDismiss(tester, SnackBarType.error, '오류', () {
        expect(findToastWithColor(AppColors.error), findsOneWidget);
      });
    });

    testWidgets('warning 타입 — 배경색이 AppColors.warning이다', (tester) async {
      await showPumpAssertAndDismiss(tester, SnackBarType.warning, '경고', () {
        expect(findToastWithColor(AppColors.warning), findsOneWidget);
      });
    });

    testWidgets('info 타입 — 배경색이 AppColors.info이다', (tester) async {
      await showPumpAssertAndDismiss(tester, SnackBarType.info, '정보', () {
        expect(findToastWithColor(AppColors.info), findsOneWidget);
      });
    });
  });
}
