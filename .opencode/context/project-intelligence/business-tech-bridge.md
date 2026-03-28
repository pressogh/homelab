<!-- Context: project-intelligence/bridge | Priority: critical | Version: 1.2 | Updated: 2026-03-28 -->

# Business ↔ Tech Bridge

**Purpose**: 운영 목표와 기술 선택이 어떻게 연결되는지 설명합니다.
**Last Updated**: 2026-03-28

## Quick Reference
- **Audience**: 운영자, 기여자, AI 에이전트
- **Update When**: 핵심 플랫폼 구성이나 운영 정책이 바뀔 때
- **Core Model**: 재현성, 복구 가능성, 보안 경계, 지속 운영 요구가 현재 기술 선택을 이끕니다

## Core Concept
이 프로젝트의 기술 선택은 "적은 인력으로도 반복 가능하고 복구 가능한 플랫폼 운영"이라는 목표를 중심으로 이루어졌습니다. 즉, VM 생성, 클러스터 부트스트랩, GitOps 운영, 시크릿 관리, 트래픽 경계, 상태 저장, 관측성을 각각 분리된 계층으로 다룹니다.

## Core Mapping
| 운영 요구 | 기술 선택 | 연결 이유 | 운영 가치 |
|-----------|-----------|-----------|-----------|
| 재현 가능한 클러스터 생성 | OpenTofu / Terraform | VM 생성부터 초기 플랫폼 설치까지 코드화 | 재설치와 복구 가능성 향상 |
| 예측 가능한 노드 상태 | Talos | 노드 구성을 선언형으로 고정 | 노드 drift 감소 |
| 지속적인 desired state 유지 | Argo CD | Git 기준 동기화와 self-heal | 수동 변경 감소 |
| Git 없는 시크릿 운영 | Bitwarden + External Secrets | 시크릿 저장소와 런타임 소비 분리 | 민감정보 노출 감소 |
| 공개/내부 노출 분리 | Gateway API + public/internal gateway | 노출 경계와 인증 정책 분리 | 운영 정책 명확화 |
| 상태 저장과 관측성 확보 | Longhorn + Prometheus + Signoz + Elasticsearch | 플랫폼 공통 기능 표준화 | 장애 대응과 운영 가시성 향상 |

## Feature Mapping

### 1. 재현 가능한 부트스트랩
**운영 맥락**
- 클러스터를 새로 만들거나 복구할 수 있어야 합니다.
- 수동 설치 절차에 의존하면 운영자가 바뀌거나 시간이 지나며 재현성이 급격히 떨어집니다.

**기술 구현**
- Proxmox VM 생성, Talos bootstrap, Cilium 설치, kubeconfig 산출, 초기 Argo CD 설치를 Terraform으로 처리합니다.
- 장기 운영 서비스는 이후 Argo CD가 이어받습니다.

**연결**
- "클러스터를 다시 만들 수 있는가?"라는 운영 질문에 대해, 현재 저장소는 코드와 bootstrap workflow로 답합니다.

### 2. Day-0/1과 Day-2 운영 분리
**운영 맥락**
- 인프라 생성과 플랫폼 운영은 성격이 다릅니다.
- 둘을 한 계층에서 관리하면 변경 책임과 장애 원인 추적이 어려워집니다.

**기술 구현**
- Terraform은 bootstrap-only로 유지하고, 장기 운영 서비스는 `k8s/argocd/manifests/` 아래 GitOps 기준으로 관리합니다.

**연결**
- 이 분리는 운영 계층의 책임을 명확히 하고, drift와 중복 관리를 줄이는 핵심 정책입니다.

### 3. 시크릿 분리
**운영 맥락**
- Git은 desired state의 중심이지만, 시크릿 저장소가 되어서는 안 됩니다.
- 운영 자동화는 유지하면서도 민감정보 유출을 막아야 합니다.

**기술 구현**
- Terraform은 최소 bootstrap credential만 넘기고, 실제 런타임 시크릿은 Bitwarden과 External Secrets Operator가 제공합니다.

**연결**
- 선언형 운영과 비밀 분리를 동시에 달성하려는 선택입니다.

### 4. 네트워크 정책의 플랫폼화
**운영 맥락**
- 어떤 서비스가 내부용인지 외부 공개용인지 일관되게 통제해야 합니다.
- 인증서와 신뢰 체계도 노출 범위에 맞게 달라져야 합니다.

**기술 구현**
- public/internal gateway를 분리하고, namespace label과 cert-manager/trust-manager 조합으로 노출과 신뢰를 관리합니다.

**연결**
- 서비스별 임시 설정이 아니라 플랫폼 정책으로 노출 경계를 관리합니다.

### 5. 상태 저장과 관측성의 내장
**운영 맥락**
- homelab이라도 저장소, 메트릭, 로그, 트레이싱, 데이터 서비스가 안정적으로 유지되어야 합니다.
- 플랫폼 상태를 모르면 장애 대응과 성능 판단이 어려워집니다.

**기술 구현**
- Longhorn, kube-prometheus-stack, Signoz, Elasticsearch를 공통 플랫폼 레이어로 운영합니다.

**연결**
- 워크로드 운영 이전에 플랫폼 자체가 상태를 유지하고 자신을 관찰할 수 있어야 한다는 요구를 반영합니다.

## Trade-offs
| 상황 | 운영 우선순위 | 기술 우선순위 | 현재 선택 | 이유 |
|------|---------------|---------------|-----------|------|
| bootstrap과 운영 분리 | 책임 경계 명확화 | 도구 수 증가 수용 | Terraform + Argo CD 분리 | 장기 유지보수에 유리 |
| Talos 불변성 | 예측 가능성 | 즉시 수동 수정 어려움 | Talos 채택 | drift 억제가 더 중요 |
| 외부 시크릿 관리 | Git 비밀 제거 | 초기 설정 복잡도 증가 | Bitwarden + ESO | 보안 원칙 유지 |
| 강한 관측성/복제 | 안정성 | 자원 사용량 증가 | Longhorn/Prometheus/Elasticsearch 유지 | 운영 가시성을 우선 |

## 📂 Codebase References
- `terraform/main.tf` - bootstrap 계층 구성
- `terraform/modules/common/talos.tf` - 노드/클러스터 선언형 구성
- `terraform/modules/common/kubernetes.tf` - bootstrap secret handoff
- `terraform/modules/argocd/main.tf` - GitOps 시작점
- `k8s/argocd/bootstrap/root-app.yaml` - 루트 GitOps 동기화
- `k8s/gateway/gateway-public/gateway.yaml` - 외부 노출 패턴
- `k8s/gateway/gateway-internal/gateway.yaml` - 내부 노출 패턴
- `k8s/external-secrets/providers/bitwarden-clustersecretstore.yaml` - 외부 시크릿 소스
- `k8s/argocd/manifests/apps/storage/longhorn/application.yaml` - 상태 저장 플랫폼 계층
- `k8s/argocd/manifests/apps/observability/signoz/application.yaml` - observability 계층

## Related Files
- `business-domain.md` - 운영 목적과 가치
- `technical-domain.md` - 기술 구현 상세
- `decisions-log.md` - 선택의 이유와 대안
- `living-notes.md` - 현재 운영상의 주의점
