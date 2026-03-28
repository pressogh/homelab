<!-- Context: project-intelligence/business | Priority: critical | Version: 1.1 | Updated: 2026-03-28 -->

# Business Domain

**Purpose**: 이 저장소가 해결하려는 운영 문제, 주요 사용자, 제공 가치, 성공 기준을 인프라 운영 관점에서 정리합니다.
**Last Updated**: 2026-03-28

## Quick Reference
- **Audience**: 운영자, 기여자, AI 에이전트
- **Update When**: 운영 목표, 플랫폼 범위, 핵심 서비스 구성이 바뀔 때
- **Core Identity**: 개인 homelab Kubernetes 플랫폼을 코드로 재현 가능하게 운영하는 인프라 프로젝트

## Core Concept
이 프로젝트는 애플리케이션 제품을 만드는 저장소가 아니라, 개인 homelab 환경의 인프라와 플랫폼 서비스를 선언적으로 운영하기 위한 저장소입니다. 목표는 수동 작업을 줄이고, 재구축 가능하고, 검증 가능하며, 장기 운영에 적합한 플랫폼 상태를 유지하는 것입니다.

## Project Identity
| 항목 | 내용 |
|------|------|
| Project Type | Homelab infrastructure operations repository |
| Primary Goal | 재현 가능한 Kubernetes 플랫폼 구축과 운영 |
| Operating Model | Terraform bootstrap + Argo CD GitOps |
| Managed Scope | VM, cluster bootstrap, networking, secrets, storage, observability, data services |
| Non-Goal | 일반적인 사용자 기능 중심 웹 애플리케이션 개발 |

## Primary Operators
| 사용자군 | 설명 | 주요 필요 | 주요 문제 |
|----------|------|-----------|-----------|
| Primary Operator | homelab을 직접 운영하는 개인 운영자 | 빠른 복구, 예측 가능한 변경, 선언적 운영 | 수동 구성 drift, 부트스트랩 복잡도 |
| Contributors | 저장소를 수정하거나 검증하는 개발자/기여자 | 구조 이해, 안전한 변경 경로, 검증 기준 | 계층 간 책임 경계 혼동 |
| AI Agents | 저장소를 읽고 변경을 제안하는 자동화 에이전트 | 명확한 운영 모델, 검증 명령, 패턴 문서 | 템플릿성 문서나 오래된 맥락으로 인한 오판 |

## Value Proposition
- 인프라와 플랫폼 운영을 코드로 남겨 재설치와 복구 가능성을 높입니다.
- Terraform과 Argo CD의 책임을 나눠 bootstrap과 day-2 운영을 명확히 분리합니다.
- 시크릿, 인증서, 게이트웨이, 스토리지, 관측성을 표준 패턴으로 묶어 운영 부담을 줄입니다.
- plan, lint, schema validation 중심의 검증 흐름으로 위험한 변경을 사전에 줄입니다.
- 사람의 기억보다 저장소 구조와 선언형 설정을 운영의 기준으로 삼습니다.

## Success Criteria
- `terraform/do`와 GitOps만으로 새 클러스터를 재현 가능하게 부트스트랩할 수 있어야 합니다.
- 장기 운영 서비스가 Argo CD 기준 desired state로 안정적으로 유지되어야 합니다.
- 시크릿이 Git에 직접 저장되지 않고 외부 시크릿 경로로만 공급되어야 합니다.
- Terraform 및 Kubernetes 변경이 저장소 표준 검증 절차를 통과해야 합니다.
- 게이트웨이, 인증서, 스토리지, 관측성, 데이터 서비스가 공통 플랫폼 기능으로 안정적으로 동작해야 합니다.

## Constraints
- Proxmox, SSH, 내부 네트워크, VLAN, 내부 도메인 등 환경 의존성이 큽니다.
- 단일 운영자 중심 환경이므로 기능 확장보다 운영 안정성과 복구성이 우선입니다.
- 민감정보는 Git에 포함할 수 없고 generated artifact로 분리해야 합니다.
- bootstrap 이후 장기 운영 앱은 Terraform이 아니라 Argo CD 관리 대상이어야 합니다.
- Gateway API와 operator 기반 리소스는 drift 판별이 까다롭습니다.

## Current Focus
- bootstrap과 GitOps 운영의 책임 경계를 유지하면서 플랫폼 품질을 높이는 것
- networking, storage, monitoring, database, observability 영역을 안정적으로 유지하는 것
- 시크릿 주입, 내부/외부 게이트웨이, 인증서 신뢰 체계, 상태 저장 워크로드 운영 패턴을 고도화하는 것

## 📂 Codebase References
- `AGENTS.md` - 저장소 운영 원칙과 책임 경계
- `terraform/do` - 표준 bootstrap 및 운영 워크플로우
- `terraform/main.tf` - 루트 인프라 구성
- `terraform/modules/common/proxmox.tf` - VM provisioning 구조
- `terraform/modules/common/talos.tf` - 클러스터 bootstrap 흐름
- `terraform/modules/argocd/main.tf` - Argo CD 초기 설치
- `k8s/argocd/bootstrap/root-app.yaml` - GitOps 운영 진입점
- `k8s/external-secrets/providers/bitwarden-clustersecretstore.yaml` - 시크릿 운영 경로
- `k8s/elasticsearch/elasticsearch.yaml` - 상태 저장형 워크로드 예시

## Related Files
- `technical-domain.md` - 기술 스택과 구현 패턴
- `business-tech-bridge.md` - 운영 목표와 기술 선택의 연결
- `decisions-log.md` - 핵심 운영/아키텍처 결정 기록
- `living-notes.md` - 현재 상태와 유지보수 메모
