<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-05-04 | Updated: 2026-05-04 -->

# integration_test/

## Purpose
전체 앱 시나리오를 에뮬레이터 또는 실기기에서 실행하는 통합 테스트. US1~US5 사용자 스토리 흐름을 end-to-end로 검증한다.

## Key Files

| File | Description |
|------|-------------|
| `app_test.dart` | 전체 앱 시나리오 통합 테스트 진입점 |

## For AI Agents

### Working In This Directory
- 실행 시 에뮬레이터 또는 실기기 필요: `flutter test integration_test/`
- in-memory DB 아닌 실제 SQLite를 사용하므로 테스트 간 상태 격리 주의
- 영업일 OPEN 상태 선제 설정 후 주문 흐름 테스트

### Testing Requirements
```bash
flutter test integration_test/  # 에뮬레이터/실기기 연결 필수
```

### Common Patterns
- `IntegrationTestWidgetsFlutterBinding.ensureInitialized()` 호출 필수
- 각 테스트는 독립적 DB 상태에서 시작

## Dependencies

### Internal
- `lib/` — 전체 앱 소스 (실제 구현체 사용)

### External
- `integration_test` (Flutter SDK)

<!-- MANUAL: -->
