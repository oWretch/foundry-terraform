terraform {
  required_version = ">= 1.8.0"
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.4"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.account_subscription_id
}

provider "azurerm" {
  alias = "search"
  features {}
  subscription_id = var.search_subscription_id
}

provider "azurerm" {
  alias = "storage"
  features {}
  subscription_id = var.storage_subscription_id
}

provider "azurerm" {
  alias = "cosmos"
  features {}
  subscription_id = var.cosmosdb_subscription_id
}

provider "azapi" {
  subscription_id = var.account_subscription_id
}