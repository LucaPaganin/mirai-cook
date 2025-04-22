@description('Unique prefix for resources (e.g. abbreviated project name)')
param prefix string = 'miraicook'

@description('Azure location where to create the resource (e.g. resourceGroup().location)')
param location string = resourceGroup().location

// Builds a unique name for the identity
var userAssignedIdentityName = '${prefix}-identity-${uniqueString(resourceGroup().id)}'

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: userAssignedIdentityName
  location: location
}

@description('Principal ID (Object ID) of the created Managed Identity. Use this to assign roles.')
output identityPrincipalId string = userAssignedIdentity.properties.principalId

@description('Client ID of the created Managed Identity.')
output identityClientId string = userAssignedIdentity.properties.clientId

@description('Full Resource ID of the created Managed Identity.')
output identityResourceId string = userAssignedIdentity.id

@description('Name of the created Managed Identity.')
output identityName string = userAssignedIdentity.name
