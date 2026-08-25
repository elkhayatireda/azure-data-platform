resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
  numeric = true
}

resource "azurerm_resource_group" "this" {
  name     = local.resource_group_name
  location = var.location
  tags     = var.tags
}
