variable "public_domain" {
  type        = string
  description = "The public domain to use for ACME DNS-01 challenges."
}
variable "internal_domain" {
  type        = string
  description = "The internal domain to use for ACME DNS-01 challenges."
}
variable "public_gw_secret_name" {
  type        = string
  description = "The public gateway secret name."
  default     = "public-gw-tls"
}
variable "internal_gw_secret_name" {
  type        = string
  description = "The internal gateway secret name."
  default     = "internal-gw-tls"
}
