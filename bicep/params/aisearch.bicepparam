// ./params/aisearch.dev.bicepparam
// Self-contained parameter file for deploying aisearch.bicep in a dev environment.
// Configured for the Free tier and specific Managed Identity.

using '../modules/aisearch.bicep' // Relative path to the bicep module file

// --- Parameters explicitly defined in this file ---

@description('Azure region where the Search service will be created.')
param location = 'westeurope' // Define the specific location

@description('Prefix used for generating the Search service name.')
param prefix = 'miraicook' // Use the consistent project prefix

@description('Tags to apply to the Search service.')
param tags = {
  Project: 'MiraiCook'
  Environment: 'Development'
  Service: 'AISearch'
}

@description('The SKU for the Search service.')
param skuName = 'free' // Explicitly set to Free tier

@description('Number of replicas (Must be 1 for Free tier).')
param replicaCount = 1

@description('Number of partitions (Must be 1 for Free tier).')
param partitionCount = 1

@description('The Principal ID of the Managed Identity to grant "Search Service Contributor" role.')
// Assigning the specific Managed Identity provided previously.
param managedIdentityPrincipalId = '85264679-13ab-4eb6-a13b-e357e6dde820'

