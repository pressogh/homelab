variable "cert_manager_version" {
  type        = string
  default     = "1.18.2"
  description = "The version of cert-manager to use."
  validation {
    condition     = can(regex("^\\d+(\\.\\d+)+", var.cert_manager_version))
    error_message = "Must be a version number."
  }
}
variable "cert_manager_csi_driver_version" {
  type        = string
  default     = "0.11.0"
  description = "The version of cert-manager-csi-driver to use."
  validation {
      condition     = can(regex("^\\d+(\\.\\d+)+", var.cert_manager_csi_driver_version))
      error_message = "Must be a version number."
  }
}
variable "trust_manager_version" {
  type        = string
  default     = "0.19.0"
  description = "The version of trust-manager to use."
  validation {
      condition     = can(regex("^\\d+(\\.\\d+)+", var.trust_manager_version))
      error_message = "Must be a version number."
  }
}

variable "acme_email" {
  type        = string
  description = "The email to use for ACME registration."
}
variable "public_domain" {
  type        = string
  description = "The public domain to use for ACME DNS-01 challenges."
}
variable "cf_api_token" {
  type        = string
  description = "The Cloudflare API token to use for DNS-01 challenges."
  sensitive   = true
}