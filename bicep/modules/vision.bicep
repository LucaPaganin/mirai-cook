@description('Azure region where the Vision service will be created. Defaults to the resource group location.')
param location string = resourceGroup().location

@description('Prefix used for generating the Vision service name. Must be globally unique.')
param prefix string = 'miraicook' // Use the consistent prefix

@description('Tags to apply to the Vision service.')
param tags object = {}

@description('The SKU for the Vision service. F0 is the Free tier.')
@allowed([
  'F0' // Free tier
  'S1' // Standard tier (Note: Vision often uses 'S1')
])
param skuName string = 'F0' // Default to Free tier

@description('Optional: The Principal ID of the Managed Identity to grant "Cognitive Services User" role. This allows the identity to use the service. Leave empty to skip.')
param managedIdentityPrincipalId string = ''

// --- Variables ---
// Cognitive Services account names must be globally unique, 2-64 chars, alphanumeric and hyphens, no hyphen start/end.
var uniqueRgString = substring(uniqueString(resourceGroup().id), 0, 10)
// Use a specific suffix like '-vision'
var visionAccountName = toLower('${prefix}-vision-${uniqueRgString}')

// Fixed Role Definition ID for 'Cognitive Services User'
var cognitiveServicesUserRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'a97b65f3-24c7-4388-baec-2e87135dc908')

// --- Resources ---
@description('Azure AI Vision Service Account.')
resource visionAccount 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: visionAccountName
  location: location
  tags: tags
  sku: {
    name: skuName
  }
  kind: 'ComputerVision' // Specifies the Vision service type
  properties: {
    // API properties can be customized here if needed (e.g., network rules, custom subdomain)
    customSubDomainName: visionAccountName // Optional: Use account name for custom subdomain
    publicNetworkAccess: 'Enabled' // Default is enabled, can be set to 'Disabled' for private endpoint scenarios
  }
}

@description('Assigns Cognitive Services User role to Managed Identity if principal ID is provided.')
resource assignCognitiveServicesUserRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(managedIdentityPrincipalId)) {
  name: guid(visionAccount.id, managedIdentityPrincipalId, 'CognitiveServicesUser') // Unique name for the role assignment
  scope: visionAccount // Assign role at the Vision account scope
  properties: {
    roleDefinitionId: cognitiveServicesUserRoleDefinitionId
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal' // Managed Identities are Service Principals
  }
}

// --- Outputs ---
@description('The name of the created Vision account.')
output visionAccountName string = visionAccount.name

@description('The resource ID of the created Vision account.')
output visionAccountId string = visionAccount.id

@description('The endpoint for the created Vision account.')
output visionEndpoint string = visionAccount.properties.endpoint

@description('The principal ID used for the role assignment (empty if none).')
output assignedPrincipalId string = managedIdentityPrincipalId // Output the ID that was used
