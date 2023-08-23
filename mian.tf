provider "azurerm" {
  features {
    resource_group {
       prevent_deletion_if_contains_resources = false
     }
  }
}

variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  default = "Demo"
}

variable "location" {
  description = "Location for Azure resources"
  default  = "eastus"
}

variable "load_balancer_name" {
  description = "Name of the Azure Load Balancer"
  default = "Demo"
}

variable "vnet_name" {
  description = "Vnet Name"
  default = "Demo"
}

variable "subnet_name" {
  description = "Subnet Name"
  default = "Demo"
}

# Load the module
module "vm_setup" {
  source             = "./modules/vm_setup"
  resource_group_name = var.resource_group_name
  location           = var.location
  vnet_name          = var.vnet_name
  subnet_name        = var.subnet_name
}

# Load the module
module "lb_setup" {
  source = "./modules/lb_setup"
  resource_group_name = var.resource_group_name
  location            = var.location
  load_balancer_name  = var.load_balancer_name
  backend_pool_vm_id = module.vm_setup.network_interfaces
}

