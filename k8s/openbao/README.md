# How to deploy OpenBao with Kubernetes Auth Method
## Initialize OpenBao
### 1. Initialize OpenBao operator
Copy the unseal keys and root token from the output of this command
```bash
kubectl exec -n openbao openbao-0 -- bao operator init
```

### 2. Unseal OpenBao
Do this step 3 times with different unseal keys
```bash
kubectl exec -n openbao openbao-0 -- bao operator unseal
```

### 3. Join other OpenBao nodes
```bash
kubectl exec -n openbao openbao-1 -- bao operator raft join https://openbao-0.openbao-internal:8200 
kubectl exec -n openbao openbao-2 -- bao operator raft join https://openbao-0.openbao-internal:8200
```

### 4. Unseal other OpenBao nodes
Do this step 3 times with different unseal keys
```bash
kubectl exec -n openbao openbao-1 -- bao operator unseal
kubectl exec -n openbao openbao-2 -- bao operator unseal
```

## Configure Kubernetes Auth Method
### 1. Create a Service Account for External Secrets Operator
This step is performed automatically by argocd.

### 2. Access the pod using the exec command
```bash
kubectl exec -n openbao -it openbao-0 -- /bin/sh
```

### 3. Login to OpenBao with the root token
```bash
bao login
```

### 4. Enable Kubernetes Auth Method and create a role for External Secrets Operator
```bash
bao auth enable kubernetes
```
```bash
bao write auth/kubernetes/config \
	kubernetes_host="https://kubernetes.default.svc:443" \
	disable_iss_validation=true
```
```bash
bao policy write external-secrets - <<'EOF'
  path "secret/data/*" {
    capabilities = ["read", "list"]
  }

  path "secret/metadata/*" {
    capabilities = ["read", "list"]
  }
EOF
```
```bash
bao write auth/kubernetes/role/external-secrets \
	bound_service_account_names=external-secrets-auth \
	bound_service_account_namespaces=external-secrets \
	policies=external-secrets \
	ttl=1h \
	max_ttl=24h
```

### 5. Enable KV Secrets Engine
```bash
bao secrets enable -path=secret kv-v2
```

### 6. Create a Kubernetes Secret for OpenBao
This step is performed automatically by argocd.

### 7. Create an ClusterSecretStore
This step is performed automatically by argocd.