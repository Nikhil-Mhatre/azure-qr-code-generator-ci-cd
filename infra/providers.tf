# providers.tf

terraform {
  required_version = ">= 1.14.4"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.58.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>3.7.0"
    }
    github = {
      source  = "hashicorp/github"
      version = "~>6.10.2"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.8.1"
    }
  }

  # Configure the remote backend (ensure this resource group/account/container exist)
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstated7d44aff"
    container_name       = "tfstate"
    key                  = "prod/terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

provider "azuread" {
  # uses the same authentication as azurerm
}

provider "random" {
  # Configuration options
}

provider "github" {
  token = var.github_token
  owner = var.github_owner
}
