# 배포 아키텍처 (Deployment Architecture)

이 문서는 homelab Kubernetes 플랫폼의 **서비스 배포 구조**를 설명한다.
배포는 GitOps 원칙을 따른다 — Git이 desired state의 단일 출처(SSOT)이고, Argo CD가 클러스터를 거기에 맞춰 동기화한다.

## 1. 책임 경계: Terraform vs Argo CD

| 영역 | 담당 | 범위 |
|---|---|---|
| **부트스트랩** | OpenTofu/Terraform (`terraform/`) | Proxmox VM, Talos, Cilium, kubeconfig/talosconfig 출력, Argo CD seed 설치, 최소 secret 부트스트랩 |
| **장기 플랫폼** | Argo CD (`k8s/argocd/manifests`) | cert-manager, trust-manager, External Secrets, Gateway, Longhorn, kube-prometheus-stack, Signoz 등 |

> 원칙: Argo CD가 관리하는 서비스를 Terraform으로 되돌리지 않는다. 수동 클러스터 변경을 SSOT로 만들지 않는다.

## 2. App of Apps 구조

이 레포는 **App of Apps** 패턴을 쓴다. ApplicationSet은 쓰지 않는다.

```
terraform (seed)
   └─ root Application: bootstrap-infrastructure   (k8s/argocd/bootstrap/root-app.yaml)
        │  source.path: k8s/argocd/manifests
        │  directory.recurse: true          ← manifests/ 하위 YAML을 재귀 발견
        ├─ projects/*.yaml                  → AppProject 5개 (RBAC/리소스 경계)
        └─ apps/<domain>/<app>/application.yaml → child Application 다수
                                               각 앱이 실제 서비스를 배포
```

### App of Apps를 쓰는 이유 (ApplicationSet이 아니라)

- **단일 클러스터 + 엄격한 순서 제어**가 필요하다. 부트스트랩 의존성(CRD → operator → 리소스)을
  `sync-wave`로 정밀하게 묶어야 하는데, App of Apps + 명시적 Application이 이를 가장 투명하게 표현한다.
- ApplicationSet은 **다수 클러스터/대량 동종 앱을 템플릿으로 자동 생성**할 때 빛난다. 현재 규모(앱 ~18개,
  클러스터 1개)에서는 추상화 비용만 늘고 이득이 적다.
- 향후 멀티 클러스터로 확장하면 ApplicationSet 도입을 재검토한다.

### AppProject (도메인 경계)

`k8s/argocd/manifests/projects/` 의 5개 AppProject가 RBAC와 허용 소스/대상을 제한한다.

| Project | 책임 서비스 | 허용 네임스페이스 |
|---|---|---|
| `infrastructure` | cert-manager, trust-manager, External Secrets | cert-manager, external-secrets, trust-manager, argocd |
| `networking` | Gateway API (internal/public) | gateway-internal, gateway-public |
| `storage` | Longhorn | longhorn-system |
| `monitoring` | kube-prometheus-stack | monitoring |
| `observability` | Signoz | signoz, argocd |

> `apps/` 하위 디렉터리(`infrastructure/`, `monitoring/` 등)는 이 AppProject 경계와 1:1로 묶인다.
> 즉 `apps/`의 도메인 그룹핑은 RBAC 구조이지 서비스 매니페스트의 위치 규칙이 아니다 (§4 참고).

## 3. 3계층 배포 모델

모든 서비스는 다음 세 계층의 조합으로 배포된다.

```
① 외부 Helm 차트         (charts.jetstack.io, charts.longhorn.io, …)   — 업스트림이 관리
② 로컬 values            k8s/<service>/values/values.yaml             — 우리가 git으로 관리
③ Kustomize 부가 리소스   k8s/<service>/  (kustomization.yaml + raw yaml) — 차트가 안 주는 것
```

- **① + ②** 는 Argo CD **multi-source**로 결합한다 (§5).
- **③** 은 차트로 표현 불가능한 리소스 — HTTPRoute, Certificate, ExternalSecret, ClusterSecretStore 등 —
  를 담고, 별도 Application의 `path:` 소스로 배포한다.

