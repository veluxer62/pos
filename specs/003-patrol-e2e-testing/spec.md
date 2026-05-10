# Feature Specification: Patrol E2E Testing Integration

**Feature Branch**: `003-patrol-e2e-testing`
**Created**: 2026-05-10
**Status**: Draft
**Input**: Patrol 프레임워크를 이용한 에뮬레이터 자동 실행 환경에서의 E2E 제품 검증

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Patrol CLI로 에뮬레이터 자동 실행 및 E2E 테스트 수행 (Priority: P1)

개발자가 `patrol test` 명령 하나로 Android 에뮬레이터를 자동 시작하고, 전체 E2E 시나리오를 실행하여 제품 품질을 검증할 수 있어야 한다.

**Why this priority**: 현재 통합 테스트는 에뮬레이터를 수동으로 시작한 뒤 `flutter test integration_test/`를 실행해야 한다. Patrol 도입으로 에뮬레이터 관리까지 자동화하여 CI/CD 및 로컬 개발 검증 비용을 낮춘다.

**Independent Test**: `patrol test` 실행 시 에뮬레이터가 자동 시작되고 us1~us6 테스트 파일이 모두 통과한다.

**Acceptance Scenarios**:

1. **Given** Android 에뮬레이터가 꺼져 있음, **When** `patrol test` 실행, **Then** Patrol CLI가 AVD를 자동 부팅하고 전체 E2E 테스트를 실행하여 결과를 출력한다.
2. **Given** 에뮬레이터가 이미 실행 중, **When** `patrol test` 실행, **Then** 기존 에뮬레이터를 재사용하여 테스트를 실행한다.
3. **Given** 특정 테스트 파일만 실행 지정, **When** `patrol test integration_test/us1_order_flow_test.dart`, **Then** 해당 파일의 테스트만 에뮬레이터에서 실행된다.

---

### User Story 2 — 기존 integration_test 코드 Patrol 호환 (Priority: P2)

기존 us1~us6 통합 테스트 파일이 Patrol 환경에서도 실행되어야 한다. WidgetTester 기반 테스트 코드의 최소한의 수정만으로 Patrol과 호환되도록 한다.

**Independent Test**: 기존 테스트 파일 6개가 `patrol test` 명령으로 모두 통과한다.

**Acceptance Scenarios**:

1. **Given** 기존 us1~us6 테스트 파일 존재, **When** `patrol test` 실행, **Then** 모든 테스트가 에러 없이 통과한다.
2. **Given** Patrol 마이그레이션 완료, **When** `flutter test integration_test/` 실행, **Then** 기존 방식도 여전히 동작한다 (하위 호환성 유지).

---

### User Story 3 — patrol.toml 설정 파일로 에뮬레이터 타겟 관리 (Priority: P3)

`patrol.toml` 설정 파일에 AVD 이름, API 레벨, 디바이스 프로파일을 명시하여 팀원 누구나 동일한 환경에서 테스트를 실행할 수 있어야 한다.

**Independent Test**: `patrol.toml`에 `Pixel_Tablet_API_34` AVD 지정 후 `patrol test` 실행 시 해당 AVD로 테스트가 수행된다.

**Acceptance Scenarios**:

1. **Given** `patrol.toml`에 `app_id`, `android.package_name`, AVD 설정 존재, **When** `patrol test` 실행, **Then** 설정에 정의된 타겟 디바이스에서 테스트가 수행된다.

---

## Functional Requirements

- **FR-001** `patrol` 및 `patrol_cli` 패키지를 `pubspec.yaml`에 추가한다 (MUST)
- **FR-002** `patrol.toml` 설정 파일을 프로젝트 루트에 생성한다 (MUST)
- **FR-003** `AndroidManifest.xml`에 Patrol 실행에 필요한 권한 및 instrumentation 설정을 추가한다 (MUST)
- **FR-004** 기존 통합 테스트 파일이 Patrol 환경에서 실행 가능하도록 최소 수정한다 (MUST)
- **FR-005** `dart analyze` zero warnings를 유지한다 (MUST)
- **FR-006** `flutter test` (단위+위젯) 기존 336개 테스트가 계속 통과한다 (MUST)

---

## Non-Functional Requirements

- **NFR-001** `patrol test` 명령 실행 후 첫 테스트 시작까지 에뮬레이터 부팅 포함 5분 이내
- **NFR-002** 기존 테스트 코드 변경 최소화 (파일당 5줄 이하)
- **NFR-003** README에 Patrol 실행 방법 문서화

---

## Out of Scope (V1)

- iOS 시뮬레이터 자동화
- Firebase Test Lab 연동
- Patrol 네이티브 기능 (권한 다이얼로그, 알림) 활용
- CI/CD 파이프라인 통합 (GitHub Actions)
