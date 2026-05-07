import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pos/core/di/providers.dart';
import 'package:pos/domain/usecases/export_data_use_case.dart';
import 'package:pos/presentation/pages/settings/menu_item_list_page.dart';
import 'package:pos/presentation/pages/settings/seat_list_page.dart';
import 'package:pos/presentation/theme/app_colors.dart';
import 'package:pos/presentation/theme/app_typography.dart';
import 'package:share_plus/share_plus.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => DefaultTabController(
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
            actions: [
              IconButton(
                icon: const Icon(Icons.upload_file),
                tooltip: '데이터 내보내기',
                onPressed: () => _exportData(context, ref),
              ),
            ],
          ),
          body: const TabBarView(
            children: [
              MenuItemListPage(),
              SeatListPage(),
            ],
          ),
        ),
      );

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    try {
      final useCase = ExportDataUseCase(
        businessDayRepository: ref.read(businessDayRepositoryProvider),
        orderRepository: ref.read(orderRepositoryProvider),
        creditAccountRepository: ref.read(creditAccountRepositoryProvider),
      );

      final dir = await getTemporaryDirectory();
      final path = await useCase.execute(dir.path);

      await Share.shareXFiles([XFile(path)]);
    } on Exception catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('내보내기 실패: $e')),
        );
      }
    }
  }
}
