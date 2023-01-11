variable "hosted_zone_name" {
  description = "The domain for the zone, e.g. `login.walletconnect.com`, this will result in the certificate of `*.login.walletconnect.com`"
  type        = string
}

variable "fqdn" {
  description = ""
  type        = string
}
