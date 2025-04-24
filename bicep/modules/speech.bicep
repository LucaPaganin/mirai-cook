@description('Azure region where the Speech service will be created. Defaults to the resource group location.')
param location string = resourceGroup().location

@description('Prefix used for generating the Speech service name. Must be globally unique.')
param prefix string = 'miraicook' // Use the consistent prefix

@description('Tags to apply to the Speech service.')
param tags object = {}

@description('The SKU for the Speech service. F0 is the Free tier.')
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
// Use a specific suffix like '-speech'
var speechAccountName = toLower('${prefix}-speech-${uniqueRgString}')

// Fixed Role Definition ID for 'Cognitive Services User'
var cognitiveServicesUserRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'a97b65f3-24c7-4388-baec-2e87135dc908')

// --- Resources ---
@description('Azure AI Speech Service Account.')
resource speechAccount 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: speechAccountName
  location: location
  tags: tags
  sku: {
    name: skuName
  }
  kind: 'SpeechServices' // Specifies the Speech service type
  properties: {
    // API properties can be customized here if needed (e.g., network rules, custom subdomain)
    customSubDomainName: speechAccountName // Optional: Use account name for custom subdomain
    publicNetworkAccess: 'Enabled' // Default is enabled, can be set to 'Disabled' for private endpoint scenarios
  }
}

@description('Assigns Cognitive Services User role to Managed Identity if principal ID is provided.')
resource assignCognitiveServicesUserRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(managedIdentityPrincipalId)) {
  name: guid(speechAccount.id, managedIdentityPrincipalId, 'CognitiveServicesUser') // Unique name for the role assignment
  scope: speechAccount // Assign role at the Speech account scope
  properties: {
    roleDefinitionId: cognitiveServicesUserRoleDefinitionId
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal' // Managed Identities are Service Principals
  }
}

// --- Outputs ---
@description('The name of the created Speech account.')
output speechAccountName string = speechAccount.name

@description('The resource ID of the created Speech account.')
output speechAccountId string = speechAccount.id

@description('The endpoint for the created Speech account.')
output speechEndpoint string = speechAccount.properties.endpoint

// Note: Keys are intentionally not outputted for security.
// Use Managed Identity + RBAC (recommended) or retrieve keys securely post-deployment
// and store them in Key Vault.

@description('The principal ID used for the role assignment (empty if none).')
output assignedPrincipalId string = managedIdentityPrincipalId // Output the ID that was used
