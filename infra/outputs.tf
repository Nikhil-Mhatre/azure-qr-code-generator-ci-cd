# outputs.tf

output "resource_group_name" {
  value       = azurerm_resource_group.rg.name
  description = "Name of the resource group"
}

output "storage_account_name" {
  value       = azurerm_storage_account.storage.name
  description = "Name of the storage account"
}
output "storage_container_name" {
  value       = azurerm_storage_container.image_container.name
  description = "Name of the storage container"
}
output "key_vault_name" {
  value       = azurerm_key_vault.kv.name
  description = "Name of the Key Vault"
}

output "azure_service_plan_sku" {
  value       = azurerm_service_plan.asp.sku_name
  description = "Service Plan SKU"
}


output "function_app_name" {
  value       = azurerm_linux_function_app.functionapp.name
  description = "Name of the Azure Function App"
}

output "function_slot_name" {
  value       = azurerm_linux_function_app_slot.staging.name
  description = "Name of the Azure Function App"
}


