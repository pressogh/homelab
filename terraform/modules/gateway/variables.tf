variable "public_domain" {
  type        = string
  description = "The public domain to use for ACME DNS-01 challenges."
}
variable "internal_domain" {
  type        = string
  description = "The internal domain to use for ACME DNS-01 challenges."
}