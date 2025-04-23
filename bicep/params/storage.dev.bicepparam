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
