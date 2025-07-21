# Public IPs for firewall management interfaces
# Not required, however useful for initial and "break glass" firewall access
# (if VPN/ExpressRoute is down, misconfigured, or not present)
resource "azurerm_public_ip" "fw_mgmt" {
  count = local.fw_instance_count

  name                = "pip-firewall${count.index + 1}-mgmt-${local.location_short}-${local.environment_short}"
  location            = azurerm_resource_group.nethub.location
  resource_group_name = azurerm_resource_group.nethub.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Public IPs for outside interfaces
# These will be the NAT addresses for internet egress
# Typically no Management Profile on these interfaces
resource "azurerm_public_ip" "fw_outside" {
  count = local.fw_instance_count

  name                = "pip-firewall${count.index + 1}-outside-${local.location_short}-${local.environment_short}"
  location            = azurerm_resource_group.nethub.location
  resource_group_name = azurerm_resource_group.nethub.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Firewall NICs
resource "azurerm_network_interface" "fw_mgmt" {
  count = local.fw_instance_count

  name                = "nic-firewall${count.index + 1}-mgmt-${local.location_short}-${local.environment_short}"
  location            = azurerm_resource_group.nethub.location
  resource_group_name = azurerm_resource_group.nethub.name

  ip_configuration {
    name                          = "mgmt"
    subnet_id                     = azurerm_subnet.mgmt.id
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(local.inside_subnet_prefix, count.index + 4) # Start firewalls at first available
    public_ip_address_id          = azurerm_public_ip.fw_mgmt[count.index].id
  }
}

resource "azurerm_network_interface" "fw_inside" {
  count = local.fw_instance_count

  name                  = "nic-firewall${count.index + 1}-inside-${local.location_short}-${local.environment_short}"
  location              = azurerm_resource_group.nethub.location
  resource_group_name   = azurerm_resource_group.nethub.name
  ip_forwarding_enabled = true # Required on inside interface to send packets with source other then self

  ip_configuration {
    name                          = "inside"
    subnet_id                     = azurerm_subnet.inside.id
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(local.inside_subnet_prefix, count.index + 5) # Start firewalls after ILB
  }
}

resource "azurerm_network_interface" "fw_outside" {
  count = local.fw_instance_count

  name                  = "nic-firewall${count.index + 1}-outside-${local.location_short}-${local.environment_short}"
  location              = azurerm_resource_group.nethub.location
  resource_group_name   = azurerm_resource_group.nethub.name
  ip_forwarding_enabled = true # Required on inside interface to send packets with source other then self

  ip_configuration {
    name                          = "outside"
    subnet_id                     = azurerm_subnet.outside.id
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(local.inside_subnet_prefix, count.index + 4) # Start firewalls at first available
    public_ip_address_id          = azurerm_public_ip.fw_outside[count.index].id
  }
}

# Associate inside NICs with ILB backend pool
resource "azurerm_network_interface_backend_address_pool_association" "fw_inside" {
  count = local.fw_instance_count

  network_interface_id    = azurerm_network_interface.fw_inside[count.index].id
  ip_configuration_name   = "inside"
  backend_address_pool_id = azurerm_lb_backend_address_pool.firewall.id
}

# Firewall VMs
resource "azurerm_linux_virtual_machine" "firewall" {
  count = local.fw_instance_count

  name                = "vm-firewall${count.index + 1}-${local.location_short}-${local.environment_short}"
  location            = azurerm_resource_group.nethub.location
  resource_group_name = azurerm_resource_group.nethub.name
  size                = local.fw_instance_size

  admin_username                  = local.fw_username
  admin_password                  = var.fw_password
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.fw_mgmt[count.index].id,
    azurerm_network_interface.fw_inside[count.index].id,
    azurerm_network_interface.fw_outside[count.index].id,
  ]

  source_image_reference {
    publisher = "paloaltonetworks"
    offer     = "vmseries-flex"
    sku       = local.fw_license_type
    version   = local.fw_version
  }

  plan {
    name      = local.fw_license_type
    publisher = "paloaltonetworks"
    product   = "vmseries-flex"
  }

  os_disk {
    name                 = "disk-firewall${count.index + 1}-os-${local.location_short}-${local.environment_short}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  # https://docs.paloaltonetworks.com/vm-series/10-1/vm-series-deployment/bootstrap-the-vm-series-firewall/create-the-init-cfgtxt-file/init-cfgtxt-file-components
  custom_data = base64encode("type=dhcp-client;vm-auth-key=;op-cmd-dpdk-pkt-io=yes;dhcp-send-hostname=yes;dhcp-send-client-id=yes;dhcp-accept-server-hostname=yes;dhcp-accept-server-domain=yes")

  boot_diagnostics {}
}
