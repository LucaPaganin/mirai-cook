@description('Azure region where the Document Intelligence service will be created. Defaults to the resource group location.')
param location string = resourceGroup().location

@description('Prefix used for generating the Document Intelligence service name. Must be globally unique.')
param prefix string = 'miraicook' // Use the consistent prefix

@description('Tags to apply to the Document Intelligence service.')
param tags object = {}

@description('The SKU for the Document Intelligence service. F0 is the Free tier.')
@allowed([
  'F0' // Free tier
  'S0' // Standard tier
])
param skuName string = 'F0' // Default to Free tier

@description('Optional: The Principal ID of the Managed Identity to grant "Cognitive Services User" role. This allows the identity to use the service. Leave empty to skip.')
param managedIdentityPrincipalId string = ''

// --- Variables ---
// Cognitive Services account names must be globally unique, 2-64 chars, alphanumeric and hyphens, no hyphen start/end.
var uniqueRgString = substring(uniqueString(resourceGroup().id), 0, 10)
// Use a specific suffix like '-docintel' to differentiate from other AI services
var docIntelligenceAccountName = toLower('${prefix}-docintel-${uniqueRgString}')

// Fixed Role Definition ID for 'Cognitive Services User'
var cognitiveServicesUserRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'a97b65f3-24c7-4388-baec-2e87135dc908')

// --- Resources ---
@description('Azure AI Document Intelligence Service Account.')
resource docIntelligenceAccount 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: docIntelligenceAccountName
  location: location
  tags: tags
  sku: {
    name: skuName
  }
  kind: 'FormRecognizer' // Specifies the Document Intelligence service type
  properties: {
    // API properties can be customized here if needed (e.g., network rules, custom subdomain)
    customSubDomainName: docIntelligenceAccountName // Optional: Use account name for custom subdomain
    publicNetworkAccess: 'Enabled' // Default is enabled, can be set to 'Disabled' for private endpoint scenarios
  }
}

@description('Assigns Cognitive Services User role to Managed Identity if principal ID is provided.')
resource assignCognitiveServicesUserRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(managedIdentityPrincipalId)) {
  name: guid(docIntelligenceAccount.id, managedIdentityPrincipalId, 'CognitiveServicesUser') // Unique name for the role assignment
  scope: docIntelligenceAccount // Assign role at the Document Intelligence account scope
  properties: {
    roleDefinitionId: cognitiveServicesUserRoleDefinitionId
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal' // Managed Identities are Service Principals
  }
}

// --- Outputs ---
@description('The name of the created Document Intelligence account.')
output docIntelligenceAccountName string = docIntelligenceAccount.name

@description('The resource ID of the created Document Intelligence account.')
output docIntelligenceAccountId string = docIntelligenceAccount.id

@description('The endpoint for the created Document Intelligence account.')
output docIntelligenceEndpoint string = docIntelligenceAccount.properties.endpoint

// Note: Keys are intentionally not outputted for security.
// Use Managed Identity + RBAC (recommended) or retrieve keys securely post-deployment
// and store them in Key Vault.

@description('The principal ID used for the role assignment (empty if none).')
output assignedPrincipalId string = managedIdentityPrincipalId // Output the ID that was used
