---
description: "Task list for Patrol E2E Testing Integration"
---

# Tasks: Patrol E2E Testing Integration (003-patrol-e2e-testing)

**Input**: Design documents from `/specs/003-patrol-e2e-testing/`
**Branch**: `003-patrol-e2e-testing`
**Plan**: [plan.md](./plan.md) | **Spec**: [spec.md](./spec.md)

## Format: `[ID] [P?] [Story] Description`

- **[P]**: 병렬 실행 가능 (다른 파일, 완료된 선행 작업 없음)
- **[US1~US3]**: 해당 User Story 소속 태스크
- 각 태스크에 정확한 파일 경로 포함

---

## Phase 1: Setup — 패키지 의존성 및 Android 설정

**Purpose**: patrol 의존성 추가 및 Android 네이티브 실행 환경 구성

- [x] T001 `pubspec.yaml` 수정 — `dev_dependencies`에 `patrol: ^4.5.0` 추가
- [x] T002 `pubspec.yaml` 수정 — 파일 맨 아래에 `patrol:` 설정 섹션 추가 (`app_name: POS`, `test_directory: integration_test`, `android.package_name: com.example.pos`, `ios.bundle_id: com.example.pos`)
- [x] T003 `flutter pub get` 실행 — patrol 의존성 설치 확인
- [x] T004 `android/app/build.gradle.kts` 수정 — `defaultConfig`에 `testInstrumentationRunner = "pl.leancode.patrol.PatrolJUnitRunner"` 및 `testInstrumentationRunnerArguments["clearPackageData"] = "true"` 추가; `android {}` 블록에 `testOptions { execution = "ANDROIDX_TEST_ORCHESTRATOR" }` 추가; `dependencies { androidTestUtil("androidx.test:orchestrator:1.5.1") }` 블록 추가
- [x] T005 `android/app/src/androidTest/java/com/example/pos/MainActivityTest.java` 신규 생성 — `PatrolJUnitRunner` 기반 parameterized 테스트 실행기 (패키지명 `com.example.pos`)

**Checkpoint**: `flutter pub get` 성공, `dart analyze` zero warnings 유지

---

## Phase 2: User Story 1 — Patrol CLI 실행 자동화 (Priority: P1)

**Goal**: `scripts/run_patrol_tests.sh` 한 줄 실행으로 에뮬레이터 시작 → patrol test 완료

**Independent Test**: `./scripts/run_patrol_tests.sh` 실행 시 에뮬레이터 자동 시작 후 E2E 테스트 결과 출력

- [x] T006 [US1] `scripts/run_patrol_tests.sh` 신규 생성 — AVD 이름(기본: `Pixel_Tablet_API_34`)과 테스트 타겟(기본: `integration_test/`)을 인자로 받아 `flutter emulators --launch`, `adb wait-for-device`, `patrol test --target` 순서로 실행하는 bash 스크립트; `chmod +x scripts/run_patrol_tests.sh` 실행

**Checkpoint**: 스크립트 파일 존재 및 실행 권한 확인

---

## Phase 3: User Story 2 — integration_test E2E 파일 Patrol 마이그레이션 (Priority: P2)

**Goal**: `integration_test/` 6개 파일을 `patrolTest` 형식으로 변환, `flutter test`(단위+위젯 336개) 기존 통과 유지

**Independent Test**: `patrol test --target integration_test/us1_order_flow_test.dart` 통과

**변경 패턴** (각 파일 동일):
1. `import 'package:integration_test/integration_test.dart';` → `import 'package:patrol/patrol.dart';`
2. `IntegrationTestWidgetsFlutterBinding.ensureInitialized();` 줄 제거
3. `testWidgets('설명', (tester) async {` → `patrolTest('설명', ($) async {`
4. 테스트 클로저 내 `tester.` → `$.tester.`, 헬퍼 호출 `pumpApp(tester)` → `pumpApp($.tester)` 등 교체

