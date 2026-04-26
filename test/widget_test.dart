import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos/main.dart';

void main() {
  testWidgets('PosApp smoke test — app renders without crash', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: PosApp()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PosApp), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
    // TODO(Phase 3): stub provider 교체 시 ProviderScope(overrides: [...]) 패턴 추가 필요
  });
}
