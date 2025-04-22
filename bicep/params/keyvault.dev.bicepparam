// File: keyvault.bicepparam
// Assicurati che questo file si trovi nella stessa cartella di keyvault.bicep

// Collega questo file di parametri al template Bicep principale
using '../modules/keyvault.bicep'

// Definizione dei valori per i parametri richiesti da keyvault.bicep
param prefix = 'miraicook'

param location = 'westeurope'

param tenantId = '995ccd76-1e90-49fb-8f13-a806c1a5646b'

param secretsReaderPrincipalId = '77339419-b378-47c6-9fa5-c507220238a3'

param secretsOfficerPrincipalId = 'a230f210-97d3-4889-bf56-67c71530cfbe'