- [x] T007 [P] [US2] `integration_test/us1_order_flow_test.dart` 마이그레이션 — import 교체, `ensureInitialized()` 제거, `testWidgets`→`patrolTest`, `tester`→`$.tester` 전체 교체; 로컬 헬퍼 `pumpApp(WidgetTester tester)`, `goToSeatGrid(WidgetTester tester)` 시그니처 유지하되 호출 시 `$.tester` 전달
- [x] T008 [P] [US2] `integration_test/us2_payment_flow_test.dart` 마이그레이션 — 동일 패턴; `pumpApp`, `navigateToPaymentPage` 헬퍼 호출 시 `$.tester` 전달
- [x] T009 [P] [US2] `integration_test/us3_credit_account_flow_test.dart` 마이그레이션 — 동일 패턴; `pumpApp`, `goToCreditTab` 헬퍼 호출 시 `$.tester` 전달
- [x] T010 [P] [US2] `integration_test/us4_settings_flow_test.dart` 마이그레이션 — 동일 패턴; `pumpApp`, `goToSettingsTab` 헬퍼 호출 시 `$.tester` 전달
- [x] T011 [P] [US2] `integration_test/us5_report_flow_test.dart` 마이그레이션 — 동일 패턴; `pumpApp` 헬퍼 호출 시 `$.tester` 전달
- [x] T012 [P] [US2] `integration_test/us6_multi_order_flow_test.dart` 마이그레이션 — 동일 패턴; `pumpApp` 헬퍼 호출 시 `$.tester` 전달

**Checkpoint**: `flutter test` 기존 336개 단위+위젯 테스트 계속 통과

---

## Phase 4: User Story 3 — 문서화 (Priority: P3)

**Goal**: README에 Patrol 설치 및 실행 방법 추가

**Independent Test**: README.md에 `patrol_cli` 설치, `patrol doctor`, `./scripts/run_patrol_tests.sh` 실행 방법이 문서화됨

- [x] T013 [US3] `README.md` 수정 — `## 테스트` 섹션에 `### Patrol E2E 테스트 (에뮬레이터 자동화)` 서브섹션 추가: `dart pub global activate patrol_cli` 설치 명령, `patrol doctor` 진단, `./scripts/run_patrol_tests.sh` 전체 실행, 단일 파일 실행 예시 포함

**Checkpoint**: README.md에 Patrol 실행 방법 확인

---

## Phase 5: Polish & Quality Gate

**Purpose**: 전체 검증 및 zero warnings 확인

- [x] T014 `dart analyze` 실행 — zero warnings 확인; 발견된 경고 즉시 수정
- [x] T015 `flutter test` 실행 — 기존 단위+위젯 336개 테스트 전체 통과 확인

---

## Dependencies (완료 순서)

```
T001 → T002 → T003 (pubspec 설정)
T004, T005 (Android 설정, T003 완료 후)
  ↓
T006 (US1 스크립트, Setup 완료 후)
  ↓
T007~T012 [P] (US2 마이그레이션, Setup 완료 후 — 6개 파일 병렬 실행 가능)
  ↓
T013 (US3 문서화, 마이그레이션 완료 후)
  ↓
T014, T015 (Polish)
```

**병렬 실행 기회**:
- T004, T005 (Android 설정): T003 완료 후 동시 실행 가능
- T006, T007~T012: T004~T005 완료 후 동시 실행 가능
- T007~T012 (마이그레이션 6개 파일): 모두 독립 파일 — 동시 실행 가능

---

## 구현 전략

**MVP**: T001~T006 (Setup + 실행 스크립트)만으로도 `patrol test` 명령 실행 환경 구성 완료

**단계별 증분 전달**:
1. Setup (T001~T005): Android 환경 구성 — `patrol doctor` 통과
2. US1 (T006): 실행 스크립트 — `./scripts/run_patrol_tests.sh` 실행 가능
3. US2 (T007~T012): 마이그레이션 — `patrol test` 실제 통과
4. US3 (T013): 문서화
5. Polish (T014~T015): 검증

**총 태스크 수**: 15개 (T001~T015)

| Phase | US | 태스크 수 | 병렬 가능 |
|-------|----|----------|----------|
| Setup | - | 5 | 2 |
| 실행 자동화 | US1 | 1 | - |
| 마이그레이션 | US2 | 6 | 6 |
| 문서화 | US3 | 1 | - |
| Polish | - | 2 | - |
