<#
Avant d’exécuter ce script, installez le module ImportExcel :
    Install-Module -Name ImportExcel -Scope CurrentUser -Force
#>

# Exemple de données par ruche (à adapter selon vos sources)
$Ruches = @{
    "Ruche1" = @(
        [PSCustomObject]@{ Date = "2025-08-01"; Poids = 42.3; Temp = 33.1 }
        [PSCustomObject]@{ Date = "2025-08-02"; Poids = 42.7; Temp = 32.8 }
    )
    "Ruche2" = @(
        [PSCustomObject]@{ Date = "2025-08-01"; Poids = 38.4; Temp = 34.0 }
        [PSCustomObject]@{ Date = "2025-08-02"; Poids = 38.1; Temp = 33.6 }
    )
}

# Fichier de sortie
$ExcelFile = "SuiviRuches.xlsx"

# Suppression éventuelle de l'ancien fichier
if (Test-Path $ExcelFile) {
    Remove-Item $ExcelFile
}

# Consolidation des données
$Consolide = foreach ($ruche in $Ruches.Keys) {
    foreach ($row in $Ruches[$ruche]) {
        [PSCustomObject]@{
            Ruche = $ruche
            Date  = $row.Date
            Poids = $row.Poids
            Temp  = $row.Temp
        }
    }
}

# Création des onglets par ruche
foreach ($ruche in $Ruches.Keys) {
    $Ruches[$ruche] | Export-Excel -Path $ExcelFile -WorksheetName $ruche -AutoSize -Append
}

# Création de l’onglet consolidé
$Consolide | Export-Excel -Path $ExcelFile -WorksheetName "Consolidé" -AutoSize -Append
