Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- Configuration des chemins ---
$ScriptDir = $PSScriptRoot
$DefaultIn = Join-Path $ScriptDir "IN"
$DefaultOut = Join-Path $ScriptDir "OUT"
$BatchPath = Join-Path $ScriptDir "ForensicBatch.reb"

# --- 1. Génération automatique du fichier .reb s'il est absent ---
if (-not (Test-Path $BatchPath)) {
    $RebContent = @"
Description: Extraction artefacts forensiques + contexte
Author: Script auto
Version: 2.0
Id: forensic-batch

Keys:
  -
    Description: Computer Name
    Category: Forensic
    HiveType: SYSTEM
    KeyPath: ControlSet001\Control\ComputerName\ComputerName
    ValueName: ComputerName
    Recursive: false
  -
    Description: Install Date
    Category: Forensic
    HiveType: SOFTWARE
    KeyPath: Microsoft\Windows NT\CurrentVersion
    ValueName: InstallDate
    IncludeBinary: true
    BinaryConvert: FILETIME [cite: 1]
  -
    Description: Registered Owner
    Category: Forensic
    HiveType: SOFTWARE
    KeyPath: Microsoft\Windows NT\CurrentVersion
    ValueName: RegisteredOwner [cite: 2]
  -
    Description: Domain Name
    Category: Forensic
    HiveType: SYSTEM
    KeyPath: ControlSet001\Services\Tcpip\Parameters
    ValueName: Domain
  -
    Description: Host IP Addresses
    Category: Forensic
    HiveType: SYSTEM
    KeyPath: ControlSet001\Services\Tcpip\Parameters\Interfaces
    Recursive: true
    ValueName: DhcpIPAddress
  -
    Description: User Accounts
    Category: Forensic
    HiveType: SAM
    KeyPath: SAM\Domains\Account\Users\Names
    Recursive: true [cite: 3]
  -
    Description: UserAssist Entries
    Category: Forensic
    HiveType: NTUSER
    KeyPath: Software\Microsoft\Windows\CurrentVersion\Explorer\UserAssist
    Recursive: true
  -
    Description: RecentDocs
    Category: Forensic
    HiveType: NTUSER
    KeyPath: Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs
    Recursive: true
  -
    Description: RunMRU
    Category: Forensic
    HiveType: NTUSER
    KeyPath: Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU
    Recursive: true [cite: 4]
  -
    Description: TypedURLs
    Category: Forensic
    HiveType: NTUSER
    KeyPath: Software\Microsoft\Internet Explorer\TypedURLs
    Recursive: true
  -
    Description: TypedPaths
    Category: Forensic
    HiveType: NTUSER
    KeyPath: Software\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths
    Recursive: true
  -
    Description: BagMRU (Folder Usage)
    Category: Forensic
    HiveType: NTUSER
    KeyPath: Software\Microsoft\Windows\Shell\BagMRU
    Recursive: true
  -
    Description: ShellBags
    Category: Forensic
    HiveType: USRCLASS
    KeyPath: Local Settings\Software\Microsoft\Windows\Shell\BagMRU
    Recursive: true [cite: 5]
  -
    Description: Amcache Program Inventory
    Category: Forensic
    HiveType: SOFTWARE
    KeyPath: Microsoft\Windows\CurrentVersion\AppCompatCache
    Recursive: true
  -
    Description: ShimCache (AppCompatCache)
    Category: Forensic
    HiveType: SYSTEM
    KeyPath: ControlSet001\Control\Session Manager\AppCompatCache
    Recursive: true
"@
    Set-Content -Path $BatchPath -Value $RebContent -Encoding UTF8
}

# --- 2. Sélection de RECmd.exe avec message ---
[System.Windows.Forms.MessageBox]::Show("Veuillez sélectionner l'emplacement du fichier 'RECmd.exe' pour démarrer l'analyse.", "Configuration", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)

$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$OpenFileDialog.Title = "Localisez RECmd.exe"
$OpenFileDialog.Filter = "RECmd.exe|RECmd.exe"
$OpenFileDialog.InitialDirectory = $ScriptDir

if ($OpenFileDialog.ShowDialog() -eq "OK") {
    $Global:ReCmdPath = $OpenFileDialog.FileName
} else { exit }

