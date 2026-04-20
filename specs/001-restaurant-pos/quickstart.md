# Quickstart: Restaurant POS App

**Branch**: `001-restaurant-pos`
**Date**: 2026-04-19 (updated: Flutter + drift SQLite)

---

## 사전 요구사항

- Flutter 3.x (stable channel) — [flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install)
- Dart 3.x (Flutter SDK 포함)
- Android Studio / Xcode (에뮬레이터 또는 실기기 연결)
- `flutter doctor` 통과 확인

```bash
flutter doctor
# 모든 항목 ✓ 또는 [!] 경고 없어야 함
```

---

## 1. 저장소 준비

```bash
git clone <repo-url>
cd pos
git checkout 001-restaurant-pos
```

---

## 2. 의존성 설치

```bash
flutter pub get
```

---

## 3. 코드 생성 (drift + Riverpod)

```bash
# drift 테이블 스키마 및 Riverpod provider 코드 생성
dart run build_runner build --delete-conflicting-outputs
```

> 스키마 변경 후에는 반드시 재실행.

---

## 4. 앱 실행

```bash
# 연결된 기기 목록 확인
flutter devices

# 에뮬레이터 또는 실기기로 실행
flutter run

# 특정 기기 지정 (기기 ID는 flutter devices 출력 참조)
flutter run -d <device-id>

# 태블릿 에뮬레이터 권장 (가로 모드)
# Android: Pixel Tablet API 34 이상
# iOS: iPad Pro (12.9-inch) iOS 17 이상
```

---

## 5. 테스트 실행

```bash
# 전체 단위·위젯 테스트
flutter test

# 커버리지 포함
flutter test --coverage

# 특정 테스트 파일
flutter test test/domain/usecases/create_order_use_case_test.dart

# 통합 테스트 (실기기 또는 에뮬레이터 필요)
flutter test integration_test/

# DB 통합 테스트 (in-memory drift, 기기 불필요)
flutter test test/data/
```

---

## 6. 정적 분석 및 포맷

```bash
# 린트 (zero warnings 필수)
dart analyze

# 포맷 검사
dart format --output=none --set-exit-if-changed .

# 포맷 자동 적용
dart format .
```

---

## 7. 핵심 사용 시나리오 (수동 검증)

### US4: 영업 시작 (선행 필수)

1. 앱 실행 → 홈 화면에서 "영업 시작" 버튼 탭
2. **확인**: BusinessDay 상태 OPEN, 주문 생성 활성화

### US1: 주문 접수 및 전달 관리

1. 홈 화면에서 좌석 번호 선택 (예: "3번")
2. 메뉴 목록에서 "김치찌개 × 2" 추가 → "주문 확정"
3. 주문 목록에서 해당 주문 "전달 완료" 처리
4. **확인**: 주문 상태 PENDING → DELIVERED, `deliveredAt` 기록됨, 항목 수정 불가

### US2: 결제 처리 (즉시/외상)

1. DELIVERED 주문 선택 → "결제" 버튼 탭
2. **즉시 결제**: 결제 금액(₩18,000) 확인 → "즉시 결제 완료"
   - **확인**: 주문 상태 DELIVERED → PAID
3. **외상 결제**: "외상으로 결제" 선택 → 외상 계좌 선택 → 확정
   - **확인**: 주문 상태 DELIVERED → CREDITED, 외상 계좌 잔액 증가

### US3: 외상 장부 관리

1. 외상 장부 화면 → 외상 계좌 목록 확인 (잔액 내림차순)
2. 계좌 선택 → "납부 입력" → 금액 입력 → 확정
3. **확인**: 계좌 잔액 차감, 거래 이력에 PAYMENT 기록

### US4: 영업 마감 및 보고서

1. "영업 마감" 버튼 탭
2. 미처리 주문 있는 경우 → 처리 방법 선택 (강제 취소 또는 취소)
3. 마감 확정 → 일일 매출 보고서 화면 자동 이동
4. **확인**: 총매출·메뉴별 판매량·시간대별 매출 확인

### US5: 메뉴·좌석 설정

1. 설정 화면 → "메뉴 관리" → "+" → "된장찌개 ₩9,000 한식" 등록
2. **확인**: 주문 화면 메뉴 목록에 즉시 반영
3. 설정 화면 → "좌석 관리" → "+" → "10번 좌석, 4인" 추가
4. **확인**: 주문 화면 좌석 목록에 즉시 반영

---

## 8. 프로젝트 구조

```
lib/
├── domain/          # 순수 Dart — entities, repositories(abstract), usecases
├── data/
│   ├── local/       # drift SQLite 구현체 (database, daos, repositories)
│   └── remote/      # 미래 HTTP 구현체 스텁
├── presentation/    # Flutter UI (theme, widgets, pages, providers)
└── core/            # DI, router, utils

test/
├── domain/          # UseCase 단위 테스트 (mockito)
├── data/            # DAO·Repository 통합 테스트 (in-memory drift)
├── presentation/    # Widget 테스트
└── integration/     # 전체 시나리오 (integration_test)
```

---

## 9. 주요 명령어 요약

| 작업 | 명령어 |
|------|--------|
| 의존성 설치 | `flutter pub get` |
| 코드 생성 | `dart run build_runner build --delete-conflicting-outputs` |
| 앱 실행 | `flutter run` |
| 단위 테스트 | `flutter test` |
| 커버리지 | `flutter test --coverage` |
| 통합 테스트 | `flutter test integration_test/` |
| 린트 | `dart analyze` |
| 포맷 | `dart format .` |
