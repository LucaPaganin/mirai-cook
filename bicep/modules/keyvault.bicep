@description('Unique prefix for resources (e.g. abbreviated project name)')
param prefix string = 'miraicook'

@description('Azure location where to create the resource (e.g. resourceGroup().location)')
param location string = resourceGroup().location

@description('Azure Tenant ID where the subscription resides.')
param tenantId string = subscription().tenantId

@description('Principal ID (Object ID) of the identity (user, group or Managed Identity) to grant permissions to READ secrets (e.g. the ID of the Managed Identity created with identity.bicep).')
param secretsReaderPrincipalId string

@description('Principal ID (Object ID) of the identity (user or group) to grant permissions to MANAGE secrets (e.g. your user or an admin group).')
param secretsOfficerPrincipalId string

// --- FIX: Shortened Key Vault Name ---
// We use substring to limit the unique part and stay within the 24 character limit.
// prefix (max ~10) + '-kv-' (4) + unique part (max 10) = max 24
// We take only the first 10 characters of the unique string.
var uniqueSuffix = substring(uniqueString(resourceGroup().id), 0, 10)
var keyVaultName = '${prefix}-kv-${uniqueSuffix}' // Now shorter name

// Definition of GUIDs for Key Vault RBAC roles
var keyVaultSecretsUserRoleDefinitionId = resourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6') // Key Vault Secrets User (Get/List)
var keyVaultSecretsOfficerRoleDefinitionId = resourceId('Microsoft.Authorization/roleDefinitions', 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7') // Key Vault Secrets Officer (All secrets actions)

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName // Use the shortened name
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenantId
    enableRbacAuthorization: true // Enable RBAC for data permissions management
    // Add network configurations (networkAcls) here if needed
  }
}

// Assign the "Key Vault Secrets User" role to the application's Managed Identity
resource kvSecretsReaderRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, secretsReaderPrincipalId, keyVaultSecretsUserRoleDefinitionId)
  scope: keyVault
  properties: {
    roleDefinitionId: keyVaultSecretsUserRoleDefinitionId
    principalId: secretsReaderPrincipalId
    principalType: 'ServicePrincipal' // Assuming it's a Managed Identity or SP
  }
}

// Assign the "Key Vault Secrets Officer" role to the admin user/group
resource kvSecretsOfficerRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, secretsOfficerPrincipalId, keyVaultSecretsOfficerRoleDefinitionId)
  scope: keyVault
  properties: {
    roleDefinitionId: keyVaultSecretsOfficerRoleDefinitionId
    principalId: secretsOfficerPrincipalId
    principalType: 'User' // Or 'Group', depending on what you pass
  }
  dependsOn: [
    kvSecretsReaderRoleAssignment // Depends on the previous assignment
  ]
}

@description('URI of the created Key Vault. To be used to access secrets.')
output keyVaultUri string = keyVault.properties.vaultUri

@description('Name of the created Key Vault.')
output keyVaultName string = keyVault.name

@description('Resource ID of the created Key Vault.')
output keyVaultResourceId string = keyVault.id
