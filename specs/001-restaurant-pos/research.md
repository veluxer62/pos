# Research: Restaurant POS App

**Phase**: 0 — Outline & Research
**Date**: 2026-04-19 (updated)
**Input**: spec.md (35 FRs, 5 user stories), plan.md Technical Context (Flutter + local storage)

---

## 1. 플랫폼 및 언어

### 1.1 Flutter + Dart

**Decision**: Flutter 3.x (stable channel), Dart 3.x

**Rationale**:
- 단일 코드베이스로 Android/iOS 태블릿 동시 지원 — POS 기기 선택 유연성 확보
- Dart 강타입 + null safety는 Constitution I(Code Quality) 요건 충족
- Flutter의 렌더링 아키텍처(Skia/Impeller)는 화면 전환 60fps 보장, 300ms 전환 SC 달성 용이
- Hot reload로 빠른 개발 사이클

**Alternatives considered**:
- React Native: JavaScript 기반, 타입 안전성이 TypeScript에 의존, 브릿지 성능 우려
- Swift/Kotlin native: 플랫폼 각각 개발 필요, 유지비용 2배
- Web PWA: 오프라인 우선 + 태블릿 최적화에 네이티브 대비 제약

---

## 2. 로컬 저장소

### 2.1 SQLite ORM: drift

**Decision**: drift 2.x (구 moor)

**Rationale**:
- Dart 코드로 타입 안전한 테이블·쿼리 정의 → 컴파일 타임 오류 탐지
- 복잡한 집계 쿼리(보고서 FR-028~029) 지원: `groupBy`, `sum`, `orderBy`
- 마이그레이션 API(`MigrationStrategy`)로 앱 업데이트 시 스키마 변경 안전하게 처리
- `Stream` 기반 쿼리 → 데이터 변경 시 UI 자동 갱신 (Riverpod과 조합 용이)
- 테스트 시 `NativeDatabase.memory()`로 in-memory DB 사용 가능

**Alternatives considered**:
- `sqflite`: 로우레벨 SQL 직접 작성, 타입 안전성 없음, 보고서 쿼리 복잡도 증가
- `isar`: NoSQL, 집계 쿼리 표현력 부족, 재무 데이터의 ACID 트랜잭션 처리 약함
- `ObjectBox`: 빠르지만 SQL 쿼리 불가, 보고서 집계 지원 제한

### 2.2 추상화 전략: Repository 패턴

**Decision**: `abstract interface class IXxxRepository` + `LocalXxxRepository` 구현체

**Rationale**:
- `domain/repositories/` 레이어는 순수 Dart — Flutter·drift에 의존하지 않음
- `LocalXxxRepository`는 drift DAO를 주입받아 구현
- 백엔드 전환 시: `RemoteXxxRepository` 추가 → `core/di/`에서 주입 대상 교체 (단 1곳 수정)
- 단위 테스트에서 `MockXxxRepository` (mockito 생성)로 use case 독립 테스트

```
IOrderRepository (abstract)
    ├── LocalOrderRepository (drift SQLite) ← 현재
    └── RemoteOrderRepository (HTTP)        ← 백엔드 전환 시
```

---

## 3. 상태 관리 및 DI

### 3.1 Riverpod 2.x (flutter_riverpod)

**Decision**: Riverpod 2.x (code generation 활성화)

**Rationale**:
- Provider → Repository → UseCase → State의 의존성 그래프를 선언적으로 표현
- `@riverpod` 어노테이션으로 보일러플레이트 최소화
- 백엔드 전환 시 Repository provider만 교체하면 전체 의존성 그래프가 자동 전파
- `AsyncNotifier`로 비동기 상태(주문 생성, 보고서 생성) 일관되게 처리
- 테스트에서 `ProviderContainer` + override로 mock 주입 용이

**Alternatives considered**:
- BLoC: 보일러플레이트 과다, 이 규모에서 오버킬
- Provider (기존): Riverpod의 단점(context 의존)을 해결한 버전이 Riverpod이므로 Riverpod 선택
- GetX: opinionated, 테스트 가이드라인 약함

---

## 4. 라우팅

### 4.1 go_router

**Decision**: go_router 13.x

