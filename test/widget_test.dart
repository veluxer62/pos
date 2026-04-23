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
    expect(find.byType(PosApp), findsOneWidget);
    expect(find.text('POS App'), findsOneWidget);
  });
}
