<#
.SYNOPSIS
Deploys a Bicep template to a specific Resource Group,
using common parameters from a configuration file and specific parameters
from a .bicepparam file.

.PARAMETER BicepTemplateFile
Path to the .bicep file to deploy. (Required)

.PARAMETER ResourceGroupName
Name of the target Resource Group. (Required)

.PARAMETER BicepParameterFile
Path to the .bicepparam file specific for this template. (Optional)
Parameters defined here override common/dynamic ones.

.PARAMETER CommonConfigFile
Path to the .psd1 file with common parameters. (Optional, default: .\config.psd1)

.PARAMETER WhatIf
Runs the deployment in What-If mode to preview changes without applying them. (Optional)

.EXAMPLE
.\Deploy-Bicep.ps1 -BicepTemplateFile .\modules\storage.bicep -ResourceGroupName MiraiCook-RG -BicepParameterFile .\params\storage.dev.bicepparam

.EXAMPLE
.\Deploy-Bicep.ps1 -BicepTemplateFile .\modules\keyvault.bicep -ResourceGroupName MiraiCook-RG -WhatIf
#>
param(
    [Parameter(Mandatory=$true)]
    [ValidateScript({Test-Path $_ -PathType Leaf})]
    [string]$BicepTemplateFile,

    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory=$false)]
    [ValidateScript({Test-Path $_ -PathType Leaf})]
    [string]$BicepParameterFile,

    [Parameter(Mandatory=$false)]
    [ValidateScript({Test-Path $_ -PathType Leaf})]
    [string]$CommonConfigFile = ".\config.psd1", # Assume it's in the same folder as the script or provided with path

    [Parameter(Mandatory=$false)]
    [switch]$WhatIf
)

# --- Script Start ---
Write-Host "Starting Bicep deployment for '$BicepTemplateFile' in Resource Group '$ResourceGroupName'" -ForegroundColor Cyan

# --- 1. Load Common Configuration ---
$commonConfig = @{}
if (Test-Path $CommonConfigFile) {
    try {
        Write-Host "Loading common configuration from '$CommonConfigFile'..."
        # Use Invoke-Expression to interpret the .psd1 file as PowerShell code
        $commonConfig = Invoke-Expression (Get-Content $CommonConfigFile -Raw)
        Write-Host "Common configuration loaded." -ForegroundColor Green
    } catch {
        Write-Error "Error loading common configuration file '$CommonConfigFile': $_"
        exit 1
    }
} else {
    Write-Warning "Common configuration file '$CommonConfigFile' not found. Proceeding without common parameters."
}

# --- 2. Get Azure CLI Context ---
Write-Host "Retrieving Azure CLI context..."
try {
    $azContext = az account show --query '{subscriptionId:id, tenantId:tenantId, environmentName:environmentName}' -o json | ConvertFrom-Json
    $loggedInUser = az ad signed-in-user show --query '{objectId:id, userPrincipalName:userPrincipalName}' -o json | ConvertFrom-Json
    Write-Host "  Subscription: $($azContext.subscriptionId)"
    Write-Host "  Tenant: $($azContext.tenantId)"
    Write-Host "  User: $($loggedInUser.userPrincipalName) ($($loggedInUser.objectId))"
} catch {
    Write-Error "Error retrieving Azure context. Make sure you are logged in with 'az login' and Azure CLI is working properly. $_"
    exit 1
}

# --- 3. Initialize Hashtable for Azure CLI Parameters ---
# Use a hashtable to dynamically build parameters
$azCliParameters = @{}

# --- 4. Populate Parameters (Precedence Order: Specific > Common > Dynamic) ---

# 4a. Dynamic/Contextual Values (Low Priority)
# Add them only if your Bicep explicitly requires them as 'param'
# $azCliParameters.subscriptionId = $azContext.subscriptionId
# $azCliParameters.tenantId = $azContext.tenantId
# $azCliParameters.resourceGroupName = $ResourceGroupName # Usually not needed as a param for Bicep
$azCliParameters.loggedInUserObjectId = $loggedInUser.objectId # Useful if you need the deployer's ID

# 4b. Values from Common Configuration (Medium Priority)
if ($commonConfig) {
    # Example: Add location, prefix, tags, etc. IF THEY EXIST in the config file
    if ($commonConfig.ContainsKey('location'))     { $azCliParameters.location = $commonConfig.location }
    if ($commonConfig.ContainsKey('projectPrefix')){ $azCliParameters.prefix = $commonConfig.projectPrefix } # Note: Bicep must have 'prefix' param
    if ($commonConfig.ContainsKey('commonTags'))   { $azCliParameters.tags = $commonConfig.commonTags }     # Bicep must have 'tags' param of type object
    if ($commonConfig.ContainsKey('adminObjectIds')){ $azCliParameters.adminObjectIds = $commonConfig.adminObjectIds } # Bicep must have 'adminObjectIds' param of type array
    if ($commonConfig.ContainsKey('defaultKeyVaultSku')) { $azCliParameters.keyVaultSkuName = $commonConfig.defaultKeyVaultSku } # Bicep must have 'keyVaultSkuName' param
    # ... Add other common parameters your Bicep files might expect ...
}

