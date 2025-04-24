// ./params/speech.dev.bicepparam
// Self-contained parameter file for deploying speech.bicep in a dev environment.
// Configured for the Free tier (F0) and specific Managed Identity.

using '../modules/speech.bicep' // Relative path to the bicep module file

// --- Parameters explicitly defined in this file ---

@description('Azure region where the Speech service will be created.')
param location = 'westeurope' // Define the specific location

@description('Prefix used for generating the Speech service name.')
param prefix = 'miraicook' // Use the consistent project prefix

@description('Tags to apply to the Speech service.')
param tags = {
  Project: 'MiraiCook'
  Environment: 'Development'
  Service: 'Speech'
}

@description('The SKU for the Speech service.')
param skuName = 'F0' // Explicitly set to Free tier

@description('The Principal ID of the Managed Identity to grant "Cognitive Services User" role.')
// Assigning the specific Managed Identity provided previously.
param managedIdentityPrincipalId = '85264679-13ab-4eb6-a13b-e357e6dde820'

