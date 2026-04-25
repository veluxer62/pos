import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/core/router/router.dart';
import 'package:pos/presentation/theme/app_spacing.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    required this.child,
    required this.location,
    super.key,
  });

  final Widget child;
  final String location;

  static const _destinations = [
    _Destination(
      route: AppRoutes.order,
      icon: Icons.table_restaurant_outlined,
      selectedIcon: Icons.table_restaurant,
      label: '주문 현황',
    ),
    _Destination(
      route: AppRoutes.credit,
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet,
      label: '외상 장부',
    ),
    _Destination(
      route: AppRoutes.report,
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart,
      label: '매출 보고서',
    ),
    _Destination(
      route: AppRoutes.settings,
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: '설정',
    ),
  ];

  int get _selectedIndex {
    final idx = _destinations.indexWhere((d) => location == d.route);
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: true,
            selectedIndex: _selectedIndex,
            destinations: _destinations
                .map(
                  (d) => NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.label),
                  ),
                )
                .toList(),
            onDestinationSelected: (index) =>
                context.go(_destinations[index].route),
          ),
          const VerticalDivider(
            thickness: AppSpacing.borderWidth,
            width: AppSpacing.borderWidth,
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _Destination {
  const _Destination({
    required this.route,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final String route;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
