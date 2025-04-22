@description('Azure region where the User-Assigned Managed Identity will be created. Defaults to the resource group location.')
param location string = resourceGroup().location

@description('The name for the User-Assigned Managed Identity. Should be unique within the resource group.')
param identityName string

@description('Tags to apply to the Managed Identity.')
param tags object = {}

@description('User-Assigned Managed Identity resource.')
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: identityName
  location: location
  tags: tags
}

@description('The Principal ID (Object ID of the service principal) for the Managed Identity.')
output identityPrincipalId string = managedIdentity.properties.principalId

@description('The Client ID for the Managed Identity.')
output identityClientId string = managedIdentity.properties.clientId

@description('The name of the created Managed Identity.')
output identityName string = managedIdentity.name

@description('The resource ID of the created Managed Identity.')
output identityResourceId string = managedIdentity.id
