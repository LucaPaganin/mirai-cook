// ./params/identity.dev.bicepparam
// Example parameter file for deploying identity.bicep in a dev environment.
// This file explicitly defines all required parameters.

using '../modules/identity.bicep' // Relative path to the bicep module file

// --- Parameters explicitly defined in this file ---

@description('The name for the User-Assigned Managed Identity.')
param identityName = 'miraicook-dev-id' // Example name for the development identity

@description('Azure region where the identity will be created.')
param location = 'westeurope' // Example location for development resources

@description('Tags to apply to the Managed Identity.')
param tags = {
  Project: 'MiraiCook'
  Environment: 'Development'
  Purpose: 'ApplicationIdentity'
}

// Note: When using this file directly with 'az deployment group create',
// ensure the 'identityName' is unique within the target resource group and subscription.
// The PowerShell script approach often adds a unique suffix automatically.
