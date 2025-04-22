<#
.SYNOPSIS
    Sets multiple secrets in an Azure Key Vault based on a JSON input file.

.DESCRIPTION
    Reads key-value pairs from a specified JSON file and uses 'az keyvault secret set'
    to create or update each secret in the target Key Vault.

.PARAMETER VaultName
    The name of the Azure Key Vault to update. (Mandatory)

.PARAMETER JsonFilePath
    The path to the JSON file containing the secrets (key-value pairs). (Mandatory)

.EXAMPLE
    .\Set-KeyVaultSecrets.ps1 -VaultName "miraiCook-kv-xxxxxxxxxx" -JsonFilePath .\secrets.json

.NOTES
    Assumes you are logged into Azure CLI (`az login`) with permissions to set secrets
    on the specified Key Vault (e.g., Key Vault Secrets Officer role).
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$VaultName,

    [Parameter(Mandatory=$false)]
    [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
    [string]$JsonFilePath=".\secrets.json"
)

# --- Verifica Login Azure (Controllo base) ---
$azAccount = az account show --output json | ConvertFrom-Json -ErrorAction SilentlyContinue
if (-not $azAccount) {
    Write-Error "Error: You don't seem to be logged into Azure CLI. Run 'az login' and select the correct subscription."
    exit 1 # Exit script
}
Write-Host "Verified Azure login for subscription: $($azAccount.name) ($($azAccount.id))"

# --- Verifica Esistenza Key Vault (Controllo base) ---
Write-Host "Verifying Key Vault '$VaultName' existence..."
try {
    $kv = az keyvault show --name $VaultName --output json | ConvertFrom-Json -ErrorAction Stop
    Write-Host "[OK] Key Vault '$($kv.name)' found in resource group '$($kv.resourceGroup)'."
} catch {
    Write-Error "Error: Key Vault '$VaultName' not found or access denied. Ensure the name is correct and you have permissions."
    exit 1
}

# --- Lettura e Parsing del File JSON ---
Write-Host "Reading secrets from '$JsonFilePath'..."
try {
    $jsonContent = Get-Content -Path $JsonFilePath -Raw | ConvertFrom-Json -ErrorAction Stop
} catch {
    Write-Error "Error reading or parsing JSON file '$JsonFilePath': $($_.Exception.Message)"
    exit 1
}

# --- Iterazione e Impostazione Segreti ---
Write-Host "Setting secrets in Key Vault '$VaultName'..."
$secrets = $jsonContent.PSObject.Properties | Select-Object -Property Name, Value
$successCount = 0
$errorCount = 0

foreach ($secret in $secrets) {
    $secretName = $secret.Name
    $secretValue = $secret.Value

    if (-not $secretValue) {
        Write-Warning "Skipping secret '$secretName' because its value is empty in the JSON file."
        continue
    }

    Write-Host "  Setting secret: '$secretName'..."
    try {
        # Esegue il comando az keyvault secret set
        az keyvault secret set --vault-name $VaultName --name $secretName --value $secretValue --output none --only-show-errors
        # Controlla l'esito del comando precedente
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "    -> Failed to set secret '$secretName' (Exit Code: $LASTEXITCODE). Check Azure CLI output above for details."
            $errorCount++
        } else {
            Write-Host "    -> Secret '$secretName' set successfully."
            $successCount++
        }
    } catch {
        Write-Warning "    -> PowerShell error while trying to set secret '$secretName': $($_.Exception.Message)"
        $errorCount++
    }
    # Piccola pausa opzionale
    # Start-Sleep -Milliseconds 500
}

# --- Riepilogo Finale ---
Write-Host "--- Secret Setting Process Completed ---"
Write-Host "Successfully set: $successCount secrets."
if ($errorCount -gt 0) {
    Write-Warning "Failed to set: $errorCount secrets. Please review the warnings/errors above."
}

