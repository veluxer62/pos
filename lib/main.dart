import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos/core/di/providers.dart';
import 'package:pos/core/utils/dev_seed.dart';
import 'package:pos/data/local/database/app_database.dart';
import 'package:pos/presentation/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase();
  if (kDebugMode) {
    await seedDevData(db);
  }
  runApp(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: const PosApp(),
    ),
  );
}

class PosApp extends ConsumerWidget {
  const PosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider).router;
    return MaterialApp.router(
      title: 'POS',
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
