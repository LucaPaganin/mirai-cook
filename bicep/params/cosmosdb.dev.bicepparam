// ./params/cosmosdb.dev.bicepparam
// Self-contained parameter file for deploying cosmosdb.bicep in a dev environment.
// All required parameters are explicitly defined here.

using '../modules/cosmosdb.bicep' // Relative path to the bicep module file

// --- Parameters explicitly defined in this file ---

@description('Azure region where the Cosmos DB account will be created.')
param location = 'westeurope' // Define the specific location

@description('Prefix used for generating the Cosmos DB account name.')
param prefix = 'miraicook' // Use the consistent project prefix

@description('Tags to apply to the Cosmos DB account.')
param tags = {
  Project: 'MiraiCook'
  Environment: 'Development'
  Service: 'CosmosDB'
}

@description('The consistency level for the Cosmos DB account.')
param consistencyLevel = 'Session' // Explicitly set consistency level (Session is a common default)

@description('Optional: The Principal ID of the Managed Identity to grant "Cosmos DB Built-in Data Contributor" role.')
// IMPORTANT: Replace the empty string with the ACTUAL Principal ID of your User-Assigned Managed Identity
// if you want to enable RBAC access for it. If left empty, the role assignment will be skipped.
// You typically get this ID from the output of the identity.bicep deployment.
param managedIdentityPrincipalId = '' // Example: 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'

