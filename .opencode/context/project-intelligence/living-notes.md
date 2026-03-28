<!-- Context: project-intelligence/notes | Priority: high | Version: 1.2 | Updated: 2026-03-28 -->

# Living Notes

**Purpose**: 현재 운영 상태, 기술 부채, 알려진 주의점, 유지보수자가 알아야 할 메모를 기록합니다.
**Last Updated**: 2026-03-28

## Quick Reference
- **Audience**: 운영자, 기여자, AI 에이전트
- **Update When**: 운영 이슈, 구조 변화, 문서 drift 발견 시
- **Focus**: "지금 이 저장소를 안전하게 다루려면 무엇을 알아야 하는가"

## Technical Debt
| 항목 | 영향 | 우선순위 | 대응 방향 |
|------|------|----------|-----------|
| observability 영역 문서 반영 부족 | 실제 구조와 문서 설명이 어긋날 수 있음 | medium | Project Intelligence와 AGENTS 간 설명 정합성 유지 |
| drift 억제 비용 증가 | ignoreDifferences와 defaulted field 관리 부담 | high | drift 패턴을 문서화하고 변경 시 live 상태 확인 |
| bootstrap 흐름 결합도 높음 | apply 실패 시 원인 분리가 어려움 | high | 단계별 실패 지점을 더 명확히 문서화 |
| 환경 상수 하드코딩 | 재사용성과 이식성 저하 | medium | 환경별 상수 목록을 점진적으로 분리 검토 |

## Open Questions
| 질문 | 관련자 | 상태 | 다음 액션 |
|------|--------|------|-----------|
| observability가 핵심 운영 영역으로 완전히 확정되었는가 | 운영자 | open | 문서와 프로젝트 설명에 일관되게 반영 |
| root app이 항상 `main` 브랜치를 보도록 한 정책이 의도된 고정값인가 | 운영자 | open | bootstrap 검증 전략과 함께 재확인 |
| 일부 보안 예외 설정이 현재도 수용 가능한가 | 운영자 | open | `argocd insecure`, privileged 정책, trust-manager 설정 재검토 |
| 로컬 generated 민감 산출물 회전/정리 정책이 충분한가 | 운영자 | open | output/state 파일 운영 규칙 정리 |

## Known Issues
- fresh apply 실패는 종종 Argo CD보다 Proxmox/SSH 전제조건 문제에서 먼저 발생합니다.
- Gateway API와 CRD-heavy 앱은 false drift가 발생하기 쉬워 live default 값을 함께 확인해야 합니다.
- Longhorn은 CRD drift를 무시하도록 설계되어 있어 실제 문제와 expected mutation을 구분해야 합니다.
- trust bundle 관련 앱은 CRD 생성 순서에 민감합니다.
- Elasticsearch는 cert-manager CSI driver 선행 의존성이 있습니다.

## Patterns Worth Preserving
- Terraform은 bootstrap까지만, 장기 운영 앱은 Argo CD가 관리하는 구조
- sync-wave 기반 의존성 계층화
- Helm chart + Git values/manifests를 혼합하는 multi-source Application 패턴
- `expose` 라벨과 trust injection 라벨을 통한 정책 표현
- generated artifact와 선언형 소스를 분리하는 원칙
- repo-native validation 명령을 우선하는 운영 습관

## Maintainer Gotchas
- OpenTofu는 항상 `terraform/`에서 실행하고, 보통 `terraform/do`를 우선 사용해야 합니다.
- `terraform/do apply`는 선행 plan 파일과 후속 health/bootstrap 검사를 전제로 합니다.
- `merge-kubeconfig`는 로컬 `~/.kube/config`를 직접 수정하므로 주의가 필요합니다.
- values 파일은 일부 검증 흐름에서 제외되므로 Helm/Argo 관점 검토가 추가로 필요합니다.
- bootstrap token, kubeconfig, talosconfig, state 파일은 모두 민감 정보로 다뤄야 합니다.
- `opnsense/`는 환경 종속 자료이며, 현재 관리 대상 플랫폼의 desired state 기준은 아닙니다.
- deprecated된 `openbao` 경로나 과거 Terraform-managed 앱 구조를 되살리지 않는 것이 현재 원칙입니다.

## Lessons Learned
- 이 저장소에서는 "Git을 고치는 것"이 "클러스터를 직접 고치는 것"보다 우선입니다.
- operator/CRD 중심 플랫폼에서는 drift가 항상 오류를 의미하지 않습니다.
- bootstrap 자동화가 강할수록 순서와 책임 경계를 문서로 남기는 것이 중요합니다.
- generated artifact와 secret material을 코드와 섞지 않는 습관이 운영 안정성을 높입니다.

## 📂 Codebase References
- `AGENTS.md` - 운영 규칙, gotcha, 검증 기준
- `terraform/do` - 강하게 결합된 bootstrap 흐름
- `terraform/modules/argocd/main.tf` - Argo CD bootstrap 세부
- `k8s/argocd/bootstrap/root-app.yaml` - root app 고정 경로
- `k8s/argocd/manifests/projects/observability.yaml` - observability 영역 존재
- `k8s/argocd/manifests/apps/storage/longhorn/application.yaml` - drift 처리 예시
- `k8s/argocd/manifests/apps/monitoring/kube-prometheus-stack/application.yaml` - monitoring 운영 패턴
- `k8s/gateway/gateway-public/gateway.yaml` - 노출 정책 예시
- `.github/workflows/k8s-lint.yml` - 저장소 검증 패턴
- `.github/workflows/terraform-lint.yml` - Terraform 검증 패턴

## Related Files
- `technical-domain.md` - 기술 구조와 표준
- `decisions-log.md` - 현재 상태를 만든 결정들
- `business-domain.md` - 운영 목적과 우선순위
- `business-tech-bridge.md` - 운영 요구와 기술 선택의 연결
