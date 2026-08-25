output "data_factory_name" {
  value = azurerm_data_factory.this.name
}

# output "databricks_workspace_url" {
#   value = azurerm_databricks_workspace.this.workspace_url
# }

# output "databricks_access_connector_id" {
#   value = azurerm_databricks_access_connector.this.id
# }

# output "databricks_cluster_id" {
#   value = databricks_cluster.hr_analytics.id
# }

# output "storage_account_dfs_endpoint" {
#   description = "Use this to fix the hardcoded hr1storage1 in your notebook, once confirmed"
#   value       = azurerm_storage_account.adls.primary_dfs_endpoint
# }
