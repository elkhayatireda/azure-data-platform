# Matches the manually-built "hr_analytics_cluster": single-node,
# Standard_D4s_v3, 17.3 LTS, Unity Catalog / Dedicated access mode,
# 10-min autotermination, Unrestricted policy (no policy_id set).
data "databricks_spark_version" "dbr_17_3_lts" {
  long_term_support = true
  spark_version      = "4.0"
  scala              = "2.13"
}

resource "databricks_cluster" "hr_analytics" {
  cluster_name             = "hr_analytics_cluster"
  spark_version             = data.databricks_spark_version.dbr_17_3_lts.id
  node_type_id              = "Standard_D4s_v3"
  autotermination_minutes = 10

  # Single-node: is_single_node handles the ResourceClass tag, spark_conf,
  # and num_workers=0 automatically — no need to set those by hand.
  is_single_node = true
  kind             = "CLASSIC_PREVIEW"

  # Unity Catalog "Dedicated" access mode. Required for the spark-excel
  # Maven library below, per the project's own known-bugs notes: shared/
  # job clusters block that install via the allowlist, Dedicated doesn't.
  data_security_mode = "DATA_SECURITY_MODE_DEDICATED"
  single_user_name    = var.databricks_single_user_name
}

resource "databricks_library" "spark_excel" {
  cluster_id = databricks_cluster.hr_analytics.id

  maven {
    coordinates = "com.crealytics:spark-excel_2.13:3.5.1_0.20.4"
  }
}
