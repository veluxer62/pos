import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos/core/di/providers.dart';
import 'package:pos/presentation/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: PosApp()));
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
