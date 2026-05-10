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
