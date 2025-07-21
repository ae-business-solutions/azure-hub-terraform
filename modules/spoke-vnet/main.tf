# Existing Resource Group
data "azurerm_resource_group" "spoke" {
  name = var.spoke_resource_group_name
}

# Spoke Virtual Network
resource "azurerm_virtual_network" "spoke" {
  name                = "vnet-${var.spoke_vnet_name}-${var.location_short}-${var.environment_short}"
  resource_group_name = data.azurerm_resource_group.spoke.name
  location            = data.azurerm_resource_group.spoke.location
  address_space       = var.spoke_vnet_address_space
}

# Create subnets
resource "azurerm_subnet" "spoke" {
  for_each = var.subnets

  name                 = each.key
  resource_group_name  = data.azurerm_resource_group.spoke.name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [each.value.address_prefix]
}

# Route table for spoke subnets
resource "azurerm_route_table" "spoke" {
  name                = "rt-${var.spoke_vnet_name}-${var.location_short}-${var.environment_short}"
  resource_group_name = data.azurerm_resource_group.spoke.name
  location            = data.azurerm_resource_group.spoke.location

  # Force all internet traffic through firewall
  route {
    name                   = "to-internet"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.firewall_ilb_ip
  }

  # Force RFC1918 traffic through firewall
  route {
    name                   = "to-rfc1918-10"
    address_prefix         = "10.0.0.0/8"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.firewall_ilb_ip
  }

  route {
    name                   = "to-rfc1918-172"
    address_prefix         = "172.16.0.0/12"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.firewall_ilb_ip
  }

  route {
    name                   = "to-rfc1918-192"
    address_prefix         = "192.168.0.0/16"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.firewall_ilb_ip
  }
}

# Associate route table with all subnets
resource "azurerm_subnet_route_table_association" "spoke" {
  for_each = var.subnets

  subnet_id      = azurerm_subnet.spoke[each.key].id
  route_table_id = azurerm_route_table.spoke.id
}

# Peering from spoke to hub
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                         = "${var.spoke_vnet_name}-to-hub"
  resource_group_name          = data.azurerm_resource_group.spoke.name
  virtual_network_name         = azurerm_virtual_network.spoke.name
  remote_virtual_network_id    = var.hub_vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = true # Use hub's gateway when deployed
}

# Peering from hub to spoke
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                         = "hub-to-${var.spoke_vnet_name}"
  resource_group_name          = data.azurerm_resource_group.spoke.name
  virtual_network_name         = var.hub_vnet_name
  remote_virtual_network_id    = azurerm_virtual_network.spoke.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true # Allow spokes to use hub's gateway
  use_remote_gateways          = false
}
