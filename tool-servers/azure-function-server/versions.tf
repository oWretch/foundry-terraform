terraform {
  required_version = ">= 1.8.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  resource_providers_to_register = [
    "Microsoft.App",
    "Microsoft.CognitiveServices",
    "Microsoft.ContainerService",
  ]
  features {}
}
