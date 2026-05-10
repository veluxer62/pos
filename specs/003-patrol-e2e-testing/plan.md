# Implementation Plan: Patrol E2E Testing Integration

**Branch**: `003-patrol-e2e-testing` | **Date**: 2026-05-10 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `specs/003-patrol-e2e-testing/spec.md`

---

## Summary

Patrol 4.x를 Flutter POS 앱에 통합하여 Android 에뮬레이터에서 E2E 테스트를 자동 실행한다. 기존 `integration_test/` 6개 파일을 `patrolTest` 형식으로 마이그레이션하고, 편의 실행 스크립트와 `pubspec.yaml` 설정을 추가한다. `flutter test`(단위+위젯 336개) 기존 통과는 그대로 유지한다.

---

## Technical Context

**Language/Version**: Dart 3.x, Flutter 3.41.7
**Primary Dependencies**:
- patrol `^4.5.0` (dev)
- patrol_cli `^4.3.1` (global install)
- androidx.test:orchestrator `1.5.1` (android)

**Storage**: 기존 `NativeDatabase.memory()` 인-메모리 drift — 변경 없음
**Testing**: patrol_cli `patrol test`, 하위호환 `flutter test integration_test/`
**Target Platform**: Android 에뮬레이터 (Pixel_Tablet_API_34), API 34
**Package Name**: `com.example.pos`
**Performance Goals**: 에뮬레이터 부팅 포함 전체 E2E 완료 5분 이내
**Constraints**:
- patrol 4.x에서 `test_directory: integration_test` 명시 필수 (기본값이 `patrol_test/`로 변경됨)
- `IntegrationTestWidgetsFlutterBinding.ensureInitialized()` → patrol이 자체 초기화하므로 제거
- native 기능(`$.native.*`) 미사용 → `flutter test`로도 실행 가능(noop)

---

## Constitution Check

| Gate | Status | Notes |
|------|--------|-------|
| I. Code Quality — No hardcoded values | ✅ PASS | patrol 설정은 pubspec.yaml에서 관리 |
| I. Code Quality — Dependency hygiene | ✅ PASS | patrol은 LeanCode에서 활발히 유지 중인 안정 패키지 |
| II. Test Standards — Test pyramid 유지 | ✅ PASS | E2E 추가이나 단위/위젯 테스트는 더 많이 유지 (336개) |
| II. Test Standards — No mock persistence | ✅ PASS | `NativeDatabase.memory()` 유지 (실제 drift in-memory) |
| II. Test Standards — Acceptance scenarios executable | ✅ PASS | spec.md 시나리오 → patrolTest로 자동화 |
| III. UX Consistency — Design tokens | N/A | 테스트 인프라 변경 |
| IV. Performance — 에뮬레이터 부팅 포함 5분 이내 | ✅ PASS | 목표 |

---

## Project Structure

### Documentation (this feature)

```text
specs/003-patrol-e2e-testing/
├── spec.md        ✅ 완료
├── research.md    ✅ 완료
├── plan.md        ← 이 파일
└── tasks.md       # /speckit-tasks로 생성 예정
```

### Source Code 변경 파일

```text
pubspec.yaml                                          # patrol 의존성 + patrol 설정 섹션
android/app/build.gradle.kts                          # testInstrumentationRunner + orchestrator
android/app/src/androidTest/java/com/example/pos/
└── MainActivityTest.java                             # 신규 생성
scripts/
└── run_patrol_tests.sh                               # 에뮬레이터 자동화 편의 스크립트 (신규)
integration_test/
├── us1_order_flow_test.dart                          # patrolTest 마이그레이션
├── us2_payment_flow_test.dart                        # patrolTest 마이그레이션
├── us3_credit_account_flow_test.dart                 # patrolTest 마이그레이션
├── us4_settings_flow_test.dart                       # patrolTest 마이그레이션
├── us5_report_flow_test.dart                         # patrolTest 마이그레이션
└── us6_multi_order_flow_test.dart                    # patrolTest 마이그레이션
```

---

## Implementation Phases

### Phase 1: 패키지 의존성 및 Android 설정

#### 1-1. `pubspec.yaml` 수정

`dev_dependencies`에 patrol 추가, 파일 맨 아래에 patrol 설정 섹션 추가:

```yaml
dev_dependencies:
  # ... 기존 항목 유지 ...
  patrol: ^4.5.0

patrol:
  app_name: POS
  test_directory: integration_test
  android:
    package_name: com.example.pos
  ios:
    bundle_id: com.example.pos
```

#### 1-2. `android/app/build.gradle.kts` 수정

`defaultConfig` 블록에 추가:
```kotlin
testInstrumentationRunner = "pl.leancode.patrol.PatrolJUnitRunner"
testInstrumentationRunnerArguments["clearPackageData"] = "true"
```

`android {}` 블록 내 추가:
```kotlin
testOptions {
    execution = "ANDROIDX_TEST_ORCHESTRATOR"
}
```

`dependencies` 블록 추가 (없으면 신규):
```kotlin
dependencies {
    androidTestUtil("androidx.test:orchestrator:1.5.1")
}
```

#### 1-3. `MainActivityTest.java` 신규 생성

경로: `android/app/src/androidTest/java/com/example/pos/MainActivityTest.java`

```java
package com.example.pos;

import androidx.test.platform.app.InstrumentationRegistry;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.junit.runners.Parameterized;
import org.junit.runners.Parameterized.Parameters;
import pl.leancode.patrol.PatrolJUnitRunner;

@RunWith(Parameterized.class)
public class MainActivityTest {
    @Parameters(name = "{0}")
    public static Object[] testCases() {
        PatrolJUnitRunner instrumentation =
            (PatrolJUnitRunner) InstrumentationRegistry.getInstrumentation();
        instrumentation.setUp(MainActivity.class);
        instrumentation.waitForPatrolAppService();
        return instrumentation.listDartTests();
    }

    public MainActivityTest(String dartTestName) {
        this.dartTestName = dartTestName;
    }

    private final String dartTestName;

    @Test
    public void runDartTest() {
        PatrolJUnitRunner instrumentation =
            (PatrolJUnitRunner) InstrumentationRegistry.getInstrumentation();
        instrumentation.runDartTest(dartTestName);
    }
}
```