**Rationale**:
- Flutter 공식 권장 라우터, URL 기반 선언적 라우팅
- 딥링크·중첩 네비게이션·가드(영업 중 여부 체크) 지원
- Riverpod과 통합 용이 (`ref.watch`로 라우트 가드 조건 처리)

---

## 5. 주문 상태 머신

**Decision**: 순수 Dart sealed class + extension method

**Rationale**:
- Dart 3의 `sealed class OrderStatus` + `switch` exhaustive 검사 → 컴파일 타임 전이 안전성
- 별도 라이브러리 불필요

```dart
sealed class OrderStatus { ... }
class Pending extends OrderStatus { ... }
class Delivered extends OrderStatus { ... }
class Paid extends OrderStatus { ... }
class Credited extends OrderStatus { ... }
class Cancelled extends OrderStatus { ... }
class Refunded extends OrderStatus { ... }
```

`canDeliver()`, `canPay()`, `canCredit()`, `canCancel()` 메서드로 전이 유효성 검사.

---

## 6. 디자인 시스템 (Constitution III)

**Decision**: `AppTheme` 중앙 집중식 디자인 토큰

**Rationale**:
- `AppColors`, `AppSpacing`, `AppTypography` 클래스에 모든 색상·간격·폰트 상수 정의
- 컴포넌트에서 raw hex/pixel 값 사용 금지 → `dart analyze` custom lint로 강제
- 태블릿 가로 레이아웃: 좌측 패널(좌석/메뉴) + 우측 패널(주문 내역) 분할 레이아웃
- 접근성: `Semantics` 위젯으로 스크린 리더 지원, 버튼 최소 터치 영역 48dp 이상

---

## 7. 테스트 전략

**Decision**: 3계층 테스트 (Unit > Widget > Integration)

| 레이어 | 도구 | 범위 |
|--------|------|------|
| 단위 | flutter_test + mockito | UseCase, Entity, 상태 머신, 금액 계산 |
| 위젯 | flutter_test (WidgetTester) | 개별 화면·컴포넌트 렌더링·상호작용 |
| 통합 | integration_test | 주요 사용자 시나리오 전 흐름 (실기기/에뮬레이터) |
| DB 통합 | flutter_test + drift in-memory | DAO·Repository 실제 SQLite 동작 검증 |

- **Constitution II**: DB 통합 테스트는 `NativeDatabase.memory()` 사용 (mock DB 금지)
- **TDD**: UseCase 메서드·DAO 쿼리는 테스트 먼저 작성 후 실패 확인 후 구현
- **Coverage**: `flutter test --coverage`, domain + data 레이어 80% 이상

---

## 8. CI

**Decision**: GitHub Actions

```
PR → dart analyze (zero warnings) → dart format --check → flutter test --coverage
   → integration_test (Android 에뮬레이터) → coverage gate (80%)
```

- `flutter pub audit` zero critical
- 빌드 크기 변화 10% 초과 시 PR 코멘트 경고

---

## 9. 백엔드 전환 경로 (향후)

백엔드 연동 시 필요한 변경 목록:

1. `data/remote/repositories/Remote*Repository` 구현체 추가 (Dio HTTP 클라이언트 사용)
2. `core/di/`에서 provider override: `LocalXxxRepository` → `RemoteXxxRepository`
3. drift 로컬 DB는 캐시 레이어로 전환하거나 제거
4. domain/use case 레이어 변경 없음
5. presentation 레이어 변경 없음

---

## 10. 해결된 NEEDS CLARIFICATION

| 항목 | 결정 |
|------|------|
| 플랫폼 | Flutter (Android/iOS 태블릿) |
| 저장소 | drift SQLite (로컬 우선, 백엔드 추후) |
| 추상화 | Repository 인터페이스 패턴, DI via Riverpod |
| 상태 관리 | Riverpod 2.x |
| 결제 수단 처리 | 외부 게이트웨이 없음, 점주 수동 확인 (즉시/외상 선택) |
| 영업일 구분 | 수동 시작/마감 페어 |
| 오프라인 동작 | 항상 로컬 (오프라인 문제 자체가 없음) |
| 보고서 집계 | drift 집계 쿼리 + 마감 시 스냅샷 저장 |
