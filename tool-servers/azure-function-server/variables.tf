variable "resource_group_name" { type = string }
variable "location" {
  type    = string
  default = "australiaeast"
}
variable "vnet_name" { type = string }
variable "integration_subnet_name" {
  type    = string
  default = "func-integration-subnet"
}
variable "integration_subnet_prefix" {
  type    = string
  default = "192.168.5.0/24"
  validation {
    condition     = can(cidrhost(var.integration_subnet_prefix, 0))
    error_message = "integration_subnet_prefix must be a valid CIDR."
  }
}
variable "private_endpoint_subnet_name" { type = string }
variable "base_name" {
  description = "Lowercase alphanumeric base for globally unique Function and Storage names."
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9]{3,18}$", var.base_name))
    error_message = "base_name must contain 3-18 lowercase alphanumeric characters."
  }
}
variable "tags" {
  type = map(string)
  default = {
    managedBy = "terraform"
  }
}