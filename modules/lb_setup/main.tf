variable "resource_group_name" {}
variable "location" {}
variable "load_balancer_name" {}
variable "backend_pool_vm_id" {

}


resource "azurerm_resource_group" "demo" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_public_ip" "demo_lb_public_ip" {
  name                = "demo-lb-pip"
  resource_group_name = azurerm_resource_group.demo.name
  location            = azurerm_resource_group.demo.location
  allocation_method  = "Static"
}

resource "azurerm_lb" "demo" {
  name                = var.load_balancer_name
  resource_group_name = azurerm_resource_group.demo.name
  location            = azurerm_resource_group.demo.location
  sku                 = "Basic"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.demo_lb_public_ip.id
  }
}


resource "azurerm_lb_probe" "http_probe" {
  loadbalancer_id     = azurerm_lb.demo.id
  name                = "HTTPProbe"
  protocol            = "Http"
  port                = 80
  request_path        = "/"
  interval_in_seconds = 15
  number_of_probes    = 2
}

resource "azurerm_lb_backend_address_pool" "demo" {
  loadbalancer_id     = azurerm_lb.demo.id
  name                = "demo-backend-pool"
}

resource "azurerm_lb_rule" "http_rule" {
  loadbalancer_id                = azurerm_lb.demo.id
  name                           = "HTTPRule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
  probe_id                       = azurerm_lb_probe.http_probe.id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.demo.id]
  enable_floating_ip             = false
}

resource "azurerm_lb_nat_rule" "ssh_nat_rule" {
  resource_group_name            = azurerm_resource_group.demo.name
  loadbalancer_id                = azurerm_lb.demo.id
  name                           = "ssh-nat-rule"
  protocol                       = "Tcp"
  frontend_port                  = 22  # External port for SSH
  backend_port                   = 22    # Internal port for SSH
  frontend_ip_configuration_name = "PublicIPAddress"
}

resource "azurerm_network_interface_nat_rule_association" "demo" {
  network_interface_id = var.backend_pool_vm_id.id
  ip_configuration_name = "internal"
  nat_rule_id           = azurerm_lb_nat_rule.ssh_nat_rule.id
}

# Associate VM network interfaces with the backend pool
resource "azurerm_network_interface_backend_address_pool_association" "example" {
  network_interface_id = var.backend_pool_vm_id.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.demo.id
}

# Output the Load Balancer ID
output "load_balancer_id" {
  value = azurerm_lb.demo.id
}