# --- 3. Interface Utilisateur ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "Apiculteur 3.4 - Autonome"
$Form.Size = New-Object System.Drawing.Size(600,520)
$Form.StartPosition = "CenterScreen"

# (Le reste du code UI identique à la version 3.3...)
$LabelIn = New-Object System.Windows.Forms.Label
$LabelIn.Text = "Dossier source (IN) :"
$LabelIn.Location = New-Object System.Drawing.Point(20,20)
$LabelIn.AutoSize = $true
$Form.Controls.Add($LabelIn)

$TextBoxIn = New-Object System.Windows.Forms.TextBox
$TextBoxIn.Location = New-Object System.Drawing.Point(20,40)
$TextBoxIn.Size = New-Object System.Drawing.Size(440,20)
if (Test-Path $DefaultIn) {
    $Latest = Get-ChildItem -Path $DefaultIn -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($Latest) { $TextBoxIn.Text = $Latest.FullName }
}
$Form.Controls.Add($TextBoxIn)

$BtnBrowse = New-Object System.Windows.Forms.Button
$BtnBrowse.Text = "Parcourir"
$BtnBrowse.Location = New-Object System.Drawing.Point(470,38)
$BtnBrowse.Add_Click({
    $FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($FolderBrowser.ShowDialog() -eq "OK") { $TextBoxIn.Text = $FolderBrowser.SelectedPath }
})
$Form.Controls.Add($BtnBrowse)

$LogBox = New-Object System.Windows.Forms.TextBox
$LogBox.Multiline = $true
$LogBox.Location = New-Object System.Drawing.Point(20,80)
$LogBox.Size = New-Object System.Drawing.Size(540,240)
$LogBox.ScrollBars = "Vertical"
$LogBox.ReadOnly = $true
$LogBox.BackColor = "Black"
$LogBox.ForeColor = "Lime"
$Form.Controls.Add($LogBox)

$BtnRun = New-Object System.Windows.Forms.Button
$BtnRun.Text = "LANCER L'ANALYSE"
$BtnRun.Location = New-Object System.Drawing.Point(20,340)
$BtnRun.Size = New-Object System.Drawing.Size(540,45)
$BtnRun.BackColor = "SteelBlue"
$BtnRun.ForeColor = "White"
$BtnRun.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)

$BtnOpenDir = New-Object System.Windows.Forms.Button
$BtnOpenDir.Text = "Ouvrir le dossier des résultats"
$BtnOpenDir.Location = New-Object System.Drawing.Point(20,400)
$BtnOpenDir.Size = New-Object System.Drawing.Size(540,35)
$BtnOpenDir.Enabled = $false
$Form.Controls.Add($BtnOpenDir)

$BtnRun.Add_Click({
    $Source = $TextBoxIn.Text
    if (-not (Test-Path $Source)) { return }
    $FolderName = Split-Path $Source -Leaf
    $Global:CurrentDest = Join-Path $DefaultOut $FolderName
    if (-not (Test-Path $Global:CurrentDest)) { New-Item -ItemType Directory -Path $Global:CurrentDest -Force | Out-Null }
    
    $LogBox.AppendText("`r`n[+] RECmd en cours sur : $FolderName")
    $Form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
    
    $ProcessArgs = "-d `"$Source`" --bn `"$BatchPath`" --csv `"$Global:CurrentDest`" --recover"
    
    try {
        $Proc = Start-Process -FilePath $Global:ReCmdPath -ArgumentList $ProcessArgs -Wait -NoNewWindow -PassThru
        $LogBox.AppendText("`r`n[OK] Terminé. Fichiers extraits dans OUT.")
        $BtnOpenDir.Enabled = $true
    }
    catch { $LogBox.AppendText("`r`n[!] Erreur : $($_.Exception.Message)") }
    finally { $Form.Cursor = [System.Windows.Forms.Cursors]::Default }
})

$BtnOpenDir.Add_Click({ if (Test-Path $Global:CurrentDest) { Invoke-Item $Global:CurrentDest } })

$Form.Controls.Add($BtnRun)
$Form.ShowDialog() | Out-Null