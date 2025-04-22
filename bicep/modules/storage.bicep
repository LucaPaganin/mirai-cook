@description('Azure region where the Storage Account will be created. Defaults to the resource group location.')
param location string = resourceGroup().location

@description('Prefix used for generating the Storage Account name. Should be globally unique when combined with uniqueString.')
param prefix string = 'mirai'

@description('SKU for the Storage Account.')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
  'Premium_ZRS'
])
param storageSkuName string = 'Standard_LRS'

@description('Tags to apply to the Storage Account.')
param tags object = {}

@description('Optional: The Principal ID of the Managed Identity to grant "Storage Blob Data Contributor" role. Leave empty to skip role assignment.')
param managedIdentityPrincipalId string = ''

// --- Variables ---
// Storage account names must be between 3 and 24 characters in length and use lowercase letters and numbers only.
// We combine the prefix with a unique string derived from the resource group ID for consistency and uniqueness.
// We take the first 18 chars of the unique string to leave room for the prefix and stay under 24 chars total.
var uniqueRgString = substring(uniqueString(resourceGroup().id), 0, 18)
// Ensure the final name is lowercase. Adjust prefix length if needed.
var storageAccountName = toLower('${prefix}${uniqueRgString}')

// --- Built-in Role Definition ID ---
// This is the fixed ID for the 'Storage Blob Data Contributor' role.
// Alternatively, you could construct it using subscriptionResourceId:
// var blobDataContributorRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
var blobDataContributorRoleDefinitionName = 'Storage Blob Data Contributor'


// --- Resources ---
@description('Azure Storage Account.')
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageSkuName
  }
  kind: 'StorageV2' // General-purpose v2 account
  tags: tags
  properties: {
    accessTier: 'Hot' // Default access tier
    allowBlobPublicAccess: false // Recommended default: disable public blob access
    minimumTlsVersion: 'TLS1_2' // Enforce modern TLS
    supportsHttpsTrafficOnly: true // Enforce HTTPS
    // Add other properties as needed (network rules, etc.)
  }
}

@description('Role Assignment for Managed Identity (if principal ID is provided).')
// This resource block will only be deployed if managedIdentityPrincipalId is not empty.
resource assignBlobContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(managedIdentityPrincipalId)) {
  name: guid(storageAccount.id, managedIdentityPrincipalId, blobDataContributorRoleDefinitionName) // Unique name for the role assignment
  scope: storageAccount // Assign the role at the scope of the storage account
  properties: {
    // Use the role definition name - Bicep resolves the ID automatically within the subscription
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal' // Managed Identities are Service Principals
  }
}

// --- Outputs ---
@description('The name of the created Storage Account.')
output storageAccountName string = storageAccount.name

@description('The resource ID of the created Storage Account.')
output storageAccountId string = storageAccount.id

@description('The primary endpoint for the Blob service.')
output primaryBlobEndpoint string = storageAccount.properties.primaryEndpoints.blob

@description('The principal ID used for the role assignment (empty if none).')
output assignedPrincipalId string = managedIdentityPrincipalId // Output the ID that was used
