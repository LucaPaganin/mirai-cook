// ./params/language.dev.bicepparam
// Self-contained parameter file for deploying language.bicep in a dev environment.
// Configured for the Free tier (F0) and specific Managed Identity.

using '../modules/language.bicep' // Relative path to the bicep module file

// --- Parameters explicitly defined in this file ---

@description('Azure region where the Language service will be created.')
param location = 'westeurope' // Define the specific location

@description('Prefix used for generating the Language service name.')
param prefix = 'miraicook' // Use the consistent project prefix

@description('Tags to apply to the Language service.')
param tags = {
  Project: 'MiraiCook'
  Environment: 'Development'
  Service: 'Language'
}

@description('The SKU for the Language service.')
param skuName = 'F0' // Explicitly set to Free tier

@description('The Principal ID of the Managed Identity to grant "Cognitive Services User" role.')
// Assigning the specific Managed Identity provided previously.
param managedIdentityPrincipalId = '85264679-13ab-4eb6-a13b-e357e6dde820'

