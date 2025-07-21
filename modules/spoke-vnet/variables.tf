variable "spoke_resource_group_name" {
  type        = string
  description = "Name of resource Group for Spoke VNET"
}

variable "spoke_vnet_name" {
  type        = string
  description = "Name of the spoke VNET"
}

variable "spoke_vnet_address_space" {
  type        = list(string)
  description = "Address space for spoke VNET"
}

variable "hub_vnet_id" {
  type        = string
  description = "Resource ID of the hub VNET for peering"
}

variable "hub_vnet_name" {
  type        = string
  description = "Name of the hub VNET for peering"
}

variable "firewall_ilb_ip" {
  type        = string
  description = "IP address of the firewall internal load balancer"
}

variable "subnets" {
  type = map(object({
    address_prefix = string
    # Add additional subnet configurations as needed
  }))
  description = "Map of subnet configurations"
}

variable "environment_short" {
  type        = string
  description = "Short name for environment"
}

variable "location_short" {
  type        = string
  description = "Short name for location"
}