서비스마다 이 세 계층을 전부 쓰는 것은 아니다. 예: cert-manager는 ①②(차트) + ③(ClusterIssuer/Certificate)를
**서로 다른 두 Application**(`cert-manager`, `cert-manager-resources`)으로 나눠 배포한다.

## 4. 디렉터리 규칙

### 서비스 매니페스트: `k8s/<service>/` (평탄)

```
k8s/
├── argocd/                     # Argo CD 자체 + App of Apps 매니페스트
│   ├── bootstrap/root-app.yaml
│   ├── manifests/projects/     # AppProject
│   ├── manifests/apps/         # child Application (도메인별)
│   └── system/                 # Argo CD UI route 등
├── cert-manager/
│   ├── values/values.yaml      # ② Helm values
│   ├── clusterissuers/         # ③ 부가 리소스
│   ├── certificates/
│   └── kustomization.yaml
├── external-secrets/
│   ├── values/values.yaml
│   ├── providers/              # ClusterSecretStore
│   └── externalsecrets/        # ExternalSecret
├── gateway/{gateway-internal,gateway-public}/
├── kube-prometheus-stack/values/values.yaml
├── longhorn/{values/,kustomization.yaml,httproute.yaml,…}
├── signoz/{values/,kustomization.yaml,…}
├── signoz-k8s-infra/values/values.yaml
└── trust-manager/{values/,bundles/}
```

규칙:
- 서비스는 항상 **`k8s/<service>/` 최상위 평탄 디렉터리**다. 도메인(`monitoring/`, `observability/`)으로
  중첩하지 않는다 — 도메인 그룹핑은 `apps/`(AppProject)에서만 한다.
- Helm values는 항상 **`k8s/<service>/values/values.yaml`**.
- 부가 리소스는 `kustomization.yaml`로 묶는다.

### Argo CD Application: `apps/<domain>/<app>/application.yaml`

도메인 = AppProject. 한 서비스가 여러 Application으로 쪼개질 수 있다 (차트 / 부가 리소스 / CRD 분리).

## 5. Helm + Argo CD 공존 방식

Argo CD가 **외부 Helm 차트**를 직접 배포하고, **values는 이 git 레포에서** 가져와 병합한다.
방식은 Argo CD 공식 권장인 **multi-source + `$values` ref** 로 **통일**한다.

```yaml
# k8s/argocd/manifests/apps/infrastructure/cert-manager/application.yaml
spec:
  sources:
    - repoURL: https://charts.jetstack.io     # ① 외부 차트
      chart: cert-manager
      targetRevision: v1.20.2
      helm:
        valueFiles:
          - $values/k8s/cert-manager/values/values.yaml   # ② 로컬 values 참조
    - repoURL: https://github.com/pressogh/homelab.git     # $values 심볼릭 소스
      targetRevision: main
      ref: values
```

규칙:
- **inline `valuesObject` 금지.** Helm values는 언제나 `valueFiles`로 외부화한다.
- values 파일 경로는 `$values/k8s/<service>/values/values.yaml`.
- 두 번째 소스(`ref: values`)는 **manifest를 만들지 않는** 심볼릭 참조이며 `path`/`chart`가 없어야 한다.
- 차트가 **override할 values가 전혀 없으면** 단일 `source`(차트만)도 허용한다. 예: `cert-manager-csi-driver`.
  values가 생기는 순간 위 multi-source 형태로 전환한다.

> 왜 inline `valuesObject`가 아니라 외부 `valueFiles`인가: values가 `k8s/<service>/values/`에 일관 위치해 발견·diff·리뷰가
> 쉽고, Application manifest는 "참조"만 담아 가벼워진다. 큰 values(예: kube-prometheus-stack ~390줄)도
> Application을 비대하게 만들지 않는다.

### Kustomize란 / 언제 쓰나

