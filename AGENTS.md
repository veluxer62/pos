<!-- Generated: 2026-05-04 | Updated: 2026-05-04 -->

# pos — Restaurant POS App

## Purpose
음식점 점주를 위한 Flutter 기반 태블릿 POS 앱. 주문 접수·전달·결제(즉시/외상), 영업 시작/마감 기반 일일 매출 정산, 외상 장부 관리, 메뉴·좌석 설정을 제공한다. Android 8.0+ / iOS 14+ 태블릿(10인치 이상) 가로 레이아웃 최적화, 로컬 전용(drift SQLite), 백엔드 없음.

## Key Files

| File | Description |
|------|-------------|
| `pubspec.yaml` | 프로젝트 의존성 및 Flutter SDK 버전 요구사항 |
| `analysis_options.yaml` | Dart strict lint 설정 — zero warnings 필수 |
| `CLAUDE.md` | AI 에이전트용 프로젝트 지침 (아키텍처, TDD, 코드 스타일) |
| `README.md` | 프로젝트 설명 및 설치/실행 가이드 |
| `lib/main.dart` | 앱 진입점 — ProviderScope + GoRouter 초기화 |

## Subdirectories

| Directory | Purpose |
|-----------|---------|
| `lib/` | 앱 소스코드 — Clean Architecture 3계층 (see `lib/AGENTS.md`) |
| `test/` | 단위·위젯·통합 테스트 (see `test/AGENTS.md`) |
| `integration_test/` | 전체 시나리오 통합 테스트 (see `integration_test/AGENTS.md`) |
| `specs/` | 요구사항 명세, 기능 스펙, 계약 문서 |
| `android/` | Android 플랫폼 설정 (Kotlin, Gradle) |
| `ios/` | iOS 플랫폼 설정 (Swift, Xcode) |

## For AI Agents

### Working In This Directory
- `CLAUDE.md`를 반드시 먼저 읽을 것 — 프로젝트 아키텍처와 코드 스타일 지침 포함
- 테이블 정의 또는 `@riverpod` provider 변경 시 반드시 build_runner 재실행:
  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```
- 모든 UseCase·DAO 구현 전 TDD(RED → GREEN) 순서 준수

### Testing Requirements
```bash
flutter test                    # 단위 + 위젯 테스트
flutter test --coverage         # 커버리지 (domain + data 레이어 80% 이상 필수)
flutter test integration_test/  # 전체 시나리오 (에뮬레이터/실기기 필요)
dart analyze                    # lint zero warnings 필수
dart format .                   # 포맷
```

### Common Patterns
- Clean Architecture: domain → data → presentation 단방향 의존성
- `abstract interface class IXxxRepository` → `LocalXxxRepository` 구현체
- Riverpod 2.x `@riverpod` 코드 생성, `AsyncNotifier` 비동기 상태
- KRW 원 단위 정수, UI 표시 시 `CurrencyFormatter` 사용
- `sealed class` + exhaustive switch로 컴파일 타임 상태 안전성

## Dependencies

### External
- `drift: ^2.20.3` — SQLite ORM (로컬 전용 저장소)
- `flutter_riverpod: ^3.3.1` + `riverpod_annotation: ^4.0.2` — 상태 관리 & DI
- `go_router: ^17.2.2` — 선언적 라우팅
- `uuid: ^4.4.2` — UUID 생성

### Dev
- `build_runner` + `drift_dev` + `riverpod_generator` — 코드 생성
- `mockito: ^5.4.4` — UseCase 테스트용 mock

<!-- MANUAL: Any manually added notes below this line are preserved on regeneration -->
