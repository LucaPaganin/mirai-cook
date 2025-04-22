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

if (-not $WhatIf) {
    # Save outputs to bicep/outputs/<template>.outputs.json
    $templateBaseName = [System.IO.Path]::GetFileNameWithoutExtension($BicepTemplateFile)
    $outputsFolder = Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "outputs"
    if (-not (Test-Path $outputsFolder)) {
        New-Item -ItemType Directory -Path $outputsFolder | Out-Null
    }
    # Get latest deployment name
    $deploymentName = az deployment group list --resource-group $ResourceGroupName --query "sort_by([].{name:name, ts:properties.timestamp}, &ts)[-1].name" -o tsv
    if ($deploymentName) {
        $outputsJson = az deployment group show -g $ResourceGroupName -n $deploymentName --query properties.outputs -o json
        if ($outputsJson) {
            $outputsFile = Join-Path $outputsFolder "$templateBaseName.outputs.json"
            Set-Content -Path $outputsFile -Value $outputsJson -Encoding UTF8
            Write-Host "Deployment outputs saved to: $outputsFile"
        } else {
            Write-Host "No outputs found for deployment."
        }
    } else {
        Write-Host "Could not determine deployment name to fetch outputs."
    }
}

Write-Host "Deployment finished."
