locals {
  resource_group_name     = "${var.project_name}${var.environment}rg"
  storage_account_name    = "${var.project_name}${var.environment}st"
  function_app_name       = "${var.project_name}-${var.environment}-func"
  aad_application_name    = "${var.project_name}-${var.environment}-github-actions"
  federated_identity_name = "${var.project_name}-${var.environment}-github-main"
}
