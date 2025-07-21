# Internal Load Balancer
resource "azurerm_lb" "firewall" {
  name                = "ilb-firewall-${local.location_short}-${local.environment_short}"
  location            = azurerm_resource_group.nethub.location
  resource_group_name = azurerm_resource_group.nethub.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "firewall-ilb-frontend" # This is a sub-resource
    subnet_id                     = azurerm_subnet.inside.id
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(local.inside_subnet_prefix, 4) # .4 in the subnet / first available IP
  }
}

resource "azurerm_lb_backend_address_pool" "firewall" {
  name            = "firewall-backend-pool" # This is a sub-resource
  loadbalancer_id = azurerm_lb.firewall.id
}

resource "azurerm_lb_probe" "firewall" {
  name                = "firewall-health-probe" # This is a sub-resource
  loadbalancer_id     = azurerm_lb.firewall.id
  protocol            = "Https"
  port                = 443
  interval_in_seconds = 5
  number_of_probes    = 2
  # PAN-OS health check path
  # Reference: https://knowledgebase.paloaltonetworks.com/KCSArticleDetail?id=kA10g000000POfaCAG
  request_path = "/unauth/php/health.php"
}

resource "azurerm_lb_rule" "firewall" {
  name                           = "firewall-ha-ports" # This is a sub-resource
  loadbalancer_id                = azurerm_lb.firewall.id
  frontend_ip_configuration_name = "firewall-ilb-frontend"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.firewall.id]
  probe_id                       = azurerm_lb_probe.firewall.id
  protocol                       = "All"
  frontend_port                  = 0
  backend_port                   = 0
  load_distribution              = "Default"
  enable_floating_ip             = true
}