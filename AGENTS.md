# AGENTS.md

## Purpose
This repo manages a homelab stack with OpenTofu/Terraform, Talos, Proxmox, ArgoCD, and Kubernetes manifests.
Agents should prefer repo-native validation and existing patterns over generic app assumptions.

## Repository Map
- `terraform/`: provisioning, providers, modules, outputs, and the `./do` wrapper.
- `terraform/modules/`: active infrastructure modules are primarily `common` and `argocd`.
- `k8s/`: GitOps-managed manifests and Helm values.
- `.github/workflows/`: CI-enforced lint and validation commands.
- `opnsense/`: local firewall-related material; treat as environment-specific.

## Cursor / Copilot Rules
- No `.cursor/rules/` directory found.
- No `.cursorrules` file found.
- No `.github/copilot-instructions.md` file found.

## Core Working Rules
- Run OpenTofu commands from `terraform/`, not repo root.
- Prefer `terraform/do` for plan/apply/health/info workflows.
- Treat `terraform/output/`, `terraform/temp/`, and `terraform/logs/` as generated.
- Never commit `terraform.tfvars`, kubeconfigs, Talos configs, exported certs, or other secrets.
- Preserve existing module and manifest patterns instead of inventing parallel structures.
- Terraform bootstraps the cluster and seeds ArgoCD; platform services are ArgoCD-managed from `k8s/argocd/manifests`.
- Secrets belong in Bitwarden Secrets Manager; Kubernetes consumes them through External Secrets Operator.
- Keep non-secret values such as domains and route hostnames in plain Git-managed YAML unless the repo already uses a secret-backed path.

## Current Platform Layout
- Terraform responsibility: Proxmox VMs, Talos bootstrap, Cilium, kubeconfig/talosconfig export, initial ArgoCD install, bootstrap secret for Bitwarden access.
- ArgoCD responsibility: `cert-manager`, `cert-manager-csi-driver`, `trust-manager`, `external-secrets`, `gateway-public`, `gateway-internal`, `longhorn`, `kube-prometheus-stack`, and `elasticsearch`.
- Root bootstrap app: `k8s/argocd/bootstrap/root-app.yaml` points at `k8s/argocd/manifests` and recurses child Applications.
- Main AppProjects: `infrastructure`, `networking`, `storage`, `monitoring`, `database`.
- Intentionally removed: `openbao` is not part of the desired state anymore.

## Build / Validate Commands
There is no traditional application build. The closest equivalents are planning, linting, formatting, and manifest validation.

### OpenTofu / Terraform
Run from `terraform/`:

```bash
./do init
./do plan
./do apply
./do plan-apply
./do health
./do info
./do merge-kubeconfig
./do destroy
```

Direct commands matching CI behavior:

```bash
tofu validate
tofu fmt -check -recursive
tofu fmt -recursive
```

- `./do plan` writes `terraform/temp/tfplan`.
- `./do apply` expects that plan, then exports kubeconfig/talosconfig, runs health checks, exports the internal CA cert, and merges kubeconfig.
- Fresh-cluster applies may need bootstrap awareness: the repo now supports full bootstrap, but failures are usually from Proxmox/SSH prerequisites rather than ArgoCD manifests.

### Kubernetes / YAML
Repository-wide checks:

```bash
yamllint -c .config/.yamllint -f parsable k8s/
yamlfmt -conf .config/.yamlfmt -lint k8s/**/*.yaml k8s/**/*.yml
yamlfmt -conf .config/.yamlfmt k8s/
kubeconform -summary -output text \
  -cache ~/.cache/kubeconform \
  -schema-location default \
  -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' \
  -ignore-missing-schemas \
  -ignore-filename-pattern '/values/' \
  k8s/
```

Per-file checks:

```bash
yamllint -c .config/.yamllint path/to/file.yaml
yamlfmt -conf .config/.yamlfmt -lint path/to/file.yaml
kubectl apply --dry-run=client -f path/to/file.yaml
kubeconform -summary -output text \
  -schema-location default \
  -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' \
  -ignore-missing-schemas \
  path/to/file.yaml
```

Validation config already in repo:
- `.config/.yamllint` warns on lines over 120 chars and ignores `**/values/*.yaml` and `**/values/*.yml`.
- `.config/.yamlfmt` enforces `---` document starts and also excludes values files.

### Useful operational checks

```bash
kubectl --kubeconfig terraform/output/kubeconfig.yml get applications -n argocd
kubectl --kubeconfig terraform/output/kubeconfig.yml get gateways,httproutes -A
kubectl --kubeconfig terraform/output/kubeconfig.yml get certificates,clusterissuers -A
kubectl --kubeconfig terraform/output/kubeconfig.yml get externalsecrets,clustersecretstores -A
kubectl --kubeconfig terraform/output/kubeconfig.yml get pods -A
```

## Test Commands
There is no unit-test or integration-test framework checked in.
If a task asks to "run tests", use the validation flow that matches the changed area.

### Terraform change validation

```bash
cd terraform
tofu validate
tofu fmt -check -recursive
./do plan
```

### Kubernetes manifest validation

```bash
yamllint -c .config/.yamllint path/to/manifest.yaml
yamlfmt -conf .config/.yamlfmt -lint path/to/manifest.yaml
kubectl apply --dry-run=client -f path/to/manifest.yaml
kubeconform ... path/to/manifest.yaml
```

### Single-test guidance
- There is no runner like `pytest path::test_name` or `go test ./pkg -run TestName`.
- Terraform validation is config-wide; there is no per-resource test target.
- The nearest equivalent is single-file validation for the YAML or manifest you changed.
- For Kubernetes, prefer per-file `yamllint`, `yamlfmt -lint`, `kubectl apply --dry-run=client`, and `kubeconform`.
- For ArgoCD changes, the closest runtime check is `kubectl get application <name> -n argocd -o yaml` plus the target namespace resources.

