terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.3"
    }
  }

 # backend "azurerm" {
 #   resource_group_name  = "terraform-state-rg"
 #   storage_account_name = "terraformstate1234"
 #   container_name       = "terraform-state-container"
 #   key                  = "aks-cluster.tfstate"
 # }
}

provider "azurerm" {
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = "myResourceGroup"
  location = "eastus"
}

# Create an ACR instance
resource "azurerm_container_registry" "acr" {
  name                     = "myacr"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  sku                      = "Standard"
  admin_enabled            = false
}

# Create an AKS cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "myaks"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix_private_cluster = "myaks"
  dns_prefix = "myaks"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2_v2"
  }

  identity {
    type = "SystemAssigned"
  }
}

# Assign AcrImageSigner role to AKS cluster identity for ACR instance scope
resource "azurerm_role_assignment" "acr_signer" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrImageSigner"
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}
