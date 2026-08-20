variable "location" {
  type    = string
  default = "australiaeast"
}
variable "existing_account_name" { type = string }
variable "account_resource_group_name" { type = string }
variable "account_subscription_id" {
  type = string
  validation {
    condition     = can(regex("^[0-9a-fA-F-]{36}$", var.account_subscription_id))
    error_message = "account_subscription_id must be a subscription GUID."
  }
}
variable "project_name" { type = string }
variable "project_suffix" {
  description = "Stable four-character suffix appended to the project name."
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9]{4}$", var.project_suffix))
    error_message = "project_suffix must be exactly four lowercase alphanumeric characters."
  }
}
variable "project_description" {
  type    = string
  default = "Additional AI Foundry project with network secured deployed Agent"
}
variable "project_display_name" { type = string }
variable "capability_host_name" {
  type    = string
  default = "caphostproj"
}
variable "existing_ai_search_name" { type = string }
variable "search_resource_group_name" { type = string }
variable "search_subscription_id" { type = string }
variable "ai_search_location" {
  description = "Azure region of the existing AI Search service."
  type        = string
  default     = null
}
variable "existing_storage_name" { type = string }
variable "storage_resource_group_name" { type = string }
variable "storage_subscription_id" { type = string }
variable "existing_cosmosdb_name" { type = string }
variable "cosmosdb_resource_group_name" { type = string }
variable "cosmosdb_subscription_id" { type = string }