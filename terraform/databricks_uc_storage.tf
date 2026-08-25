# # Wraps the Access Connector's managed identity as a UC-usable
# # credential. This is what lets Databricks resolve abfss:// paths
# # without any storage account key.
# #
# # NOTE: this requires a Unity Catalog metastore already assigned to
# # the workspace. New Azure Databricks workspaces auto-provision one
# # per region in most cases, but the project's own notes flag this as
# # "untested for a from-scratch workspace" — if this errors with
# # something like "no metastore assigned", that's the cause; it needs
# # an account-level admin step (Account Console → Catalog → create/
# # assign metastore) that the workspace-level databricks provider
# # can't do on its own.
resource "databricks_storage_credential" "adls" {
	name = "${local.name_prefix}-cred-adls-${var.environment}"

	azure_managed_identity {
		access_connector_id = azurerm_databricks_access_connector.this.id
	}

	comment = "Managed by Terraform — Unity Catalog access to ${azurerm_storage_account.adls.name} via Access Connector identity"
}

# # One External Location per medallion container. Notebooks reference
# # these paths directly via abfss:// — Unity Catalog checks the path
# # against a matching External Location + credential before allowing
# # read/write, whether or not the code ever touches a managed table.
locals {
	uc_containers = {
		raw    = azurerm_storage_container.raw.name
		silver = azurerm_storage_container.silver.name
		gold   = azurerm_storage_container.gold.name
	}
}

resource "databricks_external_location" "adls" {
	for_each = local.uc_containers

	name            = "${local.name_prefix}-extloc-${each.key}-${var.environment}"
	url             = "abfss://${each.value}@${azurerm_storage_account.adls.name}.dfs.core.windows.net/"
	credential_name = databricks_storage_credential.adls.id
	comment         = "Managed by Terraform — ${each.key} container"
}
