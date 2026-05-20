#!/usr/bin/env bash
# E2E 테스트 실행 스크립트 (10초 이상 출력 없으면 freeze로 판단 → 에뮬레이터 종료 후 분석)
# 사용법: ./scripts/run_patrol_tests.sh [AVD_NAME] [TEST_TARGET]
# 예시:   ./scripts/run_patrol_tests.sh Pixel_Tablet integration_test/us1_order_flow_test.dart

set -euo pipefail

export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
export PATH="$PATH:$ANDROID_HOME/platform-tools:$HOME/.pub-cache/bin:$HOME/flutter/bin"

AVD_NAME="${1:-Pixel_Tablet}"
TEST_TARGET="${2:-integration_test/}"
FREEZE_TIMEOUT=10  # 이 초 이상 출력 없으면 freeze로 판단

LOG_FILE="/tmp/pos_test_$$.log"
TS_FILE="/tmp/pos_test_ts_$$"

cleanup() {
  rm -f "$LOG_FILE" "$TS_FILE"
}
trap cleanup EXIT

# ── 에뮬레이터 시작 ────────────────────────────────────────────────────────────
RUNNING=$(adb devices 2>/dev/null | grep -c "emulator.*device" || true)
if [ "$RUNNING" -eq 0 ]; then
  echo "→ 에뮬레이터 시작: $AVD_NAME"
  flutter emulators --launch "$AVD_NAME"

  echo "→ 부팅 대기 중..."
  adb wait-for-device
  until adb shell getprop sys.boot_completed 2>/dev/null | grep -q "^1$"; do
    sleep 2
  done
  sleep 3
else
  echo "→ 실행 중인 에뮬레이터 감지 (${RUNNING}개) — 새 실행 건너뜀"
fi

DEVICE_SERIAL=$(adb devices | grep "emulator.*device" | head -1 | awk '{print $1}')
echo "→ 대상 디바이스: $DEVICE_SERIAL"

# ── 테스트 실행 (백그라운드) + freeze 감시 ─────────────────────────────────────
echo "→ patrol test 실행: $TEST_TARGET"
date +%s > "$TS_FILE"

(
  patrol test \
    --target "$TEST_TARGET" \
    --device "$DEVICE_SERIAL" \
    2>&1 | tee "$LOG_FILE" | while IFS= read -r line; do
      echo "$line"
      date +%s > "$TS_FILE"
    done
) &
TEST_BG=$!

while kill -0 "$TEST_BG" 2>/dev/null; do
  sleep 2
  LAST=$(cat "$TS_FILE" 2>/dev/null || date +%s)
  NOW=$(date +%s)
  ELAPSED=$(( NOW - LAST ))

  if [ "$ELAPSED" -gt "$FREEZE_TIMEOUT" ]; then
    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo "ERROR: ${FREEZE_TIMEOUT}초 이상 출력 없음 → 화면 정지(freeze) 감지"
    echo "════════════════════════════════════════════════════════════"

    kill "$TEST_BG" 2>/dev/null || true

    echo ""
    echo "→ adb logcat 수집 중..."
    adb -s "$DEVICE_SERIAL" logcat -d -s flutter 2>/dev/null | tail -80 || true

    echo ""
    echo "→ 에뮬레이터 종료"
    adb -s "$DEVICE_SERIAL" emu kill 2>/dev/null || true

    echo ""
    echo "=== 마지막 테스트 출력 ==="
    tail -30 "$LOG_FILE" 2>/dev/null || true

    echo ""
    echo "=== 원인 분석 ==="
    echo "가장 흔한 원인: pumpAndSettle() 이 CircularProgressIndicator 등"
    echo "무한 애니메이션 위젯 때문에 반환되지 않음."
    echo ""
    echo "수정 방법:"
    echo "  pumpAndSettle() → pump(const Duration(milliseconds: 800~1200))"
    echo ""
    echo "재현 파일 확인:"
    grep -n "pumpAndSettle" integration_test/*.dart 2>/dev/null || echo "  (pumpAndSettle 없음)"
    exit 1
  fi
done

wait "$TEST_BG"
EXIT_CODE=$?

if [ "$EXIT_CODE" -eq 0 ]; then
  echo ""
  echo "✓ 모든 테스트 통과"
else
  echo ""
  echo "✗ 테스트 실패 (exit code: $EXIT_CODE)"
  echo "=== 실패 요약 ==="
  grep -E "FAILED|Error|Exception" "$LOG_FILE" 2>/dev/null | tail -20 || true
fi

exit "$EXIT_CODE"
