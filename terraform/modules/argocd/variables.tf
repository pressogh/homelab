variable "argocd_version" {
  type        = string
  default     = "10.11.6"
  description = "The version of Argo CD to use."
  validation {
    condition     = can(regex("^\\d+(\\.\\d+)+", var.argocd_version))
    error_message = "Must be a version number."
  }
}
variable "argocd_domain" {
  type        = string
  description = "The domain to use for ArgoCD."
}
