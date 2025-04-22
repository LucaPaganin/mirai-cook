@description('Azure region where the Cosmos DB account will be created. Defaults to the resource group location.')
param location string = resourceGroup().location

@description('Prefix used for generating the Cosmos DB account name. Must be globally unique.')
param prefix string = 'miraicook' // Use the consistent prefix

@description('Tags to apply to the Cosmos DB account.')
param tags object = {}

// Note: Consistency level is less critical for Serverless but still applicable. Session is a good default.
@description('The consistency level for the Cosmos DB account.')
@allowed([
  'Eventual'
  'ConsistentPrefix'
  'Session'
  'BoundedStaleness'
  'Strong'
])
param consistencyLevel string = 'Session'

@description('Optional: The Principal ID of the Managed Identity to grant "Cosmos DB Built-in Data Contributor" role for data plane RBAC. Leave empty to skip.')
param managedIdentityPrincipalId string = ''

// --- Variables ---
// Cosmos DB account names must be between 3 and 44 characters, lowercase letters, numbers, and the '-' character.
// Must be globally unique. We use the prefix and a unique string.
var uniqueRgString = substring(uniqueString(resourceGroup().id), 0, 10) // Shorter unique string part
var cosmosDbAccountName = toLower('${prefix}-cosmos-${uniqueRgString}')

// Fixed Role Definition ID for 'Cosmos DB Built-in Data Contributor'
var cosmosDbDataContributorRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '00000000-0000-0000-0000-000000000002')

// --- Resources ---
@description('Azure Cosmos DB Account (API for NoSQL) configured for Serverless capacity.')
resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2023-11-15' = {
  name: cosmosDbAccountName
  location: location
  tags: tags
  kind: 'GlobalDocumentDB' // Kind for API for NoSQL
  properties: {
    // --- Enable Serverless Capacity Mode ---
    capabilities: [
      {
        name: 'EnableServerless'
      }
    ]
    // --- End Serverless Configuration ---

    consistencyPolicy: consistencyLevel == 'Session' ? {
      defaultConsistencyLevel: 'Session'
    } : {
      defaultConsistencyLevel: consistencyLevel
      // Add maxStalenessPrefix and maxIntervalInSeconds if using BoundedStaleness
    }
    locations: [
      {
        locationName: location // Primary location
        failoverPriority: 0
        isZoneRedundant: false // Availability Zones not supported in Serverless tier
      }
      // Multi-region is supported with Serverless, but write locations are limited to one.
    ]
    databaseAccountOfferType: 'Standard' // Required property, remains 'Standard' even for Serverless
    enableMultipleWriteLocations: false // Must be false for Serverless
    enableAutomaticFailover: false // Configure automatic failover if using multiple read regions
    disableLocalAuth: false // Set to true to ONLY allow RBAC (recommended for higher security)
  }
}

@description('Assigns Data Contributor role to Managed Identity if principal ID is provided.')
resource assignCosmosDbDataContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(managedIdentityPrincipalId)) {
  name: guid(cosmosDbAccount.id, managedIdentityPrincipalId, 'CosmosDbDataContributor') // Unique name for the role assignment
  scope: cosmosDbAccount // Assign role at the Cosmos DB account scope
  properties: {
    roleDefinitionId: cosmosDbDataContributorRoleDefinitionId
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal' // Managed Identities are Service Principals
  }
}

// --- Outputs ---
@description('The name of the created Cosmos DB account.')
output cosmosDbAccountName string = cosmosDbAccount.name

@description('The resource ID of the created Cosmos DB account.')
output cosmosDbAccountId string = cosmosDbAccount.id

@description('The fully qualified domain name (endpoint) of the Cosmos DB account.')
output cosmosDbEndpoint string = cosmosDbAccount.properties.documentEndpoint

@description('Indicates if the account is configured for Serverless.')
output isServerless bool = contains(cosmosDbAccount.properties.capabilities, { name: 'EnableServerless' }) // Check if capability is present

@description('The principal ID used for the role assignment (empty if none).')
output assignedPrincipalId string = managedIdentityPrincipalId // Output the ID that was used
