@description('Azure region where the Search service will be created. Defaults to the resource group location.')
param location string = resourceGroup().location

@description('Prefix used for generating the Search service name. Must be globally unique.')
param prefix string = 'miraicook' // Use the consistent prefix

@description('Tags to apply to the Search service.')
param tags object = {}

@description('The SKU for the Search service. Free tier has limitations.')
@allowed([
  'free'
  'basic'
  'standard' // S1
  'standard2' // S2
  'standard3' // S3
  // Add storage optimized SKUs (L1, L2) if needed
])
param skuName string = 'free' // Default to Free tier

@description('Number of replicas. Must be 1 for Free tier. Scales query workload.')
param replicaCount int = 1

@description('Number of partitions. Must be 1 for Free tier. Scales index size/storage.')
param partitionCount int = 1

@description('Optional: The Principal ID of the Managed Identity to grant "Search Service Contributor" role. Leave empty to skip.')
param managedIdentityPrincipalId string = ''

// --- Variables ---
// Search service names must be globally unique, 2-60 chars, lowercase letters, numbers, or hyphens, no hyphen start/end/consecutive.
var uniqueRgString = substring(uniqueString(resourceGroup().id), 0, 10)
// Use a specific suffix like '-search'
var searchServiceName = toLower('${prefix}-search-${uniqueRgString}')

// Fixed Role Definition ID for 'Search Service Contributor'
// Allows managing the search service (indexes, indexers, datasources, etc.) but not data plane access (querying).
// For querying with RBAC, use 'Search Index Data Reader' or 'Search Index Data Contributor'.
var searchServiceContributorRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7ca78c08-252a-4471-8644-bb5ff32d4ba0')

// --- Resources ---
@description('Azure AI Search Service.')
resource searchService 'Microsoft.Search/searchServices@2023-11-01' = {
  name: searchServiceName
  location: location
  tags: tags
  sku: {
    name: skuName
  }
  properties: {
    replicaCount: replicaCount
    partitionCount: partitionCount
    hostingMode: (skuName == 'free' || skuName == 'basic') ? 'default' : 'highDensity' // Required for S3, optional for S1/S2
    publicNetworkAccess: 'Enabled' // Default is enabled, can be set to 'Disabled' for private endpoint scenarios
    // semanticSearch: (skuName == 'free') ? 'disabled' : 'standard' // Enable semantic search for paid tiers if needed
  }
}

@description('Assigns Search Service Contributor role to Managed Identity if principal ID is provided.')
resource assignSearchServiceContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(managedIdentityPrincipalId)) {
  name: guid(searchService.id, managedIdentityPrincipalId, 'SearchServiceContributor') // Unique name for the role assignment
  scope: searchService // Assign role at the Search service scope
  properties: {
    roleDefinitionId: searchServiceContributorRoleDefinitionId
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal' // Managed Identities are Service Principals
  }
}

// --- Outputs ---
@description('The name of the created Search service.')
output searchServiceName string = searchService.name

@description('The resource ID of the created Search service.')
output searchServiceId string = searchService.id

@description('The primary admin key for the Search service. Handle with care; prefer RBAC.')
// Note: Retrieving keys might require specific permissions during deployment.
// It's often better to get keys post-deployment and store in Key Vault if RBAC isn't sufficient.
output primaryAdminKey string = listAdminKeys(searchService.id, searchService.apiVersion).primaryKey

@description('The principal ID used for the role assignment (empty if none).')
output assignedPrincipalId string = managedIdentityPrincipalId // Output the ID that was used
