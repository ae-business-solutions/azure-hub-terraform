# Hub Virtual Network
resource "azurerm_virtual_network" "hub" {
  name                = "vnet-nethub-${local.location_short}-${local.environment_short}"
  resource_group_name = azurerm_resource_group.nethub.name
  location            = azurerm_resource_group.nethub.location
  address_space       = local.hub_vnet_address_space
}

# Hub subnets
resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet" # Must be named GatewaySubnet for future VPN/ER Gateway
  resource_group_name  = azurerm_resource_group.nethub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [local.gateway_subnet_prefix]
}

resource "azurerm_subnet" "routeserver" {
  name                 = "RouteServerSubnet" # Must be named RouteServerSubnet for Azure Route Server
  resource_group_name  = azurerm_resource_group.nethub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [local.routeserver_subnet_prefix]
}

resource "azurerm_subnet" "inside" {
  name                 = "inside" # This is a sub-resource
  resource_group_name  = azurerm_resource_group.nethub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [local.inside_subnet_prefix]
}

resource "azurerm_subnet" "outside" {
  name                 = "outside" # This is a sub-resource
  resource_group_name  = azurerm_resource_group.nethub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [local.outside_subnet_prefix]
}

resource "azurerm_subnet" "mgmt" {
  name                 = "mgmt" # This is a sub-resource
  resource_group_name  = azurerm_resource_group.nethub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [local.mgmt_subnet_prefix]
}

# NSG for management subnet
resource "azurerm_network_security_group" "mgmt" {
  name                = "nsg-nethub-mgmt-${local.location_short}-${local.environment_short}"
  location            = azurerm_resource_group.nethub.location
  resource_group_name = azurerm_resource_group.nethub.name

  security_rule {
    name                       = "allow-https"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefixes    = local.management_sources
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-ssh"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = local.management_sources
    destination_address_prefix = "*"
  }
}

# Associate NSG with management subnet
resource "azurerm_subnet_network_security_group_association" "mgmt" {
  subnet_id                 = azurerm_subnet.mgmt.id
  network_security_group_id = azurerm_network_security_group.mgmt.id
}

# Route table for GatewaySubnet
# Routes will be added to this route table for each Spoke subnet (next-hop ILB)
resource "azurerm_route_table" "gateway" {
  name                = "rt-nethub-gw-${local.location_short}-${local.environment_short}"
  location            = azurerm_resource_group.nethub.location
  resource_group_name = azurerm_resource_group.nethub.name
}

resource "azurerm_subnet_route_table_association" "gateway" {
  subnet_id      = azurerm_subnet.gateway.id
  route_table_id = azurerm_route_table.gateway.id
}
