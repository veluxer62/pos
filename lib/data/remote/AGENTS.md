<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-05-04 | Updated: 2026-05-04 -->

# lib/data/remote/

## Purpose
백엔드 HTTP 구현체 위치 (현재 stub). 백엔드 전환 시 이 디렉토리에 `RemoteXxxRepository` 구현체를 추가하고 `core/di/providers.dart`의 주입 대상만 교체하면 된다.

## Subdirectories

| Directory | Purpose |
|-----------|---------|
| `repositories/` | HTTP repository 구현체 stub (현재 README만 존재) |

## For AI Agents

### Working In This Directory
- V1 범위 외 — SC-010·FR-035 서버 동기화는 백엔드 연동 단계에서 구현
- 구현 시 `LocalXxxRepository`와 동일한 `IXxxRepository` 인터페이스 구현
- domain·presentation 레이어 변경 없이 `providers.dart`만 수정

<!-- MANUAL: -->
