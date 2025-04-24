@description('Azure region where the Language service will be created. Defaults to the resource group location.')
param location string = resourceGroup().location

@description('Prefix used for generating the Language service name. Must be globally unique.')
param prefix string = 'miraicook' // Use the consistent prefix

@description('Tags to apply to the Language service.')
param tags object = {}

@description('The SKU for the Language service. F0 is the Free tier.')
@allowed([
  'F0' // Free tier
  'S'  // Standard tier (Note: Language uses 'S', not 'S0' like others)
])
param skuName string = 'F0' // Default to Free tier

@description('Optional: The Principal ID of the Managed Identity to grant "Cognitive Services User" role. This allows the identity to use the service. Leave empty to skip.')
param managedIdentityPrincipalId string = ''

// --- Variables ---
// Cognitive Services account names must be globally unique, 2-64 chars, alphanumeric and hyphens, no hyphen start/end.
var uniqueRgString = substring(uniqueString(resourceGroup().id), 0, 10)
// Use a specific suffix like '-lang'
var languageAccountName = toLower('${prefix}-lang-${uniqueRgString}')

// Fixed Role Definition ID for 'Cognitive Services User'
var cognitiveServicesUserRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'a97b65f3-24c7-4388-baec-2e87135dc908')

// --- Resources ---
@description('Azure AI Language Service Account.')
resource languageAccount 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: languageAccountName
  location: location
  tags: tags
  sku: {
    name: skuName
  }
  kind: 'TextAnalytics' // Specifies the Language service type
  properties: {
    // API properties can be customized here if needed (e.g., network rules, custom subdomain)
    customSubDomainName: languageAccountName // Optional: Use account name for custom subdomain
    publicNetworkAccess: 'Enabled' // Default is enabled, can be set to 'Disabled' for private endpoint scenarios
  }
}

@description('Assigns Cognitive Services User role to Managed Identity if principal ID is provided.')
resource assignCognitiveServicesUserRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(managedIdentityPrincipalId)) {
  name: guid(languageAccount.id, managedIdentityPrincipalId, 'CognitiveServicesUser') // Unique name for the role assignment
  scope: languageAccount // Assign role at the Language account scope
  properties: {
    roleDefinitionId: cognitiveServicesUserRoleDefinitionId
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal' // Managed Identities are Service Principals
  }
}

// --- Outputs ---
@description('The name of the created Language account.')
output languageAccountName string = languageAccount.name

@description('The resource ID of the created Language account.')
output languageAccountId string = languageAccount.id

@description('The endpoint for the created Language account.')
output languageEndpoint string = languageAccount.properties.endpoint

@description('The principal ID used for the role assignment (empty if none).')
output assignedPrincipalId string = managedIdentityPrincipalId // Output the ID that was used
