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
  storage_use_azuread = true
  resource_providers_to_register = [
    "Microsoft.App",
    "Microsoft.CognitiveServices",
    "Microsoft.ContainerService",
  ]
  features {}
}

provider "azapi" {}
