import 'package:flutter/material.dart';
import 'package:pos/presentation/pages/settings/menu_item_list_page.dart';
import 'package:pos/presentation/pages/settings/seat_list_page.dart';
import 'package:pos/presentation/theme/app_colors.dart';
import 'package:pos/presentation/theme/app_typography.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('설정', style: AppTypography.appBarTitle),
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            bottom: const TabBar(
              tabs: [
                Tab(text: '메뉴 관리'),
                Tab(text: '좌석 관리'),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              MenuItemListPage(),
              SeatListPage(),
            ],
          ),
        ),
      );
}
