<#
.SYNOPSIS
    Script per creare la struttura iniziale di cartelle e file per il progetto Mirai Cook.

.DESCRIPTION
    Crea la cartella principale 'mirai-cook' e tutte le sottocartelle e i file vuoti
    necessari come base per l'applicazione Streamlit, seguendo la struttura concordata.

.NOTES
    Autore: Gemini (basato sulla conversazione)
    Data:   21 Aprile 2025
    Eseguire questo script dalla cartella genitore dove si desidera creare la cartella 'mirai-cook'.
#>

# Nome della cartella principale del progetto
$projectName = "mirai-cook"

# Percorso completo della cartella del progetto (nella directory corrente)
$projectPath = Join-Path -Path $PWD -ChildPath $projectName

# Messaggio iniziale
Write-Host "--- Creazione struttura per '$projectName' in '$PWD' ---"

# --- Creazione Cartella Principale ---
try {
    if (-not (Test-Path -Path $projectPath)) {
        New-Item -ItemType Directory -Path $projectPath -Force | Out-Null
        Write-Host "[OK] Creata cartella principale: $projectPath"
    } else {
        Write-Host "[INFO] Cartella principale '$projectName' già esistente."
    }

    # --- Creazione Sottocartelle ---
    $pagesPath = Join-Path -Path $projectPath -ChildPath "pages"
    $srcPath = Join-Path -Path $projectPath -ChildPath "src"

    New-Item -ItemType Directory -Path $pagesPath -Force | Out-Null
    Write-Host "[OK] Creata sottocartella: pages"
    New-Item -ItemType Directory -Path $srcPath -Force | Out-Null
    Write-Host "[OK] Creata sottocartella: src"

    # --- Creazione File nella Root ---
    $rootFiles = @(
        "app.py",
        "requirements.txt",
        ".gitignore",
        "LICENSE",
        ".env",
        ".env.example",
        "Dockerfile",
        "README.md"
    )
    foreach ($file in $rootFiles) {
        $filePath = Join-Path -Path $projectPath -ChildPath $file
        New-Item -ItemType File -Path $filePath -Force | Out-Null
        Write-Host "[OK] Creato file root: $file"
    }

    # --- Creazione File in pages/ ---
    $pageFiles = @(
        "1_Ricettario.py",
        "2_Aggiungi_Modifica.py",
        "3_Importa_Ricetta.py",
        "4_Gestione_Dispensa.py",
        "5_Gestione_Ingredienti.py",
        "6_Cerca_Ricette.py",
        "7_Suggerimenti_AI.py"
    )
    foreach ($file in $pageFiles) {
        $filePath = Join-Path -Path $pagesPath -ChildPath $file
        New-Item -ItemType File -Path $filePath -Force | Out-Null
        Write-Host "[OK] Creato file page: $file"
    }

     # --- Creazione File in src/ ---
    $srcFiles = @(
        "__init__.py",
        "models.py",
        "azure_clients.py",
        "persistence.py",
        "ai_services.py",
        "agent.py",
        "utils.py"
    )
    foreach ($file in $srcFiles) {
        $filePath = Join-Path -Path $srcPath -ChildPath $file
        New-Item -ItemType File -Path $filePath -Force | Out-Null
        # Aggiungiamo una riga a __init__.py per renderlo riconoscibile come package
        if ($file -eq "__init__.py") {
            # Set-Content -Path $filePath -Value "# -*- coding: utf-8 -*-"
            # Lasciamolo vuoto come richiesto per ora
        }
        Write-Host "[OK] Creato file src: $file"
    }

    Write-Host "--- Struttura creata con successo! ---"

} catch {
    Write-Error "Si è verificato un errore durante la creazione della struttura: $($_.Exception.Message)"
}

