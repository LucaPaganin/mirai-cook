# ./config.psd1
# Common configuration file for Mirai Cook Bicep deployments

@{
  # --- General Settings ---
  location        = "WestEurope"     # Default Azure region
  projectPrefix   = "miraicook"      # Prefix for resource names (e.g. mirai-kv-prod)
                                     # NOTE: Make sure final names comply with Azure limits

  # --- Identity and Access ---
  # Object ID (NOT Principal ID) of the user or group that will have administrative role
  # (e.g. Key Vault Secrets Officer in Key Vault)
  # Run: az ad user show --id "your.user@domain.com" --query id -o tsv
  # Or:  az ad group show --group "Group Name" --query id -o tsv
  adminObjectIds = @(
    "a230f210-97d3-4889-bf56-67c71530cfbe" # Replace with the REAL ID
    # You can add more IDs if needed, the Bicep must handle them (e.g. loops)
  )

  # --- Tagging ---
  # Common tags to apply to all resources (if the Bicep template accepts them)
  commonTags      = @{
    Project     = "MiraiCook"
    Environment = "Development" # May be overridden by specific params
    ManagedBy   = "Bicep"
  }

  # --- Specific Settings (Examples) ---
  # You can add default values for SKU, etc. here if used in multiple modules
  defaultKeyVaultSku = "standard"
  defaultStorageSku  = "Standard_LRS"

}