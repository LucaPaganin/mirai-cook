@description('Azure region where the Azure OpenAI service will be created. Defaults to the resource group location. Note: Check Azure OpenAI region availability.')
param location string = resourceGroup().location

@description('Prefix used for generating the Azure OpenAI service name. Must be globally unique.')
param prefix string = 'miraicook' // Use the consistent prefix

@description('Tags to apply to the Azure OpenAI service.')
param tags object = {}

@description('The SKU for the Azure OpenAI service. S0 is the standard tier.')
@allowed([
  'S0' // Standard tier for Azure OpenAI
  // Check Azure documentation for other potential SKUs if needed
])
param skuName string = 'S0' // Default to Standard tier

@description('Optional: The Principal ID of the Managed Identity to grant "Cognitive Services User" role. This allows the identity to use the service. Leave empty to skip.')
param managedIdentityPrincipalId string = ''

// --- Variables ---
// Cognitive Services account names must be globally unique, 2-64 chars, alphanumeric and hyphens, no hyphen start/end.
var uniqueRgString = substring(uniqueString(resourceGroup().id), 0, 10)
// Use a specific suffix like '-openai'
var openAiAccountName = toLower('${prefix}-openai-${uniqueRgString}')

// Fixed Role Definition ID for 'Cognitive Services User'
var cognitiveServicesUserRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'a97b65f3-24c7-4388-baec-2e87135dc908')

// --- Resources ---
@description('Azure OpenAI Service Account.')
resource openAiAccount 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: openAiAccountName
  location: location
  tags: tags
  sku: {
    name: skuName
  }
  kind: 'OpenAI' // Specifies the Azure OpenAI service type
  properties: {
    // API properties can be customized here if needed (e.g., network rules, custom subdomain)
    customSubDomainName: openAiAccountName // Optional: Use account name for custom subdomain
    publicNetworkAccess: 'Enabled' // Default is enabled, can be set to 'Disabled' for private endpoint scenarios
    // Azure OpenAI specific properties might be added here in future API versions
  }
}

@description('Assigns Cognitive Services User role to Managed Identity if principal ID is provided.')
resource assignCognitiveServicesUserRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(managedIdentityPrincipalId)) {
  name: guid(openAiAccount.id, managedIdentityPrincipalId, 'CognitiveServicesUser') // Unique name for the role assignment
  scope: openAiAccount // Assign role at the Azure OpenAI account scope
  properties: {
    roleDefinitionId: cognitiveServicesUserRoleDefinitionId
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal' // Managed Identities are Service Principals
  }
}

// --- Outputs ---
@description('The name of the created Azure OpenAI account.')
output openAiAccountName string = openAiAccount.name

@description('The resource ID of the created Azure OpenAI account.')
output openAiAccountId string = openAiAccount.id

@description('The endpoint for the created Azure OpenAI account.')
output openAiEndpoint string = openAiAccount.properties.endpoint

// Note: Keys are intentionally not outputted for security.
// Use Managed Identity + RBAC (recommended) or retrieve keys securely post-deployment
// and store them in Key Vault.

@description('The principal ID used for the role assignment (empty if none).')
output assignedPrincipalId string = managedIdentityPrincipalId // Output the ID that was used