Kustomize는 raw Kubernetes YAML을 **템플릿 없이 선언적으로 묶고 변형**하는 도구다 (`kubectl`/Argo CD 내장).
`kustomization.yaml`에 `resources:` 목록을 적으면 그 파일들이 하나의 단위로 적용된다.

이 레포에서 Kustomize의 역할은 **Helm 차트가 제공하지 않는 부가 리소스를 묶는 것**이다:

| 위치 | 묶는 리소스 |
|---|---|
| `k8s/cert-manager/` | ClusterIssuer, Certificate |
| `k8s/external-secrets/providers/` | ClusterSecretStore |
| `k8s/external-secrets/externalsecrets/` | ExternalSecret |
| `k8s/gateway/gateway-*/` | Gateway, Certificate, HTTPRoute |
| `k8s/longhorn/` | HTTPRoute, R2 백업 ExternalSecret |
| `k8s/signoz/` | HTTPRoute, ClickHouse Service |

이 디렉터리는 Application의 `path:` 소스로 배포된다 (Helm 차트와 별개 Application이거나, signoz처럼
같은 Application의 세 번째 소스로 결합된다).

## 6. Sync Wave (배포 순서)

Argo CD는 `argocd.argoproj.io/sync-wave` 주석으로 의존성 순서를 제어한다. 낮은 값이 먼저 동기화된다.

| Wave | 배포 대상 | 의존 이유 |
|---|---|---|
| **-5** | AppProject 정의 | 모든 앱의 전제 |
| **-4** | external-secrets CRD | operator 선행 |
| **-3** | external-secrets-operator | CRD 대기 |
| **-2** | cert-manager, external-secrets-providers | |
| **-1** | cert-manager-csi-driver, kube-prometheus-stack CRD | |
| **0** | trust-manager, external-secrets (ExternalSecret) | operator/issuer 대기 |
| **1** | trust-bundles | trust-manager 대기 |
| **2** | gateway-internal/public, longhorn-routes | |
| **3** | argocd-config, longhorn, signoz | CRD/게이트웨이 완료 후 |
| **4** | signoz-k8s-infra | signoz 대기 |

## 7. 규칙 요약 (conventions)

| 구분 | 규칙 |
|---|---|
| 앱 부트스트랩 | App of Apps (`bootstrap-infrastructure` → `manifests/` recurse). ApplicationSet 미사용 |
| Application 위치 | `k8s/argocd/manifests/apps/<domain>/<app>/application.yaml` (도메인 = AppProject) |
| 서비스 매니페스트 위치 | `k8s/<service>/` 평탄 구조 (도메인 중첩 금지) |
| Helm values | 항상 외부 `valueFiles` + multi-source `ref: values`. inline `valuesObject` 금지 |
| values 경로 | `k8s/<service>/values/values.yaml` |
| 부가 리소스 | `kustomization.yaml`로 묶어 `path:` 소스로 배포 |
| 네임스페이스 라벨 | `managedNamespaceMetadata`로 Pod Security / `trust.cert-manager.io/inject` 등 관리 |
| 순서 제어 | `sync-wave` 주석 |

## 8. 검증

변경 영역에 맞는 명령을 쓴다 (CI와 동일).

```bash
# YAML lint/format
yamllint -c .config/.yamllint -f parsable k8s/
yamlfmt -conf .config/.yamlfmt -lint k8s/**/*.yaml k8s/**/*.yml

# 스키마 검증 (values 제외)
kubeconform -summary -output text -ignore-missing-schemas \
  -schema-location default \
  -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' \
  -ignore-filename-pattern '/values/' k8s/

# 클러스터 접근 시: 동기화/드리프트 확인
kubectl --kubeconfig terraform/output/kubeconfig.yml get applications -n argocd -o wide
# argocd app diff <app>  로 렌더 결과가 변하지 않았는지(drift 0) 확인
```

> `**/values/` 의 values.yaml은 yamllint/yamlfmt/kubeconform 대상에서 의도적으로 제외된다 (Helm 입력이라
> Kubernetes 스키마를 따르지 않음).
