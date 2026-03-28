<!-- Context: project-intelligence/nav | Priority: high | Version: 1.2 | Updated: 2026-03-28 -->

# Project Intelligence

> 프로젝트를 빠르게 이해하기 위한 시작점입니다. 비즈니스 목표, 플랫폼 결정, 구현 패턴을 함께 연결합니다.

## Structure

```text
.opencode/context/project-intelligence/
├── navigation.md
├── business-domain.md
├── technical-domain.md
├── business-tech-bridge.md
├── decisions-log.md
└── living-notes.md
```

## Quick Routes
| What You Need | File | Description |
|---------------|------|-------------|
| 플랫폼 구조와 실행 기준 파악 | `technical-domain.md` | 스택, bootstrap, 검증 흐름 |
| 이 저장소의 운영 목적 이해 | `business-domain.md` | 목표, 사용자, 성공 기준 |
| 왜 이런 기술을 택했는지 확인 | `business-tech-bridge.md` | 운영 요구와 기술 선택 연결 |
| 현재 구조의 배경 결정 추적 | `decisions-log.md` | 주요 결정, 대안, 영향 |
| 변경 전 현재 리스크 점검 | `living-notes.md` | 이슈, drift, 유지보수 gotcha |

## By File
| File | Description | Priority |
|------|-------------|----------|
| `technical-domain.md` | 플랫폼 스택과 구현 패턴 | critical |
| `business-domain.md` | 운영 맥락과 목표 | critical |
| `business-tech-bridge.md` | 운영 요구와 기술 연결 | critical |
| `decisions-log.md` | 의사결정 기록 | high |
| `living-notes.md` | 현재 이슈와 운영 메모 | high |

## Loading Strategy
- 인프라나 플랫폼 변경 작업은 `technical-domain.md`부터 읽습니다.
- 목표나 방향성을 이해할 때는 `business-domain.md`와 `business-tech-bridge.md`를 함께 읽습니다.
- 변경 배경과 현재 맥락은 `decisions-log.md`와 `living-notes.md`에서 확인합니다.

## Related Context
- `.opencode/context/core/standards/project-intelligence.md`
- `.opencode/context/core/standards/project-intelligence-management.md`
- `.opencode/context/core/context-system.md`
