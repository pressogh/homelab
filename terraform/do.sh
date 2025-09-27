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
  export-kubernetes-internal-ca-crt
  info
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

function export-kubernetes-internal-ca-crt {
  step 'export kubernetes-internal-ca-crt.pem'
  kubectl get -n cert-manager secret/internal-root-ca -o jsonpath='{.data.tls\.crt}' \
    | base64 -d \
    > output/kubernetes-internal-ca-crt.pem
}

function destroy {
  terraform destroy -auto-approve
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
  *)
    echo $"Usage: $0 {init|plan|apply|plan-apply|health|info}"
    exit 1
    ;;
esac