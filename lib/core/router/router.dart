import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/presentation/pages/business_day/business_day_page.dart';
import 'package:pos/presentation/pages/business_day/daily_sales_report_page.dart';
import 'package:pos/presentation/pages/business_day/report_page.dart';
import 'package:pos/presentation/pages/business_day/sales_history_page.dart';
import 'package:pos/presentation/pages/credit/credit_account_detail_page.dart';
import 'package:pos/presentation/pages/credit/credit_account_list_page.dart';
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
  static const creditDetail = '/credit/:accountId';
  static const report = '/report';
  static const salesHistory = '/history';
  static const settings = '/settings';
  static const businessDay = '/business-day';
  static const businessDayReport = '/business-day/:businessDayId/report';

  static String creditDetailPath(String accountId) => '/credit/$accountId';
  static String orderDetailPath(String orderId) => '/order/$orderId';
  static String orderPaymentPath(String orderId) => '/order/$orderId/payment';
  static String businessDayReportPath(String businessDayId) =>
      '/business-day/$businessDayId/report';
}

class AppRouter {
  AppRouter({this.businessDayGuard});

  // null이면 가드 없이 항상 통과
  final String? Function(BuildContext, GoRouterState)? businessDayGuard;

  late final GoRouter router = GoRouter(
    initialLocation: AppRoutes.order,
    debugLogDiagnostics: false,
    redirect: _redirect,
    routes: [
      GoRoute(
        path: AppRoutes.businessDay,
        builder: (_, __) => const BusinessDayPage(),
        routes: [
          GoRoute(
            path: ':businessDayId/report',
            builder: (_, state) => DailySalesReportPage(
              businessDayId: state.pathParameters['businessDayId'] ?? '',
            ),
          ),
        ],
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
            builder: (_, __) => const CreditAccountListPage(),
            routes: [
              GoRoute(
                path: ':accountId',
                builder: (_, state) => CreditAccountDetailPage(
                  accountId: state.pathParameters['accountId'] ?? '',
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.report,
            builder: (_, __) => const ReportPage(),
          ),
          GoRoute(
            path: AppRoutes.salesHistory,
            builder: (_, __) => const SalesHistoryPage(),
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
    // businessDay 관련 경로는 가드에서 제외 (무한 루프 방지)
    if (state.uri.path.startsWith(AppRoutes.businessDay)) return null;
    return businessDayGuard!(context, state);
  }
}
