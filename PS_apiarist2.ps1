

# =====================================================================
# Script : Run-ReCmdForensic.ps1
# Objectif :
#   - Trouver le dossier ../IN/<date> le plus récent
#   - Créer un dossier ../OUT/<date>
#   - Lancer RECmd.exe avec ForensicBatch.reb sur chaque ruche
#   - Générer un CSV par ruche
#   - Fusionner tous les CSV en un rapport global
# =====================================================================

$BaseIn = Resolve-Path "../IN"
$LatestIn = Get-ChildItem -Path $BaseIn -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if (-not $LatestIn) {
    Write-Error "Aucun dossier trouvé dans $BaseIn"
    exit
}

$DateFolder = $LatestIn.Name
$OutputDir = Join-Path (Resolve-Path "../OUT") $DateFolder
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

Write-Host "Entrée : $LatestIn"
Write-Host "Sortie : $OutputDir"

$ReCmd = Join-Path (Resolve-Path ".") "RECmd.exe"
$BatchFile = Join-Path (Resolve-Path ".") "ForensicBatch.reb"

if (-not (Test-Path $ReCmd)) {
    Write-Error "RECmd.exe introuvable dans le répertoire courant"
    exit
}

if (-not (Test-Path $BatchFile)) {
    Write-Error "Batch ForensicBatch.reb introuvable"
    exit
}

# Liste des ruches intéressantes
$Hives = Get-ChildItem -Path $LatestIn.FullName -Recurse -File -Force -ErrorAction SilentlyContinue |
         Where-Object { $_.Extension -eq "" -or $_.Name -match "NTUSER\.dat|UsrClass\.dat" -or $_.Name -in @("SYSTEM","SOFTWARE","SAM","SECURITY") }

$CsvFiles = @()

foreach ($Hive in $Hives) {
    $HiveName = $Hive.Name
    $OutCsv = Join-Path $OutputDir "$($HiveName)_forensic.csv"

    & $ReCmd --bn $BatchFile -f $Hive.FullName --csv $OutputDir --csvf "$($HiveName)_forensic.csv"

    if (Test-Path $OutCsv) {
        $CsvFiles += $OutCsv
        Write-Host "Analyse de $HiveName terminée -> $OutCsv"
    }
    else {
        Write-Warning "Pas de sortie pour $HiveName"
    }
}

# Consolidation globale
$GlobalCsv = Join-Path $OutputDir "Consolidated_Forensics.csv"

if ($CsvFiles.Count -gt 0) {
    $AllData = foreach ($File in $CsvFiles) {
        Import-Csv $File | ForEach-Object {
            $_ | Add-Member -NotePropertyName "SourceHive" -NotePropertyValue (Split-Path $File -LeafBase) -Force
            $_
        }
    }

    $AllData | Export-Csv -Path $GlobalCsv -NoTypeInformation -Encoding UTF8
    Write-Host "CSV global consolidé généré -> $GlobalCsv"
}
else {
    Write-Warning "Aucun CSV n’a été généré, pas de consolidation possible."
}

Write-Host "==== Extraction terminée ===="
Write-Host "Résultats disponibles dans : $OutputDir"
