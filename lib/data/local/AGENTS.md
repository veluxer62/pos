<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-05-04 | Updated: 2026-05-04 -->

# lib/data/local/

## Purpose
drift SQLite 기반 로컬 데이터 접근 구현체. 데이터베이스 정의, DAO(Data Access Object), repository 구현체로 구성된다.

## Subdirectories

| Directory | Purpose |
|-----------|---------|
| `database/` | drift AppDatabase, 테이블 정의, 마이그레이션 |
| `daos/` | 기능별 DAO — drift 쿼리 메서드 |
| `repositories/` | `IXxxRepository` 구현체 — DAO를 감싸는 repository |

## For AI Agents

### Working In This Directory
- 테이블 정의(`tables.dart`) 변경 시 반드시 build_runner 재실행:
  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```
- `*.g.dart` 파일은 자동 생성 — 직접 수정 금지
- 원자적 트랜잭션은 `db.transaction(() async { ... })` 블록 사용

### Testing Requirements
- `test/data/` — `NativeDatabase.memory()` in-memory drift (mock DB 절대 금지)

### Common Patterns
- UUID는 `UuidTextConverter`로 TEXT 저장
- Enum은 `TextColumn + textEnum<>()` TEXT 저장
- 날짜/시간: `DateTimeColumn` (내부 INTEGER milliseconds)
- 금액: `IntColumn` KRW 원 단위 정수

## Dependencies

### Internal
- `lib/domain/` — entities, repository interfaces

### External
- `drift: ^2.20.3`
- `sqlite3_flutter_libs`
- `path_provider`, `path`

<!-- MANUAL: -->
