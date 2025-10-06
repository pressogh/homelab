variable "longhorn_version" {
  type        = string
  default     = "1.10.0"
  description = "The version of Longhorn to use."
  validation {
    condition     = can(regex("^\\d+(\\.\\d+)+", var.longhorn_version))
    error_message = "Must be a version number."
  }
}
variable "longhorn_domain" {
  type        = string
  description = "The domain to use for Longhorn."
}