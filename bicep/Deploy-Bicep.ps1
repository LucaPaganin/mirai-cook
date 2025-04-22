<#
.SYNOPSIS
Deploys a Bicep template to a specific Resource Group,
using common parameters from a configuration file and specific parameters
from a .bicepparam file.

.PARAMETER BicepTemplateFile
Path to the .bicep file to deploy. (Required)

.PARAMETER BicepParameterFile
Path to the .bicepparam file specific for this template. (Optional)
Parameters defined here override common/dynamic ones.

.PARAMETER WhatIf
Switch to run the deployment in What-If mode. (Optional)

.EXAMPLE
.\Deploy-Bicep.ps1 -BicepTemplateFile .\modules\storage.bicep -BicepParameterFile .\params\storage.dev.bicepparam

.EXAMPLE
.\Deploy-Bicep.ps1 -BicepTemplateFile .\modules\keyvault.bicep

.EXAMPLE
.\Deploy-Bicep.ps1 -BicepTemplateFile .\modules\storage.bicep -WhatIf
#>
param(
    [Parameter(Mandatory=$true)]
    [ValidateScript({Test-Path $_ -PathType Leaf})]
    [string]$BicepTemplateFile,

    [Parameter(Mandatory=$false)]
    [ValidateScript({Test-Path $_ -PathType Leaf})]
    [string]$BicepParameterFile,

    [Parameter(Mandatory=$false)]
    [switch]$WhatIf
)

$ResourceGroupName = "mirai-cook"

Write-Host "Deploying '$BicepTemplateFile' to resource group '$ResourceGroupName'..."

if ($WhatIf) {
    $azCmd = @(
        'deployment', 'group', 'what-if',
        '--resource-group', $ResourceGroupName,
        '--template-file', $BicepTemplateFile
    )
} else {
    $azCmd = @(
        'deployment', 'group', 'create',
        '--resource-group', $ResourceGroupName,
        '--template-file', $BicepTemplateFile
    )
}

if ($BicepParameterFile) {
    $azCmd += @('--parameters', $BicepParameterFile)
}

az @azCmd

Write-Host "Deployment finished."