**Checkpoint**: `flutter pub get` 성공, `dart analyze` zero warnings 유지

---

### Phase 2: 통합 테스트 마이그레이션

6개 파일 공통 변경 패턴:

**제거**:
```dart
import 'package:integration_test/integration_test.dart';
// IntegrationTestWidgetsFlutterBinding.ensureInitialized();  ← 제거
```

**추가**:
```dart
import 'package:patrol/patrol.dart';
```

**교체**:
```dart
// Before
testWidgets('description', (WidgetTester tester) async {
  await tester.pumpWidget(...);
  await tester.pumpAndSettle();
  await tester.tap(...);
  // ...
});

// After
patrolTest('description', ($) async {
  await $.tester.pumpWidget(...);
  await $.tester.pumpAndSettle();
  await $.tester.tap(...);
  // ...
});
```

**중요**: `flutter_test.dart` import는 유지 (find, expect 등 사용).

#### 마이그레이션 대상 파일

| 파일 | 변경량 | 특이사항 |
|------|--------|---------|
| `us1_order_flow_test.dart` | import 교체 + testWidgets→patrolTest | `pumpApp` 헬퍼 내 tester → $.tester |
| `us2_payment_flow_test.dart` | import 교체 + testWidgets→patrolTest | 동일 |
| `us3_credit_account_flow_test.dart` | import 교체 + testWidgets→patrolTest | 동일 |
| `us4_settings_flow_test.dart` | import 교체 + testWidgets→patrolTest | 동일 |
| `us5_report_flow_test.dart` | import 교체 + testWidgets→patrolTest | 동일 |
| `us6_multi_order_flow_test.dart` | import 교체 + testWidgets→patrolTest | 동일 |

**Checkpoint**: `flutter test` 336개 기존 단위+위젯 테스트 통과 유지

---

### Phase 3: 실행 스크립트 및 문서화

#### 3-1. `scripts/run_patrol_tests.sh` 신규 생성

```bash
#!/usr/bin/env bash
# Patrol E2E 테스트 실행 스크립트
# 사용법: ./scripts/run_patrol_tests.sh [AVD_NAME] [TEST_TARGET]
# 예시:   ./scripts/run_patrol_tests.sh Pixel_Tablet_API_34 integration_test/us1_order_flow_test.dart

set -e

AVD_NAME="${1:-Pixel_Tablet_API_34}"
TEST_TARGET="${2:-integration_test/}"

echo "→ 에뮬레이터 시작: $AVD_NAME"
flutter emulators --launch "$AVD_NAME"

echo "→ 부팅 대기 중..."
adb wait-for-device
sleep 8

echo "→ patrol test 실행: $TEST_TARGET"
patrol test --target "$TEST_TARGET"
```

#### 3-2. README.md 업데이트

`## 테스트` 섹션에 Patrol 실행 방법 추가:

```markdown
### Patrol E2E 테스트 (에뮬레이터 자동화)

# patrol_cli 설치 (최초 1회)
dart pub global activate patrol_cli

# 환경 진단
patrol doctor

# 에뮬레이터 자동 시작 + 전체 E2E 실행
./scripts/run_patrol_tests.sh

# 특정 파일만 실행
./scripts/run_patrol_tests.sh Pixel_Tablet_API_34 integration_test/us1_order_flow_test.dart
```

**Checkpoint**: `patrol doctor` 이상 없음, `dart analyze` zero warnings

---

## Acceptance Criteria

| # | 기준 | 검증 방법 |
|---|------|---------|
| AC-01 | `patrol test --target integration_test/` 실행 시 6개 파일 전부 통과 | 에뮬레이터 연결 후 직접 실행 |
| AC-02 | `flutter test` 기존 336개 단위+위젯 테스트 계속 통과 | `flutter test` 실행 |
| AC-03 | `dart analyze` zero warnings | `dart analyze` 실행 |
| AC-04 | `scripts/run_patrol_tests.sh` 실행 시 에뮬레이터 자동 시작 후 테스트 완료 | 에뮬레이터 종료 후 스크립트 실행 |
| AC-05 | README에 Patrol 실행 방법 문서화 | README.md 확인 |

---

## Risks & Mitigations

| 위험 | 가능성 | 대응 |
|------|--------|------|
| patrol 4.x가 현재 Flutter 빌드 설정과 충돌 | 낮음 | `patrol doctor`로 사전 진단; 문제 시 3.x 계열로 다운그레이드 |
| `MainActivityTest.java` 패키지명 불일치 | 낮음 | `com.example.pos` 확인 완료 |
| 기존 `testWidgets` 혼용으로 인한 binding 충돌 | 중간 | 6개 파일 모두 일괄 마이그레이션; `ensureInitialized()` 전부 제거 |
| 에뮬레이터 부팅 시간 초과 | 낮음 | `adb wait-for-device` + 8초 추가 대기로 안정화 |

---

## Verification Steps

1. `dart pub get` — patrol 의존성 설치 확인
2. `dart analyze` — zero warnings 확인
3. `flutter test` — 기존 336개 테스트 통과 확인
4. 에뮬레이터 시작 후 `patrol test --target integration_test/us1_order_flow_test.dart` — 단일 파일 smoke test
5. `./scripts/run_patrol_tests.sh` — 전체 자동화 스크립트 실행
