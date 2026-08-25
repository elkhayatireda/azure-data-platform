# --- Naming convention ------------------------------------------------
# Every resource name starts with "terr". Azure enforces different
# character sets and length limits per resource type, so this can't be
# one flat string template — each name is built to satisfy its own
# resource's constraints, then truncated defensively as a safety net
# (e.g. if var.project or var.environment get lengthened later, storage
# account names won't silently exceed 24 chars and fail apply).
#
#   Resource Group : terr-rg-<project>-<env>            (hyphens ok, generous length limit)
#   Storage Account: terrst<project><env><suffix>        (lowercase alphanumeric ONLY, <=24 chars, globally unique)
#   Key Vault      : terr-kv-<project>-<env>-<suffix>    (alphanumeric+hyphen, <=24 chars, globally unique)
#   Data Factory   : terr-adf-<project>-<env>-<suffix>   (alphanumeric+hyphen, <=63 chars, globally unique)
#
# random_string.suffix (defined in resource_group.tf) is reused
# everywhere a globally-unique name is required, so all resources in
# one apply share the same suffix and are easy to spot as a set.
locals {
  name_prefix = "terr"

  resource_group_name = "${local.name_prefix}-rg-${var.project}-${var.environment}"

  # Storage accounts: lowercase letters + numbers only, no hyphens,
  # 3-24 chars total, globally unique. Naive truncation of the whole
  # concatenated string risks chopping into random_string.suffix,
  # which is what actually guarantees global uniqueness — losing
  # characters there raises collision odds. Instead: fixed parts
  # (prefix+"st", environment, suffix) are always kept whole, and only
  # the project name gets truncated to whatever budget is left.
  storage_fixed_parts_length = length("${local.name_prefix}st") + length(var.environment) + length(random_string.suffix.result)
  storage_project_budget     = max(24 - local.storage_fixed_parts_length, 1)
  storage_project_trimmed    = substr(replace(var.project, "-", ""), 0, local.storage_project_budget)

  storage_account_name = lower(
    "${local.name_prefix}st${local.storage_project_trimmed}${var.environment}${random_string.suffix.result}"
  )
}
