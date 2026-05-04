<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-05-04 | Updated: 2026-05-04 -->

# test/presentation/

## Purpose
Flutter 위젯·페이지 테스트. Riverpod provider를 override하여 UI 동작을 검증한다.

## Subdirectories

| Directory | Purpose |
|-----------|---------|
| `pages/` | 기능별 페이지 위젯 테스트 |
| `widgets/` | 공용 위젯 단위 테스트 |

## For AI Agents

### Working In This Directory
- `ProviderScope(overrides: [...])` 로 provider mock 주입
- `tester.pumpWidget()` 후 `tester.pump()` 또는 `tester.pumpAndSettle()` 으로 비동기 처리
- 접근성 검증: `tester.getSemantics()` 활용

### Common Patterns
```dart
testWidgets('order page shows seats', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [seatProvider.overrideWith((_) => mockSeats)],
      child: const MaterialApp(home: SeatGridPage()),
    ),
  );
  await tester.pumpAndSettle();
  expect(find.text('1번 테이블'), findsOneWidget);
});
```

<!-- MANUAL: -->
