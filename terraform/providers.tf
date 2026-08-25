terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.55"
    }
  }

  # NOT YET WIRED — bootstrap manually first, then uncomment.
  # This is the gap noted in the project summary ("remote state not
  # fully wired"). Until this is set, `terraform apply` uses local
  # state, which is fine for solo learning but risky for a team.
  #
  # backend "azurerm" {
  #   resource_group_name  = "rg-tfstate"
  #   storage_account_name = "sthranalyticstfstate"
  #   container_name       = "tfstate"
  #   key                  = "hr-analytics.tfstate"
  # }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

# Workspace-level auth: no PAT, no separate secret. Reuses whatever
# Azure credential is already authenticating the azurerm provider
# (Azure CLI login, or a service principal via ARM_* env vars) and
# exchanges it for a Databricks-scoped token via azure_workspace_resource_id.
provider "databricks" {
  host                        = azurerm_databricks_workspace.this.workspace_url
  azure_workspace_resource_id = azurerm_databricks_workspace.this.id
}
