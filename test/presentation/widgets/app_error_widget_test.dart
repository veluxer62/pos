import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/presentation/widgets/app_button.dart';
import 'package:pos/presentation/widgets/app_error_widget.dart';

void main() {
  Widget buildSubject(Widget widget) => MaterialApp(
        home: Scaffold(body: widget),
      );

  group('AppErrorWidget', () {
    testWidgets('메시지가 표시된다', (tester) async {
      await tester.pumpWidget(
        buildSubject(const AppErrorWidget(message: '오류가 발생했습니다')),
      );
      expect(find.text('오류가 발생했습니다'), findsOneWidget);
    });

    testWidgets('onRetry가 없으면 재시도 버튼이 표시되지 않는다', (tester) async {
      await tester.pumpWidget(
        buildSubject(const AppErrorWidget(message: '오류')),
      );
      expect(find.byType(AppButton), findsNothing);
    });

    testWidgets('onRetry가 있으면 재시도 버튼이 표시된다', (tester) async {
      await tester.pumpWidget(
        buildSubject(AppErrorWidget(message: '오류', onRetry: () {})),
      );
      expect(find.byType(AppButton), findsOneWidget);
    });

    testWidgets('재시도 버튼 탭 시 onRetry 콜백이 호출된다', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        buildSubject(
          AppErrorWidget(message: '오류', onRetry: () => retried = true),
        ),
      );
      await tester.tap(find.byType(AppButton));
      expect(retried, isTrue);
    });

    testWidgets('retryLabel이 재시도 버튼에 표시된다', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          AppErrorWidget(
            message: '오류',
            onRetry: () {},
            retryLabel: '다시 불러오기',
          ),
        ),
      );
      expect(find.text('다시 불러오기'), findsOneWidget);
    });
  });

  group('AppErrorWidget.fullScreen', () {
    testWidgets('메시지가 표시된다', (tester) async {
      await tester.pumpWidget(
        buildSubject(const AppErrorWidget.fullScreen(message: '네트워크 오류')),
      );
      expect(find.text('네트워크 오류'), findsOneWidget);
    });

    testWidgets('Center 위젯으로 감싸진다', (tester) async {
      await tester.pumpWidget(
        buildSubject(const AppErrorWidget.fullScreen(message: '오류')),
      );
      // 에러 텍스트의 조상 중 Center가 있는지 확인 (fullScreen 전용 구조)
      expect(
        find.ancestor(
          of: find.text('오류'),
          matching: find.byType(Center),
        ),
        findsOneWidget,
      );
    });

    testWidgets('onRetry가 있으면 재시도 버튼이 표시된다', (tester) async {
      await tester.pumpWidget(
        buildSubject(AppErrorWidget.fullScreen(message: '오류', onRetry: () {})),
      );
      expect(find.byType(AppButton), findsOneWidget);
    });
  });
}
