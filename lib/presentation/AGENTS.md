<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-05-04 | Updated: 2026-05-04 -->

# lib/presentation/

## Purpose
Flutter UI 레이어. 테마 토큰, 재사용 위젯, 기능별 페이지, Riverpod 상태 provider로 구성된다. 디자인 토큰(`AppColors`, `AppSpacing`, `AppTypography`)을 사용하고 raw hex/pixel 값 금지.

## Subdirectories

| Directory | Purpose |
|-----------|---------|
| `theme/` | 디자인 토큰 및 MaterialTheme 설정 |
| `widgets/` | 앱 전체 공용 재사용 위젯 |
| `pages/` | 기능별 페이지 및 하위 위젯 (see `pages/AGENTS.md`) |
| `providers/` | Riverpod AsyncNotifier 기반 상태 provider |

## Key Files

| File | Description |
|------|-------------|
| `theme/app_colors.dart` | 컬러 토큰 |
| `theme/app_spacing.dart` | 여백·크기 토큰 |
| `theme/app_typography.dart` | 타이포그래피 토큰 |
| `theme/app_theme.dart` | MaterialTheme 조합 |
| `widgets/app_button.dart` | 공용 버튼 컴포넌트 |
| `widgets/app_error_widget.dart` | 에러 표시 위젯 |
| `widgets/app_shell.dart` | 앱 전체 쉘 레이아웃 |
| `widgets/app_snack_bar.dart` | 스낵바 유틸리티 |
| `widgets/confirm_dialog.dart` | 확인 다이얼로그 |
| `providers/order_providers.dart` | 주문 상태 provider |
| `providers/business_day_providers.dart` | 영업일 상태 provider |
| `providers/credit_account_providers.dart` | 외상 계정 상태 provider |
| `providers/settings_providers.dart` | 메뉴·좌석 설정 provider |

## For AI Agents

### Working In This Directory
- 디자인 토큰만 사용 — `AppColors.primary` 사용, `Color(0xFF...)` 직접 사용 금지
- 버튼 최소 터치 영역 48dp, `Semantics` 위젯 적용 (접근성)
- provider 파일 수정 시 build_runner 재실행 필요 (`*.g.dart` 재생성)
- 상태: `@riverpod` 어노테이션 + `AsyncNotifier` 패턴

### Testing Requirements
- `test/presentation/` 에 widget 테스트
- `flutter test test/presentation/`

### Common Patterns
```dart
// AsyncNotifier 패턴
@riverpod
class OrderNotifier extends _$OrderNotifier {
  @override
  Future<List<Order>> build() async { ... }
}
```

## Dependencies

### Internal
- `lib/domain/usecases/` — UseCase 호출
- `lib/core/` — DI, router, formatters

### External
- `flutter_riverpod`, `riverpod_annotation`
- `go_router`

<!-- MANUAL: -->
