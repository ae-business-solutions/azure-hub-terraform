resource "azurerm_resource_group" "nethub" {
  name     = "rg-nethub-${local.location_short}-${local.environment_short}"
  location = local.location
}