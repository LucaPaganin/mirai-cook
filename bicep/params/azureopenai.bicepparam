// ./params/azureopenai.dev.bicepparam
// Self-contained parameter file for deploying azureopenai.bicep in a dev environment.
// Configured for the Standard tier (S0) and specific Managed Identity.

using '../modules/azureopenai.bicep' // Relative path to the bicep module file

// --- Parameters explicitly defined in this file ---

@description('Azure region where the Azure OpenAI service will be created. Check availability.')
// IMPORTANT: Azure OpenAI is not available in all regions. Verify availability for 'westeurope' or choose another supported region.
// Common regions include: East US, West Europe, France Central, UK South, Australia East, etc.
param location = 'westeurope' // Define the specific location (VERIFY AVAILABILITY)

@description('Prefix used for generating the Azure OpenAI service name.')
param prefix = 'miraicook' // Use the consistent project prefix

@description('Tags to apply to the Azure OpenAI service.')
param tags = {
  Project: 'MiraiCook'
  Environment: 'Development'
  Service: 'AzureOpenAI'
}

@description('The SKU for the Azure OpenAI service.')
param skuName = 'S0' // Standard tier (No general free tier)

@description('The Principal ID of the Managed Identity to grant "Cognitive Services User" role.')
// Assigning the specific Managed Identity provided previously.
param managedIdentityPrincipalId = '85264679-13ab-4eb6-a13b-e357e6dde820'

