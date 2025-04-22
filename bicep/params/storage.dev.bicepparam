// ./params/storage.dev.bicepparam
// Example parameter file for deploying storage.bicep in a dev environment.
// Assumes location and managedIdentityPrincipalId will be passed by the deployment script.

using '../modules/storage.bicep' // Relative path to the bicep module file

param prefix = 'miraicook' // UPDATED: Use the consistent project prefix

param storageSkuName = 'Standard_LRS' // Explicitly set SKU for dev (could be omitted if default is ok)

param tags = { // Override common tags or add specific ones for this resource/env
  Project: 'MiraiCook'
  Environment: 'Development'
  CostCenter: 'DevTeam1'
}

// NOTE: We DO NOT specify 'location' or 'managedIdentityPrincipalId' here.
// - 'location' should ideally come from the common config (config.psd1) or resource group.
// - 'managedIdentityPrincipalId' should be passed dynamically by the Deploy-Bicep.ps1 script,
//   likely retrieved from the output of the identity.bicep deployment.
//   If you don't need role assignment for this specific storage account,
//   ensure the script passes an empty string or null for managedIdentityPrincipalId.

