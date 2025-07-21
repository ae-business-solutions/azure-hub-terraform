output "vnet_id" {
  description = "The ID of the spoke VNET"
  value       = azurerm_virtual_network.spoke.id
}

output "vnet_name" {
  description = "The name of the spoke VNET"
  value       = azurerm_virtual_network.spoke.name
}

output "subnet_ids" {
  description = "Map of subnet names to IDs"
  value = {
    for subnet_key, subnet in azurerm_subnet.spoke : subnet_key => subnet.id
  }
}

output "address_space" {
  description = "The address space of the spoke VNET"
  value       = azurerm_virtual_network.spoke.address_space
}

output "route_table_id" {
  description = "The ID of the spoke route table"
  value       = azurerm_route_table.spoke.id
}
