import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/core/router/router.dart';
import 'package:pos/domain/entities/business_day.dart';
import 'package:pos/domain/value_objects/business_day_status.dart';
import 'package:pos/presentation/providers/business_day_providers.dart';
import 'package:pos/presentation/widgets/app_shell.dart';

final _now = DateTime(2024, 1, 1, 9);

final _openDay = BusinessDay(
  id: 'bd-1',
  status: BusinessDayStatus.open,
  openedAt: _now,
  createdAt: _now,
);

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
            path: AppRoutes.salesHistory,
            builder: (_, __) => const Scaffold(body: Text('매출 내역')),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (_, __) => const Scaffold(body: Text('설정 페이지')),
          ),
        ],
      ),
    ],
  );
}

Widget _buildApp({
  required String initialLocation,
  BusinessDay? openDay,
}) =>
    ProviderScope(
      overrides: [
        openBusinessDayProvider.overrideWith(
          (_) => Stream.value(openDay),
        ),
      ],
      child: MaterialApp.router(routerConfig: _buildRouter(initialLocation)),
    );

void main() {
  group('AppShell - 영업 중', () {
    testWidgets('주문 현황 메뉴가 표시된다', (tester) async {
      await tester.pumpWidget(
        _buildApp(initialLocation: AppRoutes.order, openDay: _openDay),
      );
      await tester.pumpAndSettle();

      expect(find.text('주문 현황'), findsOneWidget);
    });

    testWidgets('NavigationRail이 4개 목적지를 포함한다', (tester) async {
      await tester.pumpWidget(
        _buildApp(initialLocation: AppRoutes.order, openDay: _openDay),
      );
      await tester.pumpAndSettle();

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.destinations.length, 4);
    });

    testWidgets('order 경로에서 첫 번째 탭이 선택된다', (tester) async {
      await tester.pumpWidget(
        _buildApp(initialLocation: AppRoutes.order, openDay: _openDay),
      );
      await tester.pumpAndSettle();

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.selectedIndex, 0);
    });

    testWidgets('credit 경로에서 두 번째 탭이 선택된다', (tester) async {
      await tester.pumpWidget(
        _buildApp(initialLocation: AppRoutes.credit, openDay: _openDay),
      );
      await tester.pumpAndSettle();

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.selectedIndex, 1);
    });

    testWidgets('salesHistory 경로에서 세 번째 탭이 선택된다', (tester) async {
      await tester.pumpWidget(
        _buildApp(initialLocation: AppRoutes.salesHistory, openDay: _openDay),
      );
      await tester.pumpAndSettle();

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.selectedIndex, 2);
    });

    testWidgets('settings 경로에서 네 번째 탭이 선택된다', (tester) async {
      await tester.pumpWidget(
        _buildApp(initialLocation: AppRoutes.settings, openDay: _openDay),
      );
      await tester.pumpAndSettle();

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.selectedIndex, 3);
    });

    testWidgets('탭 선택 시 해당 경로로 이동한다', (tester) async {
      await tester.pumpWidget(
        _buildApp(initialLocation: AppRoutes.order, openDay: _openDay),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('외상 장부'));
      await tester.pumpAndSettle();

      expect(find.text('외상'), findsOneWidget);
    });
  });

  group('AppShell - 영업 전', () {
    testWidgets('주문 현황 메뉴가 표시되지 않는다', (tester) async {
      await tester.pumpWidget(
        _buildApp(initialLocation: AppRoutes.credit, openDay: null),
      );
      await tester.pumpAndSettle();

      expect(find.text('주문 현황'), findsNothing);
    });

    testWidgets('NavigationRail이 3개 목적지를 포함한다', (tester) async {
      await tester.pumpWidget(
        _buildApp(initialLocation: AppRoutes.credit, openDay: null),
      );
      await tester.pumpAndSettle();

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.destinations.length, 3);
    });

    testWidgets('credit 경로에서 첫 번째 탭이 선택된다', (tester) async {
      await tester.pumpWidget(
        _buildApp(initialLocation: AppRoutes.credit, openDay: null),
      );
      await tester.pumpAndSettle();

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.selectedIndex, 0);
    });

    testWidgets('salesHistory 경로에서 두 번째 탭이 선택된다', (tester) async {
      await tester.pumpWidget(
        _buildApp(initialLocation: AppRoutes.salesHistory, openDay: null),
      );
      await tester.pumpAndSettle();

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.selectedIndex, 1);
    });

    testWidgets('settings 경로에서 세 번째 탭이 선택된다', (tester) async {
      await tester.pumpWidget(
        _buildApp(initialLocation: AppRoutes.settings, openDay: null),
      );
      await tester.pumpAndSettle();

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.selectedIndex, 2);
    });

    testWidgets('탭 선택 시 해당 경로로 이동한다', (tester) async {
      await tester.pumpWidget(
        _buildApp(initialLocation: AppRoutes.credit, openDay: null),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('설정'));
      await tester.pumpAndSettle();

      expect(find.text('설정 페이지'), findsOneWidget);
    });
  });
}
