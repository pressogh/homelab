#!/bin/bash
set -euo pipefail

export CHECKPOINT_DISABLE='1'
export TF_LOG='DEBUG' # TRACE, DEBUG, INFO, WARN or ERROR.
export TF_LOG_PATH='logs/terraform.log'

export TALOSCONFIG=$PWD/output/talosconfig.yml
export KUBECONFIG=$PWD/output/kubeconfig.yml

function step {
  echo "### $* ###"
}

function init {
  step 'terraform init'
  terraform init -lockfile=readonly
}

function plan {
  step 'terraform plan'
  terraform plan -out=temp/tfplan
}

function apply {
  step 'terraform apply'
  terraform apply temp/tfplan
  terraform output -raw talosconfig > output/talosconfig.yml
  terraform output -raw kubeconfig > output/kubeconfig.yml
  health
  install-gateway-api-crd
  export-kubernetes-internal-ca-crt
  info
  merge-kubeconfig
}

function health {
  step 'talosctl health'
  local controllers="$(terraform output -raw controllers)"
  local workers="$(terraform output -raw workers)"
  local c0="$(echo $controllers | cut -d , -f 1)"
  talosctl -e $c0 -n $c0 \
    health \
    --control-plane-nodes $controllers \
    --worker-nodes $workers
}

function info {
  local controllers="$(terraform output -raw controllers)"
  local workers="$(terraform output -raw workers)"
  local nodes=($(echo "$controllers,$workers" | tr ',' ' '))
  step 'talos node installer image'
  for n in "${nodes[@]}"; do
    # NB there can be multiple machineconfigs in a machine. we only want to see
    #    the ones with an id that looks like a version tag.
    talosctl -n $n get machineconfigs -o json \
      | jq -r 'select(.metadata.id | test("v\\d+")) | .spec' \
      | yq -r '.machine.install.image' \
      | sed -E "s,(.+),$n: \1,g"
  done
  step 'talos node os-release'
  for n in "${nodes[@]}"; do
    talosctl -n $n read /etc/os-release \
      | sed -E "s,(.+),$n: \1,g"
  done
  step 'kubernetes nodes'
  kubectl get nodes -o wide
}

function install-gateway-api-crd {
  step 'install gateway api crds'
  kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/standard-install.yaml
}

function export-kubernetes-internal-ca-crt {
  step 'export kubernetes-internal-ca-crt.pem'

  local max_wait=300
  local elapsed=0
  local interval=5

  echo "Waiting for secret/internal-root-ca in cert-manager namespace (max ${max_wait}s)..."

  while [ $elapsed -lt $max_wait ]; do
    if kubectl get -n cert-manager secret/internal-root-ca &>/dev/null; then
      echo "Secret found after ${elapsed}s"
      kubectl get -n cert-manager secret/internal-root-ca -o jsonpath='{.data.tls\.crt}' \
        | base64 -d \
        > output/kubernetes-internal-ca-crt.pem
      echo "Exported to output/kubernetes-internal-ca-crt.pem"
      return 0
    fi

    sleep $interval
    elapsed=$((elapsed + interval))
    echo "Still waiting... (${elapsed}/${max_wait}s)"
  done

  echo "Error: secret/internal-root-ca not found after ${max_wait}s"
  return 1
}

function destroy {
  terraform destroy -auto-approve
}

function merge-kubeconfig {
  step 'merge kubeconfig to ~/.kube/config'

  local controllers="$(terraform output -raw controllers)"
  local c0="$(echo $controllers | cut -d , -f 1)"

  # 기존 컨텍스트 백업
  if [ -f "$HOME/.kube/config" ]; then
    cp "$HOME/.kube/config" "$HOME/.kube/config.backup.$(date +%Y%m%d_%H%M%S)"
    echo "Backup created"
  fi

  KUBECONFIG=~/.kube/config talosctl -n $c0 kubeconfig --merge

  echo "Successfully merged kubeconfig"
  kubectl config get-contexts
}

case $1 in
  init)
    init
    ;;
  plan)
    plan
    ;;
  apply)
    apply
    ;;
  plan-apply)
    plan
    apply
    ;;
  health)
    health
    ;;
  info)
    info
    ;;
  destroy)
    destroy
    ;;
  merge-kubeconfig)
    merge-kubeconfig
    ;;
  *)
    echo $"Usage: $0 {init|plan|apply|plan-apply|health|info}"
    exit 1
    ;;
esac