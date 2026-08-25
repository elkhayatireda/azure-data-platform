# ADLS Gen2 (hierarchical namespace enabled) — matches the manual build:
# one storage account, three containers acting as the medallion layers.
resource "azurerm_storage_account" "adls" {
  name                     = local.storage_account_name
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true # HNS = ADLS Gen2, required for Unity Catalog external locations later

  min_tls_version                = "TLS1_2"
  allow_nested_items_to_be_public = false

  tags = var.tags
}

resource "azurerm_storage_container" "raw" {
  name                  = "raw"
  storage_account_name  = azurerm_storage_account.adls.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "silver" {
  name                  = "silver"
  storage_account_name  = azurerm_storage_account.adls.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "gold" {
  name                  = "gold"
  storage_account_name  = azurerm_storage_account.adls.name
  container_access_type = "private"
}

# Folder placeholders inside raw/ for each of the three sources, so
# both the ADF copy activity (built in ADF Studio / Git) and your
# manual CSV/Excel uploads land somewhere predictable from day one.
resource "azurerm_storage_data_lake_gen2_path" "raw_employees" {
  storage_account_id = azurerm_storage_account.adls.id
  path                = "employees"
  filesystem_name    = azurerm_storage_container.raw.name
  resource            = "directory"
}

resource "azurerm_storage_data_lake_gen2_path" "raw_attendees" {
  storage_account_id = azurerm_storage_account.adls.id
  path                = "attendees"
  filesystem_name    = azurerm_storage_container.raw.name
  resource            = "directory"
}

resource "azurerm_storage_data_lake_gen2_path" "raw_performance" {
  storage_account_id = azurerm_storage_account.adls.id
  path                = "performance"
  filesystem_name    = azurerm_storage_container.raw.name
  resource            = "directory"
}
