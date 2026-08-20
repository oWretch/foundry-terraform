variable "account_id" { type = string }
variable "account_name" { type = string }
variable "location" { type = string }
variable "project_name" { type = string }
variable "project_description" { type = string }
variable "project_display_name" { type = string }
variable "capability_host_name" { type = string }
variable "ai_search_id" { type = string }
variable "ai_search_name" { type = string }
variable "ai_search_endpoint" { type = string }
variable "ai_search_location" { type = string }
variable "cosmosdb_id" { type = string }
variable "cosmosdb_name" { type = string }
variable "cosmosdb_endpoint" { type = string }
variable "cosmosdb_location" { type = string }
variable "storage_id" { type = string }
variable "storage_name" { type = string }
variable "storage_blob_endpoint" { type = string }
variable "storage_location" { type = string }
variable "unique_connection_salt" {
  type    = string
  default = ""
}