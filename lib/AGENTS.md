<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-05-04 | Updated: 2026-05-04 -->

# lib/

## Purpose
Flutter 앱 소스코드 루트. Clean Architecture 3계층(domain → data → presentation)으로 구성되며, `core/`에 DI·라우터·유틸리티를 둔다. **domain 레이어는 Flutter·drift에 의존하지 않는다.**

## Key Files

| File | Description |
|------|-------------|
| `main.dart` | 앱 진입점 — `ProviderScope` + `GoRouter` 초기화 |

## Subdirectories

| Directory | Purpose |
|-----------|---------|
| `core/` | DI(Riverpod providers), go_router 설정, 유틸리티 (see `core/AGENTS.md`) |
| `domain/` | 순수 Dart — entities, repositories(abstract), usecases, value_objects, exceptions (see `domain/AGENTS.md`) |
| `data/` | drift SQLite 구현체 및 remote stub (see `data/AGENTS.md`) |
| `presentation/` | Flutter UI — theme, widgets, pages, providers (see `presentation/AGENTS.md`) |

## For AI Agents

### Working In This Directory
- 의존성 방향: `presentation` → `domain` ← `data`, `core`는 모두에서 사용
- 새 기능 추가 시: domain 레이어 먼저(entity → repository interface → usecase), 그 다음 data → presentation 순서
- `domain/`에 Flutter import 절대 금지

### Testing Requirements
- UseCase 테스트: `test/domain/usecases/` — mockito repository mock
- DAO·Repository 테스트: `test/data/` — `NativeDatabase.memory()` in-memory drift

### Common Patterns
- 레이어 간 이동은 repository interface를 통해서만
- 주문 생성·상태 변경 전 OPEN 영업일 확인 필수 (`IBusinessDayRepository.getOpen()`)

## Dependencies

### External
- `drift` — data 레이어 전용
- `flutter_riverpod` — presentation + core 레이어

<!-- MANUAL: -->
