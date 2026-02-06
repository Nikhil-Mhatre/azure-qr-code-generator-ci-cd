# ---------------------------------------------
# Data Sources
# ---------------------------------------------

data "azurerm_client_config" "current" {
}

data "azuread_client_config" "current" {}

# ---------------------------------------------
# Resource Group
# ---------------------------------------------
resource "azurerm_resource_group" "rg" {
  name     = local.resource_group_name
  location = var.location
}


# ---------------------------------------------
# Storage Account
# ---------------------------------------------
resource "azurerm_storage_account" "storage" {
  name                       = local.storage_account_name
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  account_tier               = "Standard"
  account_replication_type   = "LRS"
  account_kind               = "StorageV2"
  https_traffic_only_enabled = true # enforce HTTPS
}

resource "azurerm_storage_container" "image_container" {
  name                  = "images"
  storage_account_id    = azurerm_storage_account.storage.id
  container_access_type = "private"
}

# ---------------------------------------------
# Key Vault (RBAC enabled)
# ---------------------------------------------
resource "azurerm_key_vault" "kv" {
  name                = "qrcode-kv"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  rbac_authorization_enabled = true
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
}

# ---------------------------------------------
# Terraform SP → Key Vault Admin
# ---------------------------------------------
resource "azurerm_role_assignment" "tf_kv_admin" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}


# ---------------------------------------------
# Key Vault Secrets (RBAC enabled)
# ---------------------------------------------
resource "azurerm_key_vault_secret" "storage_account_name" {
  name         = "storage-account-name"
  value        = azurerm_storage_account.storage.name
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [
    azurerm_role_assignment.tf_kv_admin
  ]
}

resource "azurerm_key_vault_secret" "storage_account_key" {
  name         = "storage-account-key"
  value        = azurerm_storage_account.storage.primary_access_key
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [
    azurerm_role_assignment.tf_kv_admin
  ]
}

resource "azurerm_key_vault_secret" "storage_connection_string" {
  name         = "storage-connection-string"
  value        = azurerm_storage_account.storage.primary_connection_string
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [
    azurerm_role_assignment.tf_kv_admin
  ]
}

resource "azurerm_key_vault_secret" "qr_sas_expiry_hours" {
  name         = "qr-sas-expiry-hours"
  value        = 1
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [
    azurerm_role_assignment.tf_kv_admin
  ]
}


# ---------------------------------------------
# App Service Plan (Consumption)
# ---------------------------------------------
resource "azurerm_service_plan" "asp" {
  name                = "${var.project_name}-${var.environment}-plan"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "Y1" # Consumption plan (Y1/Dynamic)
}

# ---------------------------------------------
# Linux Function App (Managed Identity)
# ---------------------------------------------
resource "azurerm_linux_function_app" "functionapp" {
  name                = local.function_app_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  service_plan_id            = azurerm_service_plan.asp.id
  storage_account_name       = azurerm_storage_account.storage.name
  storage_account_access_key = azurerm_storage_account.storage.primary_access_key

  functions_extension_version = "~4"
  https_only                  = true # Enforce HTTPS-only access (best practice):contentReference[oaicite:2]{index=2}

  identity {
    type = "SystemAssigned"
  }
  site_config {
    always_on = false
    application_stack {
      node_version = "22"
    }
  }

  app_settings = {
    SCM_DO_BUILD_DURING_DEPLOYMENT = "false"
    STORAGE_ACCOUNT_NAME           = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.storage_account_name.id})"
    STORAGE_ACCOUNT_KEY            = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.storage_account_key.id})"
    STORAGE_CONN_STRING            = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.storage_connection_string.id})"
    QR_SAS_EXPIRY_HOURS            = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.qr_sas_expiry_hours.id})"

  }
}


# ---------------------------------------------
# Function App Slot (Staging)
# ---------------------------------------------
resource "azurerm_linux_function_app_slot" "staging" {
  name                       = "staging"
  function_app_id            = azurerm_linux_function_app.functionapp.id
  storage_account_name       = azurerm_storage_account.storage.name
  storage_account_access_key = azurerm_storage_account.storage.primary_access_key

  site_config {
    always_on = false
    application_stack {
      node_version = "22"
    }
  }
  functions_extension_version = "~4"
  app_settings = {
    SCM_DO_BUILD_DURING_DEPLOYMENT = "false"
    STORAGE_ACCOUNT_NAME           = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.storage_account_name.id})"
    STORAGE_ACCOUNT_KEY            = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.storage_account_key.id})"
    STORAGE_CONN_STRING            = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.storage_connection_string.id})"
    QR_SAS_EXPIRY_HOURS            = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.qr_sas_expiry_hours.id})"
  }
}

# ---------------------------------------------
# Function App → Key Vault Secrets User
# ---------------------------------------------
resource "azurerm_role_assignment" "function_kv_secrets_user" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_function_app.functionapp.identity[0].principal_id
}


# ---------------------------------------------
# Azure Entra ID Application for Github Action
# ---------------------------------------------
resource "azuread_application" "github" {
  display_name = local.aad_application_name
  owners = [
    data.azuread_client_config.current.object_id
  ]
}

# ---------------------------------------------
# Github Action Service Principle
# ---------------------------------------------
resource "azuread_service_principal" "github" {
  client_id = azuread_application.github.client_id
  owners = [
    data.azuread_client_config.current.object_id
  ]
}

# ---------------------------------------------
# OIDC Federated Identity Credential
# ---------------------------------------------
resource "azuread_application_federated_identity_credential" "github" {
  application_id = azuread_application.github.id
  display_name   = local.federated_identity_name
  description    = "Deployments for my-repo"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_owner}/${var.github_repo}:ref:refs/heads/main"
}

# ---------------------------------------------------------------
# Github Action Service Principal Contributor Role Assignment
# ---------------------------------------------------------------
resource "azurerm_role_assignment" "sp_rg_assignment" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.github.object_id
}

# ---------------------------------------------------------------
# Github Action Repo Secrets variables
# ---------------------------------------------------------------
resource "github_actions_secret" "azure_tenant" {
  repository      = var.github_repo
  secret_name     = "AZURE_TENANT_ID"
  plaintext_value = data.azurerm_client_config.current.tenant_id
}
resource "github_actions_secret" "azure_subscription" {
  repository      = var.github_repo
  secret_name     = "AZURE_SUBSCRIPTION_ID"
  plaintext_value = data.azurerm_client_config.current.subscription_id
}
resource "github_actions_secret" "azure_client_id" {
  repository      = var.github_repo
  secret_name     = "AZURE_CLIENT_ID"
  plaintext_value = azuread_application.github.client_id
}
resource "github_actions_secret" "azure_function_name" {
  repository      = var.github_repo
  secret_name     = "FUNCTION_APP_NAME"
  plaintext_value = azurerm_linux_function_app.functionapp.name
}
resource "github_actions_secret" "azure_resource_group" {
  repository      = var.github_repo
  secret_name     = "RESOURCE_GROUP_NAME"
  plaintext_value = azurerm_resource_group.rg.name
}