# 4c. Values from Specific Parameter File (High Priority)
if ($PSBoundParameters.ContainsKey('BicepParameterFile') -and $BicepParameterFile) {
    Write-Host "Loading specific parameters from '$BicepParameterFile'..."
    if (Test-Path $BicepParameterFile) {
        try {
            # Reads the .bicepparam file, removes the 'using' line and parses it as JSON
            $paramContent = Get-Content $BicepParameterFile -Raw
            $paramJsonContent = $paramContent -replace '^\s*using\s+.*\s*' # Removes the 'using' line (basic support)
            $specificParamsObject = $paramJsonContent | ConvertFrom-Json -ErrorAction Stop

            if ($specificParamsObject -and $specificParamsObject.PSObject.Properties.Name -contains 'parameters') {
                # Iterate over parameters defined in the file and add/overwrite in the hashtable
                foreach ($key in $specificParamsObject.parameters.PSObject.Properties.Name) {
                    $value = $specificParamsObject.parameters.$key.value
                    Write-Host "  Applying specific parameter: $key"
                    $azCliParameters[$key] = $value # Overwrites common or dynamic values if the key is the same
                }
                 Write-Host "Specific parameters applied." -ForegroundColor Green
            } else {
                Write-Warning "File '$BicepParameterFile' does not appear to contain a valid 'parameters' section."
            }
        } catch {
            Write-Error "Error reading or parsing parameter file '$BicepParameterFile': $_"
            # Decide whether to exit or continue without specific parameters
            # exit 1
            Write-Warning "Proceeding without specific parameters due to the above error."
        }
    } else {
        # This should not happen thanks to ValidateScript in the param block, but just in case...
        Write-Warning "Specific parameter file '$BicepParameterFile' not found (this is unexpected)."
    }
} else {
    Write-Host "No specific parameter file provided."
}

# --- 5. Prepare and Execute Azure CLI Command ---
Write-Host "Preparing 'az deployment group create' command..."

# Convert the hashtable of parameters to a JSON string accepted by Azure CLI
# Use -Depth 5 to handle nested objects/arrays (e.g. tags)
$parametersJsonString = $azCliParameters | ConvertTo-Json -Depth 5 -Compress

# Use splatting to pass arguments to 'az' cleanly
$azDeploymentArgs = @{
    ResourceGroupName = $ResourceGroupName
    TemplateFile      = $BicepTemplateFile
    Parameters        = $parametersJsonString
    ErrorAction       = 'Stop' # Stops the PowerShell script if 'az' returns an error
}

if ($WhatIf) {
    $azDeploymentArgs.Confirm = $true # Adds --confirm for What-If mode
    Write-Host "Running in What-If mode..." -ForegroundColor Yellow
}

Write-Host "AZ CLI command to be executed (compressed JSON parameters):"
Write-Host "az deployment group create --resource-group $($azDeploymentArgs.ResourceGroupName) --template-file $($azDeploymentArgs.TemplateFile) --parameters $($azDeploymentArgs.Parameters) $(if($WhatIf){'--confirm'})" -ForegroundColor Gray

try {
    # Execute the deployment
    az deployment group create @azDeploymentArgs

    if ($LASTEXITCODE -eq 0) {
         Write-Host "Deployment completed successfully for '$BicepTemplateFile'." -ForegroundColor Green

         # --- NEW: Save outputs to bicep/outputs/<template>.outputs.json ---
         # Determine output folder and file name
         $outputsFolder = Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "outputs"
         if (-not (Test-Path $outputsFolder)) {
             New-Item -ItemType Directory -Path $outputsFolder | Out-Null
         }
         $templateBaseName = [System.IO.Path]::GetFileNameWithoutExtension($BicepTemplateFile)
         $outputsFile = Join-Path $outputsFolder "$templateBaseName.outputs.json"

         # Get outputs from the deployment
         $deploymentName = az deployment group list --resource-group $ResourceGroupName --query "[?properties.templateHash!=null]|[0].name" -o tsv
         if (-not $deploymentName) {
             # Fallback: get the latest deployment by timestamp
             $deploymentName = az deployment group list --resource-group $ResourceGroupName --query "sort_by([].{name:name, ts:properties.timestamp}, &ts)[-1].name" -o tsv
         }
         if ($deploymentName) {
             $outputsJson = az deployment group show -g $ResourceGroupName -n $deploymentName --query properties.outputs -o json
             if ($outputsJson) {
                 Set-Content -Path $outputsFile -Value $outputsJson -Encoding UTF8
                 Write-Host "Deployment outputs saved to: $outputsFile" -ForegroundColor Green
             } else {
                 Write-Warning "No outputs found for deployment '$deploymentName'."
             }
         } else {
             Write-Warning "Could not determine deployment name to fetch outputs."
         }
         # --- END NEW ---

    } else {
         # ErrorAction=Stop should have already stopped the script, but just in case
         Write-Error "Deployment appears to have failed (Exit Code: $LASTEXITCODE)."
    }
} catch {
    # Catch errors thrown by PowerShell (e.g. 'az' command not found) or by ErrorAction Stop
    Write-Error "Error executing 'az deployment group create': $_"
    exit 1
}

Write-Host "Deploy-Bicep.ps1 script finished." -ForegroundColor Cyan
