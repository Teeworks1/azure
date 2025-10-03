data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "velero" {
  name                        = "teeworkskeyxx"
  location                    = azurerm_resource_group.velero.location
  resource_group_name         = azurerm_resource_group.velero.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  enable_rbac_authorization = true

  sku_name = "standard"

#   access_policy {
#     tenant_id = data.azurerm_client_config.current.tenant_id
#     object_id = data.azurerm_client_config.current.object_id

#     key_permissions = [
#       "Get", "Create","Decrypt", "Delete", "Encrypt", "Import", "List", "Purge", "Recover", "Restore", "Sign", "UnwrapKey", "Update", "Verify", "WrapKey", "Release", "Rotate",
#     ]

#     secret_permissions = [
#       "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"
#     ]

#     storage_permissions = [
#       "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge",]
#   }
}

resource "azurerm_key_vault_secret" "velero" {
  name         = "db-password"
  value        = "SuperSecret123"
  key_vault_id = azurerm_key_vault.velero.id

#    lifecycle {
#     prevent_destroy = true
#   }
  depends_on = [ azurerm_role_assignment.terraform_kv_secret_admin ]
}

# Give AKS Managed Identity access
# resource "azurerm_key_vault_access_policy" "aks" {
#   key_vault_id = azurerm_key_vault.velero.id
#   tenant_id    = data.azurerm_client_config.current.tenant_id
# #   object_id    = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
#     object_id    = data.azurerm_client_config.current.object_id

#   secret_permissions = ["Get", "List"]
# }

# resource "kubernetes_manifest" "azure_secret_provider_class" {
#   manifest = {
#     "apiVersion" = "secrets-store.csi.x-k8s.io/v1"
#     "kind"       = "SecretProviderClass"
#     "metadata" = {
#       "name"      = "azure-kv-spc"
#       "namespace" = "default"
#     }
#     "spec" = {
#       "provider" = "azure"
#       "parameters" = {
#         "usePodIdentity"     = "false"
#         "useVMManagedIdentity" = "true"
#         "userAssignedIdentityID" = azurerm_user_assigned_identity.aks_identity.client_id
#         "keyvaultName"       = azurerm_key_vault.velero.name
#         "cloudName"          = "AzurePublicCloud"
#         "objects"            = <<EOT
#           array:
#             - |
#               objectName: db-password
#               objectType: secret
#               objectVersion: ""
#         EOT
#         "tenantId"           = data.azurerm_client_config.current.tenant_id
#       }
#     }
#   }
# }
resource "azurerm_user_assigned_identity" "aks_identity" {
  location            = azurerm_resource_group.velero.location
  name                = "aks-identity"
  resource_group_name = azurerm_resource_group.velero.name
}