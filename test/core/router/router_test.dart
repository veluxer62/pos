import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/router/router.dart';

void main() {
  group('AppRoutes', () {
    test('order 경로는 루트이다', () {
      expect(AppRoutes.order, '/');
    });

    test('모든 경로가 /로 시작한다', () {
      expect(AppRoutes.credit, startsWith('/'));
      expect(AppRoutes.report, startsWith('/'));
      expect(AppRoutes.settings, startsWith('/'));
      expect(AppRoutes.businessDay, startsWith('/'));
    });

    test('각 경로가 고유하다', () {
      final routes = [
        AppRoutes.order,
        AppRoutes.credit,
        AppRoutes.report,
        AppRoutes.settings,
        AppRoutes.businessDay,
      ];
      expect(routes.toSet().length, routes.length);
    });
  });

  group('AppRouter', () {
    testWidgets('businessDayGuard가 null이면 정상 라우팅된다', (tester) async {
      final appRouter = AppRouter();
      final router = appRouter.router;

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router),
      );
      await tester.pumpAndSettle();

      // 가드 없이 정상 라우팅 — order 페이지 접근 가능
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('businessDayGuard가 제공되면 redirect에 호출된다', (tester) async {
      var guardCalled = false;
      final appRouter = AppRouter(
        businessDayGuard: (context, state) {
          guardCalled = true;
          return null;
        },
      );

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: appRouter.router),
      );
      await tester.pumpAndSettle();

      expect(guardCalled, isTrue);
    });

    testWidgets('businessDay 경로로 리다이렉트 시 무한 루프 없이 이동한다',
        (tester) async {
      final appRouter = AppRouter(
        businessDayGuard: (context, state) => AppRoutes.businessDay,
      );

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: appRouter.router),
      );
      await tester.pumpAndSettle();

      expect(
        appRouter.router.routerDelegate.currentConfiguration.uri.path,
        AppRoutes.businessDay,
      );
    });
  });
}
