import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/presentation/theme/app_colors.dart';
import 'package:pos/presentation/widgets/app_snack_bar.dart';

void main() {
  Future<void> showAndPump(
    WidgetTester tester,
    SnackBarType type,
    String message,
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
  }

  group('AppSnackBar', () {
    testWidgets('success 타입 — 메시지가 표시된다', (tester) async {
      await showAndPump(tester, SnackBarType.success, '성공');
      expect(find.text('성공'), findsOneWidget);
    });

    testWidgets('error 타입 — 메시지가 표시된다', (tester) async {
      await showAndPump(tester, SnackBarType.error, '오류');
      expect(find.text('오류'), findsOneWidget);
    });

    testWidgets('success 타입 — 배경색이 AppColors.success이다', (tester) async {
      await showAndPump(tester, SnackBarType.success, '성공');
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, AppColors.success);
    });

    testWidgets('error 타입 — 배경색이 AppColors.error이다', (tester) async {
      await showAndPump(tester, SnackBarType.error, '오류');
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, AppColors.error);
    });

    testWidgets('warning 타입 — 배경색이 AppColors.warning이다', (tester) async {
      await showAndPump(tester, SnackBarType.warning, '경고');
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, AppColors.warning);
    });

    testWidgets('info 타입 — 배경색이 AppColors.info이다', (tester) async {
      await showAndPump(tester, SnackBarType.info, '정보');
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, AppColors.info);
    });

    testWidgets('action이 제공되면 SnackBarAction이 표시된다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => AppSnackBar.show(
                  context,
                  message: '메시지',
                  actionLabel: '실행',
                  onAction: () {},
                ),
                child: const Text('show'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('show'));
      await tester.pump();
      expect(find.text('실행'), findsOneWidget);
    });

    testWidgets('action이 없으면 SnackBarAction이 표시되지 않는다', (tester) async {
      await showAndPump(tester, SnackBarType.info, '메시지');
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.action, isNull);
    });
  });
}
