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

locals {
  resource_group_name = "rg-aks-01"
  location            = "eastus"
  node_count          = 2
  node_size           = "Standard_D2_v2"
  cluster_name        = "aks-cluster-01"
  acr_name            = "acr-01"
}

module "aks" {
  source              = "Azure/aks/azurerm"
  resource_group_name = local.resource_group_name
  location            = local.location
  client_id           = var.client_id
  client_secret       = var.client_secret
  ssh_key             = var.ssh_key
  node_count          = local.node_count
  node_size           = local.node_size
  cluster_name        = local.cluster_name
  subnet_prefixes     = [var.subnet_prefix]
  vnet_subnet_id      = var.vnet_subnet_id
  dns_service_ip      = var.dns_service_ip
  service_cidr        = var.service_cidr
  tags                = var.tags
  depends_on          = [module.acr]
}

module "acr" {
  source              = "Azure/acr/azurerm"
  resource_group_name = local.resource_group_name
  location            = local.location
  sku                 = "Standard"
  name                = local.acr_name
  admin_enabled       = false
  tags                = var.tags
}

# Assign ACR Contributor role to AKS service principal
resource "azurerm_role_assignment" "acr_contributor" {
  scope              = module.acr.id
  role_definition_id = data.azurerm_role_definition.acr_contributor.id
  principal_id       = module.aks.kubelet_identity_object_id
}

data "azurerm_role_definition" "acr_contributor" {
  name = "AcrImageSigner"
}
