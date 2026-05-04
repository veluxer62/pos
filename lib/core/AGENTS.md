<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-05-04 | Updated: 2026-05-04 -->

# lib/core/

## Purpose
앱 전체에서 공유되는 인프라 코드. DI(Riverpod provider 등록), 라우팅(go_router), 유틸리티(통화·날짜 포맷터, 개발용 시드 데이터).

## Subdirectories

| Directory | Purpose |
|-----------|---------|
| `di/` | Riverpod provider 등록 — repository 주입 대상 정의 |
| `router/` | go_router 라우트 설정 |
| `utils/` | 유틸리티 함수 (CurrencyFormatter, DateFormatter, DevSeed) |

## Key Files

| File | Description |
|------|-------------|
| `di/providers.dart` | 모든 repository provider 등록 — 백엔드 전환 시 이 파일만 수정 |
| `di/providers.g.dart` | 코드 생성 파일 (build_runner 자동 생성) |
| `router/router.dart` | go_router 라우트 정의 |
| `utils/currency_formatter.dart` | KRW 원 단위 정수 → 표시용 문자열 변환 |
| `utils/date_formatter.dart` | 날짜 포맷 유틸리티 |
| `utils/dev_seed.dart` | 개발/테스트용 시드 데이터 생성 |

## For AI Agents

### Working In This Directory
- `di/providers.dart` 수정 시 build_runner 재실행 필요
- 백엔드 전환: `LocalXxxRepository` → `RemoteXxxRepository`로 교체 (이 파일만)
- 금액 표시는 항상 `CurrencyFormatter` 사용 — raw 숫자 표시 금지

### Testing Requirements
- `test/core/` 에 router, utils 테스트 위치

### Common Patterns
```dart
// DI provider 패턴
@riverpod
IOrderRepository orderRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return LocalOrderRepository(db.orderDao);
}
```

## Dependencies

### Internal
- `lib/data/local/` — LocalXxxRepository 구현체
- `lib/domain/repositories/` — IXxxRepository 인터페이스

### External
- `flutter_riverpod`, `riverpod_annotation`
- `go_router`

<!-- MANUAL: -->
