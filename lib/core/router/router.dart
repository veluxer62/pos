import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/presentation/pages/business_day/business_day_page.dart';
import 'package:pos/presentation/pages/business_day/report_page.dart';
import 'package:pos/presentation/pages/credit/credit_page.dart';
import 'package:pos/presentation/pages/order/create_order_page.dart';
import 'package:pos/presentation/pages/order/order_detail_page.dart';
import 'package:pos/presentation/pages/order/order_page.dart';
import 'package:pos/presentation/pages/payment/payment_page.dart';
import 'package:pos/presentation/pages/settings/settings_page.dart';
import 'package:pos/presentation/widgets/app_shell.dart';

abstract final class AppRoutes {
  static const order = '/';
  static const orderCreate = '/order/create';
  static const orderDetail = '/order/:orderId';
  static const credit = '/credit';
  static const report = '/report';
  static const settings = '/settings';
  static const businessDay = '/business-day';

  static String orderDetailPath(String orderId) => '/order/$orderId';
  static String orderPaymentPath(String orderId) => '/order/$orderId/payment';
}

class AppRouter {
  AppRouter({this.businessDayGuard});

  // null이면 가드 없이 항상 통과 — Riverpod provider 연결 후 활성화
  final String? Function(BuildContext, GoRouterState)? businessDayGuard;

  late final GoRouter router = GoRouter(
    initialLocation: AppRoutes.order,
    debugLogDiagnostics: false,
    redirect: _redirect,
    routes: [
      GoRoute(
        path: AppRoutes.businessDay,
        builder: (_, __) => const BusinessDayPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(
          location: state.uri.toString(),
          child: child,
        ),
        routes: [
          GoRoute(
            path: AppRoutes.order,
            builder: (_, __) => const OrderPage(),
            routes: [
              GoRoute(
                path: 'create',
                builder: (_, state) => CreateOrderPage(
                  seatId: state.uri.queryParameters['seatId'] ?? '',
                ),
              ),
              GoRoute(
                path: ':orderId',
                builder: (_, state) => OrderDetailPage(
                  orderId: state.pathParameters['orderId'] ?? '',
                ),
                routes: [
                  GoRoute(
                    path: 'payment',
                    builder: (_, state) => PaymentPage(
                      orderId: state.pathParameters['orderId'] ?? '',
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.credit,
            builder: (_, __) => const CreditPage(),
          ),
          GoRoute(
            path: AppRoutes.report,
            builder: (_, __) => const ReportPage(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (_, __) => const SettingsPage(),
          ),
        ],
      ),
    ],
  );

  String? _redirect(BuildContext context, GoRouterState state) {
    if (businessDayGuard == null) return null;
    if (state.uri.path == AppRoutes.businessDay) return null;
    return businessDayGuard!(context, state);
  }
}
