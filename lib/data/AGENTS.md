<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-05-04 | Updated: 2026-05-04 -->

# lib/data/

## Purpose
데이터 접근 레이어. `local/`에 drift SQLite 구현체(DAO, repository 구현체, 데이터베이스 정의)가 있고, `remote/`는 백엔드 전환 시 HTTP 구현체 위치 (현재 stub). 백엔드 전환 시 `core/di/providers.dart`의 주입 대상만 교체하면 됨.

## Subdirectories

| Directory | Purpose |
|-----------|---------|
| `local/` | drift SQLite 구현체 (see `local/AGENTS.md`) |
| `remote/` | HTTP stub — 백엔드 전환 시 구현 위치 |

## For AI Agents

### Working In This Directory
- 테이블 정의(`tables.dart`) 변경 시 반드시 build_runner 재실행
- repository 구현체는 `IXxxRepository`를 구현하고 drift DAO를 사용
- 원자적 트랜잭션 필수:
  - 영업 마감 + DailySalesReport 생성: `drift transaction()` 블록
  - 외상 발생 + Order 상태 변경: 동일 트랜잭션
  - 외상 납부 + CreditAccount balance 업데이트: 동일 트랜잭션

### Testing Requirements
- `test/data/` — `NativeDatabase.memory()` in-memory drift 사용 (mock DB 금지)

### Common Patterns
- DAO: `@DriftAccessor(tables: [...])` 어노테이션
- Repository 구현체: `class LocalXxxRepository implements IXxxRepository`

## Dependencies

### Internal
- `lib/domain/` — repository interface, entities

### External
- `drift: ^2.20.3`
- `sqlite3_flutter_libs`
- `path_provider`, `path`

<!-- MANUAL: -->
