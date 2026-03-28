<!-- Context: project-intelligence/decisions | Priority: high | Version: 1.2 | Updated: 2026-03-28 -->

# Decisions Log

**Purpose**: 현재 플랫폼 구조를 만든 핵심 아키텍처 및 운영 결정을 기록합니다.
**Last Updated**: 2026-03-28

## Quick Reference
- **Audience**: 운영자, 기여자, AI 에이전트
- **Status Model**: Decided | Under Review | Deprecated
- **Focus**: 저장소 구조와 운영 원칙으로 확인 가능한 핵심 결정만 기록

## Decision: Terraform은 bootstrap까지만 담당하고, 장기 운영 서비스는 Argo CD가 관리한다

**Status**: Decided

### Context
클러스터 이전 단계의 인프라 생성과 클러스터 내부 서비스 운영은 서로 다른 성격의 문제입니다. 이 저장소는 VM 생성, Talos bootstrap, Cilium 설치, kubeconfig export, 초기 Argo CD 설치를 Terraform으로 처리하고, 이후 플랫폼 서비스는 GitOps로 관리합니다.

### Decision
Terraform의 책임은 인프라와 초기 bootstrap까지로 제한하고, 장기 운영되는 Kubernetes 서비스는 Argo CD 기준으로 관리합니다.

### Rationale
인프라 생성과 day-2 운영을 분리하면 변경 책임과 desired state의 소유권이 명확해집니다. 또한 장기 운영 리소스를 Terraform state에 과도하게 묶지 않게 됩니다.

### Alternatives Considered
| Alternative | 장점 | 단점 | 배제 이유 |
|-------------|------|------|-----------|
| 대부분의 플랫폼 앱도 Terraform으로 관리 | 도구 수 감소 | 운영 계층이 인프라 코드와 결합 | 저장소 원칙과 불일치 |
| Argo CD 수동 설치 | 단순해 보임 | 재현성과 bootstrap 자동화 약화 | 부트스트랩 자동화 목표와 어긋남 |
| 수동 `kubectl apply` 중심 운영 | 빠른 수동 대응 | drift 통제 어려움 | GitOps 운영 모델과 불일치 |

### Impact
- **Positive**: 책임 경계와 운영 모델이 명확해집니다.
- **Negative**: Terraform과 Argo CD 두 계층을 함께 이해해야 합니다.
- **Risk**: 같은 대상을 두 계층에서 중복 관리하면 drift가 발생할 수 있습니다.

### 📂 Codebase References
- `AGENTS.md`
- `terraform/main.tf`
- `terraform/modules/argocd/main.tf`
- `k8s/argocd/bootstrap/root-app.yaml`

---

## Decision: Kubernetes 노드는 Proxmox 위 Talos VM으로 구성한다

**Status**: Decided

### Context
이 저장소는 Proxmox 기반 VM provisioning과 Talos 기반 Kubernetes bootstrap을 전제로 설계되어 있습니다. 노드 네트워크, VIP, sysctl, machine config, kubeconfig export 흐름도 모두 이 구조에 맞춰져 있습니다.

### Decision
클러스터 노드는 Proxmox VM으로 만들고, 노드 OS와 bootstrap은 Talos를 사용합니다.

### Rationale
Talos는 불변형 운영 모델을 제공해 노드 drift를 줄이고, bootstrap 과정을 선언형으로 관리하기 좋습니다. Proxmox는 현재 homelab 환경의 기본 가상화 계층입니다.

### Alternatives Considered
| Alternative | 장점 | 단점 | 배제 이유 |
|-------------|------|------|-----------|
| 범용 Linux + kubeadm | 익숙한 운영 | 표준화와 재현성 약화 가능 | 현재 구조와 불일치 |
| 베어메탈 직접 운영 | 가상화 오버헤드 감소 | 현재 자동화 흐름 재설계 필요 | Proxmox 기반 저장소 구조와 다름 |
| 다른 배포판 사용 | 선택지 다양 | 기존 provider/flow 재설계 필요 | Talos 중심 구현이 이미 확립됨 |

### Impact
- **Positive**: 노드 구성과 bootstrap이 일관됩니다.
- **Negative**: Talos 운영 제약을 이해해야 합니다.
- **Risk**: Proxmox/SSH/Talos 초기화 실패가 전체 bootstrap을 막을 수 있습니다.

### 📂 Codebase References
- `terraform/modules/common/proxmox.tf`
- `terraform/modules/common/talos.tf`
- `terraform/modules/common/output.tf`

---

## Decision: Cilium과 Gateway API를 기본 네트워킹 모델로 사용한다

**Status**: Decided

### Context
기본 CNI 대신 Cilium을 bootstrap 단계에서 설치하고, gateway 리소스도 `gatewayClassName: cilium`을 기준으로 구성되어 있습니다. public/internal gateway와 L2 announcement 기반 IP 관리가 이 모델에 맞춰집니다.

### Decision
클러스터 네트워킹은 Cilium을 중심으로 구성하고, 서비스 노출은 Gateway API 패턴을 사용합니다.

