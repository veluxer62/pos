<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-05-04 | Updated: 2026-05-04 -->

# test/

## Purpose
단위·위젯 테스트 모음. domain 레이어 UseCase 단위 테스트(mockito), data 레이어 DAO·Repository 통합 테스트(in-memory drift), presentation 레이어 위젯 테스트로 구성된다. TDD 필수 — 구현 전 테스트 먼저 작성(RED → GREEN).

## Subdirectories

| Directory | Purpose |
|-----------|---------|
| `domain/` | UseCase 단위 테스트 — mockito로 repository mock (see `domain/AGENTS.md`) |
| `data/` | DAO·Repository 통합 테스트 — `NativeDatabase.memory()` in-memory drift (see `data/AGENTS.md`) |
| `presentation/` | Widget·Page 테스트 (see `presentation/AGENTS.md`) |
| `core/` | router, utils 테스트 |
| `integration_test/` | 레거시 통합 테스트 디렉토리 (실제 통합 테스트는 루트 `integration_test/` 사용) |

## For AI Agents

### Working In This Directory
- mock DB 사용 금지 — data 레이어는 반드시 `NativeDatabase.memory()` 사용
- mockito mock 클래스는 `build_runner`로 생성: `dart run build_runner build --delete-conflicting-outputs`
- 각 테스트 파일은 대응하는 소스 파일과 동일한 경로 구조 유지

### Testing Requirements
```bash
flutter test                  # 전체 실행
flutter test --coverage       # 커버리지 리포트 (domain + data 80% 이상 필수)
flutter test test/domain/     # domain 레이어만
flutter test test/data/       # data 레이어만
```

### Common Patterns
- `setUp()`에서 in-memory DB 초기화, `tearDown()`에서 `db.close()` 호출
- UseCase 테스트: `@GenerateMocks([IXxxRepository])` 어노테이션 사용
- 영업일 의존 UseCase 테스트 시 mockRepository에 OPEN BusinessDay stub 필요

## Dependencies

### Internal
- `lib/` — 테스트 대상 소스

### External
- `mockito: ^5.4.4`
- `flutter_test` (Flutter SDK)

<!-- MANUAL: -->
