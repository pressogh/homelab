output "talosconfig" {
  value     = module.common.talosconfig
  sensitive = true
}

output "kubeconfig" {
  value     = module.common.kubeconfig
  sensitive = true
}

output "controllers" {
  value = module.common.controllers
}

output "workers" {
  value = module.common.workers
}