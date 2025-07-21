variable "fw_password" {
  type        = string
  description = "Admin password for firewall"
  sensitive   = true
}

locals {
  # Resource group and location
  location          = "centralus"
  location_short    = "cus"
  environment       = "production"
  environment_short = "prod"

  # Network addressing
  hub_vnet_address_space    = ["10.0.0.0/16"]
  gateway_subnet_prefix     = "10.0.0.0/24"
  routeserver_subnet_prefix = "10.0.1.0/24"
  inside_subnet_prefix      = "10.0.2.0/24"
  outside_subnet_prefix     = "10.0.3.0/24"
  mgmt_subnet_prefix        = "10.0.4.0/24"

  # Firewall configuration
  fw_instance_size  = "Standard_DS3_v2" # 4 vCPU, 14GB RAM, 4 NICs
  fw_instance_count = 2
  fw_version        = "11.1.2"
  fw_license_type   = "byol"
  fw_username       = "panadmin"

  # Misc
  management_sources = ["10.0.0.0/8"]
}
