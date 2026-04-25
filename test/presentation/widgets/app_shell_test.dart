import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/core/router/router.dart';
import 'package:pos/presentation/widgets/app_shell.dart';

GoRouter _buildRouter(String initialLocation) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(
          location: state.uri.toString(),
          child: child,
        ),
        routes: [
          GoRoute(
            path: AppRoutes.order,
            builder: (_, __) => const Scaffold(body: Text('주문')),
          ),
          GoRoute(
            path: AppRoutes.credit,
            builder: (_, __) => const Scaffold(body: Text('외상')),
          ),
          GoRoute(
            path: AppRoutes.report,
            builder: (_, __) => const Scaffold(body: Text('보고서')),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (_, __) => const Scaffold(body: Text('설정')),
          ),
        ],
      ),
    ],
  );
}

void main() {
  group('AppShell', () {
    testWidgets('order 경로에서 첫 번째 탭이 선택된다', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(routerConfig: _buildRouter(AppRoutes.order)),
      );
      await tester.pumpAndSettle();

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.selectedIndex, 0);
    });

    testWidgets('credit 경로에서 두 번째 탭이 선택된다', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(routerConfig: _buildRouter(AppRoutes.credit)),
      );
      await tester.pumpAndSettle();

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.selectedIndex, 1);
    });

    testWidgets('report 경로에서 세 번째 탭이 선택된다', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(routerConfig: _buildRouter(AppRoutes.report)),
      );
      await tester.pumpAndSettle();

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.selectedIndex, 2);
    });

    testWidgets('settings 경로에서 네 번째 탭이 선택된다', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(routerConfig: _buildRouter(AppRoutes.settings)),
      );
      await tester.pumpAndSettle();

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.selectedIndex, 3);
    });

    testWidgets('탭 선택 시 해당 경로로 이동한다', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(routerConfig: _buildRouter(AppRoutes.order)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('외상 장부'));
      await tester.pumpAndSettle();

      expect(find.text('외상'), findsOneWidget);
    });

    testWidgets('NavigationRail이 4개 목적지를 포함한다', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(routerConfig: _buildRouter(AppRoutes.order)),
      );
      await tester.pumpAndSettle();

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.destinations.length, 4);
    });
  });
}
