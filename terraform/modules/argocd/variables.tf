variable "argocd_version" {
  type        = string
  default     = "8.5.7"
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
variable "argocd_default_apps" {
  type = object({
    git_url         = string
    path            = string
    target_revision = string
  })
  description = "The default apps to deploy."
  nullable    = true
}