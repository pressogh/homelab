<!-- Context: project-intelligence/technical | Priority: critical | Version: 1.1 | Updated: 2026-03-28 -->

# Technical Domain

**Purpose**: 이 homelab 플랫폼의 기술 스택, 운영 모델, 구현 패턴, 유지보수 시 주의할 운영 포인트를 정리합니다.
**Last Updated**: 2026-03-28

## Quick Reference
- **Audience**: 이 저장소에서 작업하는 개발자, 운영자, AI 에이전트
- **Update When**: 기술 스택, 운영 워크플로우, 부트스트랩 방식, 플랫폼 서비스 구성이 바뀔 때
- **Core Model**: Terraform이 인프라를 부트스트랩하고, Argo CD가 장기 운영되는 Kubernetes 서비스를 관리합니다

## Core Concept
이 프로젝트는 OpenTofu/Terraform으로 인프라와 클러스터 초기 구성을 만들고, Argo CD로 Kubernetes 플랫폼 서비스를 지속적으로 운영하는 homelab 플랫폼입니다. 임시 수동 변경보다 명시적이고 재현 가능한 플랫폼 정의를 우선합니다.

## Primary Stack
| Layer | Technology | Role |
|------|------------|------|
| Virtualization | Proxmox | 클러스터 노드 VM 생성 및 관리 |
| OS / Cluster Bootstrap | Talos Linux | Kubernetes 노드 OS와 클러스터 부트스트랩 |
| Provisioning | OpenTofu / Terraform | 인프라 및 초기 구성 자동화 |
| Networking | Cilium + Gateway API | CNI, 라우팅, 서비스 노출 |
| GitOps | Argo CD | 플랫폼 앱의 지속적 배포 및 동기화 |
| Secrets | External Secrets Operator + Bitwarden | Kubernetes 시크릿 주입 |
| PKI / Trust | cert-manager + trust-manager | 인증서 발급 및 신뢰 번들 배포 |
| Storage | Longhorn | 영구 스토리지 |
| Observability | kube-prometheus-stack + Signoz | 메트릭 및 관측성 |
| Data Services | Elasticsearch | 상태 저장형 플랫폼 워크로드 |

## Key Points
- Terraform 작업은 `terraform/` 디렉터리에서 실행하며, `plan`, `apply`, `health`, `merge-kubeconfig` 흐름은 `terraform/do` 래퍼를 우선 사용합니다.
- Terraform은 Proxmox VM, Talos 부트스트랩, Cilium, kubeconfig export, 초기 Argo CD 설치처럼 부트스트랩 성격의 작업을 담당합니다.
- 장기 운영되는 Kubernetes 플랫폼 서비스는 Terraform이 아니라 `k8s/argocd/manifests/` 기준의 GitOps로 관리합니다.
- 시크릿은 Git에 직접 넣지 않고 Bitwarden과 External Secrets Operator를 통해 Kubernetes로 전달합니다.
- 설정은 drift를 줄이고 가독성을 유지하기 위해 sync wave, 명시적 namespace, generated output 분리 원칙을 따릅니다.
- CRD와 operator 중심 앱은 false drift가 발생할 수 있으므로, 실제 변경 판단 전 `decisions-log.md`와 `living-notes.md`의 운영 메모를 함께 확인합니다.

## Working Patterns

### Infrastructure Pattern
루트 Terraform 구성은 작게 유지하고, 역할이 분리된 모듈 중심으로 구성합니다. 현재 핵심 모듈은 인프라와 부트스트랩을 담당하는 `common`과 GitOps 시드를 담당하는 `argocd`입니다.

### GitOps Pattern
Argo CD는 루트 bootstrap application을 통해 저장소 내 child Application과 AppProject를 재귀적으로 적용합니다. 플랫폼 영역은 infrastructure, networking, storage, monitoring, database, observability 같은 도메인 단위로 나뉩니다.

### Kubernetes Resource Pattern
저장소의 Kubernetes 리소스는 `namespace.yaml`, `application.yaml`, `gateway.yaml`, `httproute.yaml`, `certificate.yaml`, `kustomization.yaml` 같은 익숙한 파일 조합으로 관리합니다. Helm 기반 서비스는 보통 `k8s/<service>/values/values.yaml`에 값을 둡니다.

