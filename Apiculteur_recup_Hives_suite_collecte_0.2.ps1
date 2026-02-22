# =====================================================================
# Script : Collect-RegistryHives.ps1 (Version Corrigée)
# Objectif : 
#   - Recherche toutes les ruches de registre
#   - Copie chaque ruche avec ses journaux de transaction
#   - Destination : ./IN/<date>/ (Dossier local au script)
# =====================================================================

# Demander le chemin source
$SourcePath = Read-Host "Entrez le chemin de l'arborescence à analyser"

# Vérifier si le chemin existe
if (-Not (Test-Path $SourcePath)) {
    Write-Error "Le chemin '$SourcePath' n'existe pas."
    exit
}

# --- CORRECTION DU CHEMIN DE DESTINATION ---
# On définit le dossier IN dans le répertoire actuel du script
$BaseInPath = Join-Path -Path $PSScriptRoot -ChildPath "IN"

# Créer le dossier 'IN' s'il n'existe pas
if (-not (Test-Path $BaseInPath)) {
    New-Item -ItemType Directory -Path $BaseInPath -Force | Out-Null
}

# Créer le sous-dossier de sortie avec la date
$Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$OutputPath = Join-Path -Path $BaseInPath -ChildPath $Timestamp
New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
# --------------------------------------------

Write-Host "Les ruches seront copiées vers : $OutputPath"

# Extensions typiques des ruches + fichiers de log associés
$HivePatterns = @("SAM", "SECURITY", "SOFTWARE", "SYSTEM", "NTUSER.DAT", "UsrClass.dat")
$LogPatterns = @("*.log", "*.log1", "*.log2", "*.jrs", "*.blf", "*.regtrans-ms")

# Récupérer toutes les ruches trouvées
$Hives = Get-ChildItem -Path $SourcePath -Recurse -Force -File -ErrorAction SilentlyContinue |
         Where-Object { $HivePatterns -contains $_.Name }

foreach ($Hive in $Hives) {
    $HiveDir = Split-Path $Hive.FullName -Parent

    # Créer une structure de dossiers relative dans la destination
    # On utilise -Replace pour extraire la structure après le chemin source
    $EscapedSource = [RegEx]::Escape($SourcePath).Replace("\\", "\\")
    $SubPath = $HiveDir -replace "^$EscapedSource", ""
    $TargetDir = Join-Path $OutputPath $SubPath
    
    if (-not (Test-Path $TargetDir)) {
        New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
    }

    # Copier la ruche
    Copy-Item -Path $Hive.FullName -Destination $TargetDir -Force
    Write-Host "Copié : $($Hive.FullName)"

    # Copier les fichiers journaux associés
    foreach ($Pattern in $LogPatterns) {
        Get-ChildItem -Path $HiveDir -Filter $Pattern -Force -ErrorAction SilentlyContinue |
            Copy-Item -Destination $TargetDir -Force
    }
}

Write-Host "`n==== Fin de la collecte ===="
Write-Host "Toutes les ruches sont ici : $OutputPath"