### Rationale
네트워킹, 게이트웨이, 일부 observability 경로를 하나의 일관된 모델로 가져갈 수 있기 때문입니다. ingress controller 조합보다 현재 저장소 구조와 잘 맞습니다.

### Alternatives Considered
| Alternative | 장점 | 단점 | 배제 이유 |
|-------------|------|------|-----------|
| 별도 Ingress Controller 중심 설계 | 익숙함 | 모델 이원화 | 현재 게이트웨이 구조와 불일치 |
| MetalLB + 별도 네트워크 조합 | 전통적 조합 | 도구 증가 | 현재 Cilium 기능으로 대체 가능 |
| 다른 CNI 사용 | 선택지 다양 | bootstrap 흐름 재설계 필요 | 기존 구현과 다름 |

### Impact
- **Positive**: 네트워킹과 노출 정책이 일관됩니다.
- **Negative**: Cilium 의존성이 커집니다.
- **Risk**: Cilium/Gateway API 변경이 라우팅 전체에 영향을 줍니다.

### 📂 Codebase References
- `terraform/modules/common/cilium.tf`
- `k8s/gateway/gateway-public/gateway.yaml`
- `k8s/gateway/gateway-internal/gateway.yaml`

---

## Decision: 시크릿은 Bitwarden + External Secrets Operator로 관리한다

**Status**: Decided

### Context
저장소는 Git에 비밀값을 넣지 않는 것을 기본 원칙으로 삼고 있습니다. bootstrap 단계에서는 최소 credential만 전달하고, 실제 런타임 시크릿은 외부 시크릿 저장소에서 가져옵니다.

### Decision
운영 시크릿은 Bitwarden Secrets Manager를 원천 저장소로 사용하고, Kubernetes에는 External Secrets Operator가 동기화합니다.

### Rationale
선언형 운영을 유지하면서도 시크릿을 Git과 분리할 수 있습니다. 또한 bootstrap credential과 런타임 시크릿의 책임 경계도 명확해집니다.

### Alternatives Considered
| Alternative | 장점 | 단점 | 배제 이유 |
|-------------|------|------|-----------|
| Git에 Kubernetes Secret 저장 | 구조 단순 | 비밀 유출 위험 | 저장소 원칙 위반 |
| Terraform이 모든 앱 시크릿 생성 | 일원화 가능 | 장기 운영 시크릿이 인프라 계층과 결합 | 운영 모델과 부적합 |
| 다른 시크릿 백엔드 사용 | 유연성 | 현재 구현과 불일치 | Bitwarden 연동이 이미 존재 |

### Impact
- **Positive**: Git에서 비밀이 분리됩니다.
- **Negative**: 외부 의존성과 bootstrap 복잡도가 증가합니다.
- **Risk**: provider나 bootstrap token 오류 시 여러 앱이 동시에 영향을 받습니다.

### 📂 Codebase References
- `AGENTS.md`
- `terraform/modules/common/kubernetes.tf`
- `k8s/external-secrets/providers/bitwarden-clustersecretstore.yaml`
- `k8s/external-secrets/providers/bitwarden-sdk-server-certificate.yaml`

---

## Decision: 공개 트래픽과 내부 트래픽, 신뢰 체인은 분리한다

**Status**: Decided

### Context
저장소는 `gateway-public`과 `gateway-internal`를 분리하고, public certificate와 internal CA/trust bundle도 별도로 운영합니다. namespace label과 trust injection 규칙도 명시되어 있습니다.

### Decision
외부 공개 경로와 내부 서비스 경로를 서로 다른 gateway, 인증서, 신뢰 체계로 분리합니다.

### Rationale
내부와 외부는 보안 요구와 운영 정책이 다르기 때문입니다. 이 경계를 플랫폼 수준에서 명시적으로 관리하면 개별 서비스 설정 오류를 줄일 수 있습니다.

### Alternatives Considered
| Alternative | 장점 | 단점 | 배제 이유 |
|-------------|------|------|-----------|
| 하나의 gateway/인증 체계로 통합 | 단순함 | 경계가 흐려짐 | 현재 정책과 불일치 |
| 내부도 공인 인증서만 사용 | 공인 신뢰 활용 | 내부 이름체계/워크로드에 비효율 | 내부 CA 설계가 존재 |
| 앱별 개별 CA 배포 | 독립성 | 관리 중복 | trust bundle 방식보다 비효율 |

### Impact
- **Positive**: 노출면과 신뢰 체계가 명확해집니다.
- **Negative**: 인증서와 gateway 구성이 이원화됩니다.
- **Risk**: issuer, label, bundle 순서가 어긋나면 TLS나 라우팅 문제가 생길 수 있습니다.

### 📂 Codebase References
- `k8s/argocd/manifests/apps/networking/gateway-public/application.yaml`
- `k8s/argocd/manifests/apps/networking/gateway-internal/application.yaml`
- `k8s/cert-manager/clusterissuers/letsencrypt-public.yaml`
- `k8s/trust-manager/bundles/homelab-internal-ca-bundle.yaml`

## Related Files
- `technical-domain.md` - 현재 기술 구조
- `business-tech-bridge.md` - 왜 이런 기술을 선택했는지
- `living-notes.md` - 현재 유지보수 시 주의점