## Naming Conventions
| Type | Convention | Examples |
|------|------------|----------|
| Terraform variables / locals / outputs | `snake_case` | `proxmox_endpoint`, `kube_client_config` |
| Terraform resource labels | 설명적인 `snake_case` | `bootstrap_bitwarden_secret` |
| Kubernetes resources / namespaces | 소문자 `kebab-case` | `gateway-public`, `external-secrets` |
| Directories | 소문자 `kebab-case` | `gateway-public`, `cert-manager-csi-driver` |
| Common manifest files | 관례적 파일명 | `application.yaml`, `kustomization.yaml`, `values.yaml` |

## Standards
- OpenTofu 명령은 저장소 루트가 아니라 `terraform/`에서 실행합니다.
- 부트스트랩 흐름은 임의 명령 조합보다 `terraform/do`를 우선 사용합니다.
- provider alias, provider wiring, `depends_on` 같은 부트스트랩 순서 제어는 유지합니다.
- 장기 운영 앱을 다시 Terraform으로 옮기지 않고, Terraform은 bootstrap-focused 상태를 유지합니다.
- YAML은 2칸 들여쓰기와 일반적인 Kubernetes 필드 순서를 따릅니다.
- namespaced resource는 namespace를 명시합니다.
- 기존 Argo CD 앱 구조와 sync-wave 순서를 존중합니다.
- `terraform/output/`, `terraform/temp/`, `terraform/logs/`는 generated artifact로 취급합니다.
- 변경 검증은 저장소에 이미 있는 Terraform 및 Kubernetes 검증 명령을 사용합니다.

## Security Requirements
- `terraform.tfvars`, kubeconfig, Talos config, exported certificate 같은 민감 정보는 커밋하지 않습니다.
- 서비스 시크릿은 Bitwarden Secrets Manager에 저장하고 External Secrets Operator를 통해 Kubernetes에서 사용합니다.
- 비밀이 아닌 도메인, 라우팅, 일반 설정 값은 기존 패턴에 따라 Git 관리 YAML에 둡니다.
- apply 전에 plan 결과를 검토하고, 의도 없는 파괴적 인프라 변경은 피합니다.
- `opnsense/`는 환경 의존적인 로컬 방화벽 자료로 간주하며, 관리 대상 플랫폼의 1차 source of truth로 보지 않습니다.

## Quick Example
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: gateway-public
spec:
  source:
    path: k8s/gateway/gateway-public
  destination:
    namespace: gateway
```

## 📂 Codebase References
- `terraform/do` - 표준 인프라 실행 래퍼
- `terraform/main.tf` - 루트 모듈 구성
- `terraform/modules/common/talos.tf` - Talos 부트스트랩과 클러스터 시퀀싱
- `terraform/modules/common/kubernetes.tf` - 초기 Kubernetes 리소스와 Bitwarden 시크릿 전달
- `terraform/modules/argocd/main.tf` - Argo CD 초기 설치
- `k8s/argocd/bootstrap/root-app.yaml` - GitOps 루트 진입점
- `k8s/argocd/manifests/apps/networking/gateway-public/application.yaml` - 대표적인 Argo CD Application 패턴
- `k8s/external-secrets/providers/bitwarden-clustersecretstore.yaml` - 시크릿 스토어 연동 패턴
- `k8s/elasticsearch/elasticsearch.yaml` - 상태 저장형 워크로드 패턴

## Validation Commands
- `cd terraform && tofu validate`
- `cd terraform && tofu fmt -check -recursive`
- `cd terraform && ./do plan`
- `yamllint -c .config/.yamllint -f parsable k8s/`
- `yamlfmt -conf .config/.yamlfmt -lint k8s/**/*.yaml k8s/**/*.yml`
- `kubeconform -summary -output text -ignore-missing-schemas k8s/`

## Operational Notes
- `terraform/do apply`는 apply 이후 health check, bootstrap 확인, kubeconfig 병합까지 이어지므로 단순 apply보다 더 넓은 운영 단계로 봐야 합니다.
- Gateway API, Longhorn, 기타 CRD-heavy 앱은 controller mutation과 defaulted field 때문에 Git diff만으로 상태를 단정하지 않습니다.
- `merge-kubeconfig`는 로컬 `~/.kube/config`를 수정하므로 공유 환경이나 기존 kubeconfig 사용 중일 때 특히 주의합니다.
- `opnsense/`는 참고용 환경 자료일 뿐, 현재 플랫폼 desired state의 주 관리 경로는 아닙니다.

## Related Files
- `business-domain.md` - 플랫폼의 비즈니스 맥락
- `business-tech-bridge.md` - 목표와 구현 방식의 연결
- `decisions-log.md` - 주요 기술 의사결정 기록
- `living-notes.md` - 현재 운영 이슈와 메모
