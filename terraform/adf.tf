resource "azurerm_data_factory" "this" {
  name                = "${local.name_prefix}-adf-${var.project}-${var.environment}-${random_string.suffix.result}"
  location             = azurerm_resource_group.this.location
  resource_group_name  = azurerm_resource_group.this.name

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# Lets ADF write into raw/ via managed identity — no storage account
# keys anywhere.
resource "azurerm_role_assignment" "adf_storage_contributor" {
  scope                = azurerm_storage_account.adls.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_data_factory.this.identity[0].principal_id
}
