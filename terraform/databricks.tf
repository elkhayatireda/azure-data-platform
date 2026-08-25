# Premium SKU required for Unity Catalog + Access Connector support.
resource "azurerm_databricks_workspace" "this" {
  name                = "${local.name_prefix}-dbx-${var.project}-${var.environment}-${random_string.suffix.result}"
  resource_group_name  = azurerm_resource_group.this.name
  location             = azurerm_resource_group.this.location
  sku                  = "premium"

  tags = var.tags
}

# Access Connector = the managed identity Unity Catalog uses to reach
# storage. This replaces per-user/per-cluster storage keys — identity-
# based access only, matching what's already built manually.
resource "azurerm_databricks_access_connector" "this" {
  name                = "${local.name_prefix}-dbxac-${var.project}-${var.environment}-${random_string.suffix.result}"
  resource_group_name  = azurerm_resource_group.this.name
  location             = azurerm_resource_group.this.location

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# Lets the Access Connector's identity read/write the ADLS account.
# This is what the Unity Catalog Storage Credential + External
# Locations (next step, via the databricks provider) will actually
# use at query time.
resource "azurerm_role_assignment" "dbx_storage_contributor" {
  scope                = azurerm_storage_account.adls.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.this.identity[0].principal_id
}
