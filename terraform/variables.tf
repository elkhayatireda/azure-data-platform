variable "project" {
  description = "Short project name used in resource naming"
  type        = string
  default     = "hranalytics"
}

variable "environment" {
  description = "Environment name (dev, prod, etc.)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "westeurope"
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default = {
    project = "hr-analytics"
    managed = "terraform"
  }
}

variable "databricks_single_user_name" {
  description = "Azure AD UPN/email assigned to the Dedicated (SINGLE_USER) cluster — required by Unity Catalog for single-user compute. Find it in the Databricks workspace: top-right user icon."
  type        = string
}
