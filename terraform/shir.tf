# Registers the IR identity in ADF and produces an auth key. It does
# NOT install anything on-prem — you install the IR agent on the
# machine that can reach your Docker Postgres yourself and paste in
# the key (terraform output -raw shir_auth_key_1) to register the node.
resource "azurerm_data_factory_integration_runtime_self_hosted" "onprem" {
  name            = "${local.name_prefix}-shir-onprem-postgres"
  data_factory_id = azurerm_data_factory.this.id
  description     = "Bridges ADF to on-prem PostgreSQL for the Employees source"
}

output "shir_auth_key_1" {
  value     = azurerm_data_factory_integration_runtime_self_hosted.onprem.primary_authorization_key
  sensitive = true
}