## Code Style Guidelines

### General
- Match the existing style in the file before introducing new patterns.
- Keep edits minimal and scoped; this repo is config-heavy and diff readability matters.
- Prefer descriptive names over abbreviations.
- Avoid comments for obvious code; add short comments only when the intent is not obvious.
- Keep secrets out of committed files, examples, and diffs.

### Terraform / OpenTofu
- Use `tofu fmt` style for spacing and alignment.
- Keep top-level files conventional: `main.tf`, `variables.tf`, `providers.tf`, `output.tf`.
- Use lowercase snake_case for variables, locals, outputs, and resource labels.
- Use module names that reflect the concern, such as `common` or `argocd`.
- Always declare variable `type`; include `description`; set `sensitive = true` for secrets.
- Prefer explicit version pinning for providers and major platform components.
- Prefer `locals` for repeated structures and computed manifests.
- Keep provider/module references explicit and readable.
- Reuse existing locals and outputs instead of duplicating literals.
- Preserve provider alias usage when cluster access depends on `module.common` outputs.
- Keep `depends_on` explicit where ordering is operationally important.
- Keep bootstrap-only concerns in Terraform; do not move long-lived platform apps back into Terraform modules.

### Terraform Types, Naming, and References
- Use precise object types for structured inputs like node lists and app config.
- Prefer explicit booleans, numbers, and strings over loosely shaped maps when schema is known.
- Resource labels should be descriptive and singular/plural based on intent.
- Prefer direct references like `kubernetes_namespace.argocd.metadata[0].name` when they improve consistency.

### YAML / Kubernetes
- Use 2-space indentation.
- Start manifest files with `---` unless you are editing excluded values files that do not currently use it.
- Keep field order conventional: `apiVersion`, `kind`, `metadata`, `spec`.
- Use lowercase kebab-case resource names and directory names.
- Keep namespaces explicit when the resource is namespaced.
- Match the existing ArgoCD single-source or multi-source pattern in the surrounding app; do not convert styles without need.
- Keep Helm values in `k8s/<service>/values/values.yaml`.
- Do not aggressively reformat values files; they are excluded from repo formatting.
- Common filenames are `application.yaml`, `kustomization.yaml`, `values.yaml`, `httproute.yaml`, `certificate.yaml`, and `namespace.yaml`.
- For Gateway API resources, match live defaulted fields in Git when ArgoCD reports persistent drift, e.g. explicit `group: ""`, `kind: Service`, and `requestRedirect.statusCode: 302`.
- Trust bundle injection uses `trust.cert-manager.io/inject: "true"`; prefer that label over older variants.

### ArgoCD Patterns
- Root bootstrap lives in `k8s/argocd/bootstrap/root-app.yaml`; child Applications live under `k8s/argocd/manifests/apps/`.
- Use sync waves to express platform dependencies: CRDs/operators first, then issuers/secrets, then certificates/gateways/routes.
- `cert-manager` is installed separately from `cert-manager-resources`; `cert-manager-csi-driver` is its own Application and is required by Elasticsearch.
- `external-secrets` is split into CRDs, operator, providers, and actual ExternalSecret resources.
- Longhorn is Helm-managed with ArgoCD `ignoreDifferences` for CRD drift; do not try to mirror webhook-injected CRD data in Git.
- When investigating app drift, inspect both `kubectl get application -n argocd <app> -o yaml` and the live resource defaults before changing manifests.

### Error Handling and Safety
- In shell scripts, keep `set -euo pipefail`.
- Fail early on missing dependencies or missing generated files.
- For destructive infrastructure actions, prefer `./do plan` before `./do apply` or `./do destroy`.
- Review plan output for unintended deletions or replacements.
- For manifest changes, run dry-run and schema checks before assuming ArgoCD will reconcile cleanly.
- Proxmox operations require working SSH agent authentication for the configured `terraform` user on each node.
- If `./do apply` fails after cluster creation, check whether the failure is in post-apply health/bootstrap steps rather than resource provisioning itself.

## Verification Expectations
- Terraform edits: run `tofu validate`, `tofu fmt -check -recursive`, and usually `./do plan`.
- K8s manifest edits: run `yamllint`, `yamlfmt -lint`, and `kubeconform`; add `kubectl apply --dry-run=client` when direct kubectl compatibility matters.
- Routing or certificate changes: also inspect `kubectl get gateways -A`, `kubectl get httproutes -A`, and `kubectl get certificates -A` when cluster access is available.
- Secret-store changes: also inspect `kubectl get clustersecretstores -A`, `kubectl get externalsecrets -A`, and controller logs in `external-secrets`.
- Storage changes: also inspect `kubectl get storageclass`, `kubectl get pvc -A`, and `kubectl get pods -n longhorn-system`.
- Elasticsearch changes: confirm `kubectl get pods -n elastic-system` and ensure the `csi.cert-manager.io` driver is present.

## Practical Advice For Agents
- Read `.github/workflows/terraform-lint.yml` and `.github/workflows/k8s-lint.yml` before inventing validation steps.
- Prefer improving existing manifests/modules over creating new patterns.
- If a task mentions tests, explain that validation replaces tests here and list the exact commands you ran.
- If a task touches secrets or credentials, stop short of committing secret material and call it out clearly.
- Do not resurrect deprecated paths from older notes or deleted modules such as Terraform-managed `gateway`, `longhorn`, `cert-manager`, or `openbao` resources.
- If ArgoCD shows `OutOfSync` on Gateway API or CRD-heavy apps, check for defaulted fields or controller-mutated CRD sections before assuming a real config mismatch.
