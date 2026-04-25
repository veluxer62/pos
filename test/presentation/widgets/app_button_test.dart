import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/presentation/widgets/app_button.dart';

void main() {
  Widget buildSubject({
    String label = '버튼',
    VoidCallback? onPressed,
    AppButtonVariant variant = AppButtonVariant.primary,
    IconData? icon,
    bool isLoading = false,
    bool enabled = true,
    double? width,
  }) =>
      MaterialApp(
        home: Scaffold(
          body: AppButton(
            label: label,
            onPressed: onPressed,
            variant: variant,
            icon: icon,
            isLoading: isLoading,
            enabled: enabled,
            width: width,
          ),
        ),
      );

  group('AppButton', () {
    testWidgets('label이 표시된다', (tester) async {
      await tester.pumpWidget(buildSubject(label: '확인'));
      expect(find.text('확인'), findsOneWidget);
    });

    testWidgets('onPressed 콜백이 호출된다', (tester) async {
      var pressed = false;
      await tester.pumpWidget(buildSubject(onPressed: () => pressed = true));
      await tester.tap(find.byType(AppButton));
      expect(pressed, isTrue);
    });

    testWidgets('isLoading이면 버튼이 비활성화된다', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        buildSubject(
          isLoading: true,
          onPressed: () => pressed = true,
        ),
      );
      await tester.tap(find.byType(AppButton));
      expect(pressed, isFalse);
    });

    testWidgets('isLoading이면 CircularProgressIndicator가 표시된다', (tester) async {
      await tester.pumpWidget(buildSubject(isLoading: true));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('enabled=false이면 버튼이 비활성화된다', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        buildSubject(
          enabled: false,
          onPressed: () => pressed = true,
        ),
      );
      await tester.tap(find.byType(AppButton));
      expect(pressed, isFalse);
    });

    testWidgets('icon이 있으면 아이콘이 표시된다', (tester) async {
      await tester.pumpWidget(buildSubject(icon: Icons.add));
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('Semantics label이 설정된다', (tester) async {
      await tester.pumpWidget(buildSubject(label: '확인'));
      // AppButton.build의 Semantics가 가장 바깥쪽 — first로 선택
      final semanticsWidget = tester
          .widgetList<Semantics>(
            find.descendant(
              of: find.byType(AppButton),
              matching: find.byType(Semantics),
            ),
          )
          .first;
      expect(semanticsWidget.properties.label, '확인');
    });

    group('variant', () {
      testWidgets('primary variant는 ElevatedButton으로 렌더된다', (tester) async {
        await tester.pumpWidget(buildSubject(variant: AppButtonVariant.primary));
        expect(find.byType(ElevatedButton), findsOneWidget);
      });

      testWidgets('secondary variant는 ElevatedButton으로 렌더된다', (tester) async {
        await tester.pumpWidget(
          buildSubject(variant: AppButtonVariant.secondary),
        );
        expect(find.byType(ElevatedButton), findsOneWidget);
      });

      testWidgets('destructive variant는 ElevatedButton으로 렌더된다', (tester) async {
        await tester.pumpWidget(
          buildSubject(variant: AppButtonVariant.destructive),
        );
        expect(find.byType(ElevatedButton), findsOneWidget);
      });

      testWidgets('outline variant는 OutlinedButton으로 렌더된다', (tester) async {
        await tester.pumpWidget(
          buildSubject(variant: AppButtonVariant.outline),
        );
        expect(find.byType(OutlinedButton), findsOneWidget);
      });

      testWidgets('text variant는 TextButton으로 렌더된다', (tester) async {
        await tester.pumpWidget(buildSubject(variant: AppButtonVariant.text));
        expect(find.byType(TextButton), findsOneWidget);
      });
    });
  });
}
