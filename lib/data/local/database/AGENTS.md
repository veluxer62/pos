<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-05-04 | Updated: 2026-05-04 -->

# lib/data/local/database/

## Purpose
drift `AppDatabase` 정의 및 테이블 스키마. 앱의 모든 SQLite 테이블이 여기서 정의된다.

## Key Files

| File | Description |
|------|-------------|
| `tables.dart` | 모든 drift 테이블 클래스 정의 (스키마 정의) |
| `app_database.dart` | `AppDatabase` — drift `@DriftDatabase` 선언, DAO 등록, 마이그레이션 |
| `app_database.g.dart` | build_runner 자동 생성 파일 (직접 수정 금지) |

## For AI Agents

### Working In This Directory
- `tables.dart` 수정(컬럼 추가/변경/삭제) 시 반드시 build_runner 재실행 및 마이그레이션 버전 올리기
- `app_database.dart`의 `schemaVersion` 변경 시 `MigrationStrategy` 업데이트 필수
- Enum 컬럼: `TextColumn + textEnum<MyEnum>()` 패턴 사용
- UUID 컬럼: `TextColumn + map(const UuidTextConverter())` 패턴

### Testing Requirements
- `test/data/` 에서 `NativeDatabase.memory()`로 테이블 생성 후 DAO 테스트

### Common Patterns
```dart
// 테이블 정의 패턴
class Orders extends Table {
  TextColumn get id => text().map(const UuidTextConverter())();
  TextColumn get status => textEnum<OrderStatus>()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get totalAmount => integer()();
}
```

## Dependencies

### External
- `drift`
- `uuid`

<!-- MANUAL: -->
