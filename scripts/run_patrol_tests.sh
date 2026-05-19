#!/usr/bin/env bash
# Patrol E2E 테스트 실행 스크립트
# 사용법: ./scripts/run_patrol_tests.sh [AVD_NAME] [TEST_TARGET]
# 예시:   ./scripts/run_patrol_tests.sh Pixel_Tablet integration_test/us1_order_flow_test.dart

set -e

export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
export PATH="$PATH:$ANDROID_HOME/platform-tools:$HOME/.pub-cache/bin"

AVD_NAME="${1:-Pixel_Tablet}"
TEST_TARGET="${2:-integration_test/}"

# 이미 실행 중인 에뮬레이터 확인
RUNNING=$(adb devices 2>/dev/null | grep -c "emulator.*device" || true)

if [ "$RUNNING" -eq 0 ]; then
  echo "→ 에뮬레이터 시작: $AVD_NAME"
  flutter emulators --launch "$AVD_NAME"

  echo "→ 부팅 대기 중..."
  # 새로 시작된 에뮬레이터가 online 상태가 될 때까지 대기
  adb wait-for-device shell 'while [[ -z $(getprop sys.boot_completed) ]]; do sleep 2; done'
else
  echo "→ 실행 중인 에뮬레이터 감지 (${RUNNING}개) — 새 실행 건너뜀"
fi

# 연결된 에뮬레이터 중 첫 번째를 타겟으로 사용
DEVICE_SERIAL=$(adb devices | grep "emulator.*device" | head -1 | awk '{print $1}')
echo "→ 대상 디바이스: $DEVICE_SERIAL"

echo "→ patrol test 실행: $TEST_TARGET"
patrol test --target "$TEST_TARGET" --device "$DEVICE_SERIAL"
