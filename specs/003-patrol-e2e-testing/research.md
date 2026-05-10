# Research: Patrol E2E Testing Integration

**Date**: 2026-05-10
**Branch**: `003-patrol-e2e-testing`

---

## 1. 버전 선택

**Decision**: patrol `^4.5.0` + patrol_cli `^4.3.1` 사용

**Rationale**: 현재 Flutter 3.41.7이 설치되어 있으므로 최신 4.x 계열 사용 가능. 3.x 계열은 3.32.0 이상을 요구하므로 3.22.0 환경 이점이 없다.

**Alternatives considered**:
- patrol 3.11.2 + patrol_cli 3.2.1: Flutter 3.22.0 최소 요구 기준에 맞으나, 이미 3.41.7 환경이므로 이점 없음
- patrol 3.20.0: 최소 Flutter 3.32.0 요구 — 4.x와 기능 차이 없이 구버전

**Constraint**: patrol 4.x부터 기본 테스트 디렉토리가 `patrol_test/`로 변경되므로 `pubspec.yaml`에 `test_directory: integration_test` 명시 필수.

---

## 2. 설정 파일 구조

**Decision**: 별도 `patrol.toml` 파일 없음. `pubspec.yaml`의 `patrol:` 섹션에서 모든 설정 관리.

```yaml
patrol:
  app_name: POS
  test_directory: integration_test
  android:
    package_name: com.example.pos
  ios:
    bundle_id: com.example.pos
```

**Rationale**: Patrol은 `patrol.toml`을 지원하지 않는다. pubspec.yaml 중앙화로 관리 편의성 향상.

---

## 3. Android 네이티브 설정

**Decision**: `AndroidManifest.xml` 직접 수정 없음. `build.gradle.kts`와 `MainActivityTest.java` 수정/생성.

**`android/app/build.gradle.kts` 추가 내용**:
```kotlin
defaultConfig {
    testInstrumentationRunner = "pl.leancode.patrol.PatrolJUnitRunner"
    testInstrumentationRunnerArguments["clearPackageData"] = "true"
}

testOptions {
    execution = "ANDROIDX_TEST_ORCHESTRATOR"
}

dependencies {
    androidTestUtil("androidx.test:orchestrator:1.5.1")
}
```

**`android/app/src/androidTest/java/com/example/pos/MainActivityTest.java`** 신규 생성 필요.

**Rationale**: Patrol은 gRPC를 통해 Flutter 테스트와 통신하므로 PatrolJUnitRunner가 필수. Orchestrator는 테스트 간 격리를 보장한다.

---

## 4. 기존 테스트 마이그레이션 전략

**Decision**: `testWidgets` → `patrolTest`, `WidgetTester tester` → `PatrolIntegrationTester $`로 교체. `$.tester`로 기존 WidgetTester API 접근.

**최소 변경 패턴**:
```dart
// Before
import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('test', (WidgetTester tester) async {
    await tester.pumpWidget(...);
  });
}

// After
import 'package:patrol/patrol.dart';

void main() {
  patrolTest('test', ($) async {
    await $.tester.pumpWidget(...);
  });
}
```

**Rationale**: `$.tester`가 기존 `WidgetTester`이므로 코드 변경 최소화. native 기능 미사용 시 `flutter test`로도 실행 가능(noop 처리).

**Constraint**: `IntegrationTestWidgetsFlutterBinding.ensureInitialized()` 제거 필요. Patrol이 자체적으로 binding을 초기화한다.

---

## 5. 에뮬레이터 자동 시작

**Decision**: `patrol test`는 에뮬레이터를 자동 시작하지 않는다. 에뮬레이터를 먼저 시작한 후 `-d` 플래그로 대상 지정.

```bash
# AVD 시작
flutter emulators --launch Pixel_Tablet_API_34

# 부팅 대기 후 테스트 실행
patrol test --target integration_test/us1_order_flow_test.dart -d emulator-5554

# 전체 실행
patrol test --target integration_test/
```

**Convenience script** (`scripts/run_patrol_tests.sh`):
```bash
#!/bin/bash
set -e
DEVICE_ID="${1:-emulator-5554}"
flutter emulators --launch Pixel_Tablet_API_34
adb -s "$DEVICE_ID" wait-for-device
sleep 5
patrol test --target integration_test/ --device "$DEVICE_ID"
```

**Rationale**: CI 환경에서는 `reactivecircus/android-emulator-runner` GitHub Action 활용. 로컬에서는 편의 스크립트로 자동화.

---

## 6. 하위 호환성

**Decision**: native 기능(`$.native.*`) 미사용 시 `flutter test integration_test/`도 동작.

**Constraint**: `patrolTest` 코드를 `flutter test`로 실행하면 Patrol native 기능은 noop처리되지만, 순수 Flutter widget 테스트는 정상 동작. 현재 프로젝트 테스트는 native 기능 없으므로 하위 호환 유지 가능.

---

## 7. patrol_cli 설치

```bash
dart pub global activate patrol_cli
export PATH="$PATH:$HOME/.pub-cache/bin"   # ~/.zshrc에 추가
patrol doctor   # 환경 진단
```

---

## 8. Android package name 확인 방법

```bash
grep -r "applicationId\|namespace" android/app/build.gradle.kts
# 또는
grep "package" android/app/src/main/AndroidManifest.xml
```
