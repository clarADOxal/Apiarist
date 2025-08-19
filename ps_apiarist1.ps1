# =====================================================================
# Script : Collect-RegistryHives.ps1
# Objectif : 
#   - Demande un chemin source à analyser
#   - Recherche toutes les ruches de registre (y compris NTUSER.dat)
#   - Copie chaque ruche avec ses journaux de transaction (log1/log2, .LOG, etc.)
#   - Garde les fichiers supprimés, slack et transaction logs pour RECmd
#   - Crée un répertoire de sortie avec date au format yyyy-MM-dd_HH-mm-ss
#   - Dépose le tout dans ../../IN/<date>/
# =====================================================================

# Demander le chemin source
$SourcePath = Read-Host "Entrez le chemin de l'arborescence à analyser"

# Vérifier si le chemin existe
if (-Not (Test-Path $SourcePath)) {
    Write-Error "Le chemin '$SourcePath' n'existe pas."
    exit
}

# Créer le dossier de sortie
$Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$OutputPath = Join-Path -Path (Resolve-Path "../../IN").Path -ChildPath $Timestamp
New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null

Write-Host "Les ruches seront copiées vers : $OutputPath"

# Extensions typiques des ruches + fichiers de log associés
$HivePatterns = @(
    "SAM", "SECURITY", "SOFTWARE", "SYSTEM",
    "NTUSER.DAT", "UsrClass.dat"
)

$LogPatterns = @(
    "*.log", "*.log1", "*.log2", "*.jrs", "*.blf", "*.regtrans-ms"
)

# Récupérer toutes les ruches trouvées
$Hives = Get-ChildItem -Path $SourcePath -Recurse -Force -File -ErrorAction SilentlyContinue |
         Where-Object { $HivePatterns -contains $_.Name }

foreach ($Hive in $Hives) {
    $HiveDir = Split-Path $Hive.FullName -Parent

    # Créer une structure de dossiers identique à la source dans la destination
    $RelativePath = Resolve-Path $HiveDir -Relative
    $TargetDir = Join-Path $OutputPath $RelativePath
    New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null

    # Copier la ruche
    Copy-Item -Path $Hive.FullName -Destination $TargetDir -Force
    Write-Host "Copié : $($Hive.FullName)"

    # Copier les fichiers journaux associés (si présents)
    foreach ($Pattern in $LogPatterns) {
        Get-ChildItem -Path $HiveDir -Filter $Pattern -Force -ErrorAction SilentlyContinue |
            Copy-Item -Destination $TargetDir -Force
    }
}

Write-Host "==== Fin de la collecte ===="
Write-Host "Toutes les ruches ont été copiées vers : $OutputPath"
