Description: Extraction artefacts forensiques + contexte
Author: Script auto
Version: 2.0
Id: forensic-batch

Keys:
  # --- Contexte machine ---
  -
    Description: Computer Name
    HiveType: SYSTEM
    KeyPath: ControlSet001\Control\ComputerName\ComputerName
    ValueName: ComputerName
    Recursive: false

  -
    Description: Install Date
    HiveType: SOFTWARE
    KeyPath: Microsoft\Windows NT\CurrentVersion
    ValueName: InstallDate
    IncludeBinary: true
    BinaryConvert: FILETIME

  -
    Description: Registered Owner
    HiveType: SOFTWARE
    KeyPath: Microsoft\Windows NT\CurrentVersion
    ValueName: RegisteredOwner

  -
    Description: Domain Name
    HiveType: SYSTEM
    KeyPath: ControlSet001\Services\Tcpip\Parameters
    ValueName: Domain

  -
    Description: Host IP Addresses
    HiveType: SYSTEM
    KeyPath: ControlSet001\Services\Tcpip\Parameters\Interfaces
    Recursive: true
    ValueName: DhcpIPAddress

  # --- Liste utilisateurs ---
  -
    Description: User Accounts
    HiveType: SAM
    KeyPath: SAM\Domains\Account\Users\Names
    Recursive: true

  # --- Artefacts utilisateur ---
  -
    Description: UserAssist Entries
    HiveType: NTUSER
    KeyPath: Software\Microsoft\Windows\CurrentVersion\Explorer\UserAssist
    Recursive: true

  -
    Description: RecentDocs
    HiveType: NTUSER
    KeyPath: Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs
    Recursive: true

  -
    Description: RunMRU
    HiveType: NTUSER
    KeyPath: Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU
    Recursive: true

  -
    Description: TypedURLs
    HiveType: NTUSER
    KeyPath: Software\Microsoft\Internet Explorer\TypedURLs
    Recursive: true

  -
    Description: TypedPaths
    HiveType: NTUSER
    KeyPath: Software\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths
    Recursive: true

  -
    Description: BagMRU (Folder Usage)
    HiveType: NTUSER
    KeyPath: Software\Microsoft\Windows\Shell\BagMRU
    Recursive: true

  -
    Description: ShellBags
    HiveType: USRCLASS
    KeyPath: Local Settings\Software\Microsoft\Windows\Shell\BagMRU
    Recursive: true

  # --- Artefacts système ---
  -
    Description: Amcache Program Inventory
    HiveType: SOFTWARE
    KeyPath: Microsoft\Windows\CurrentVersion\AppCompatCache
    Recursive: true

  -
    Description: ShimCache (AppCompatCache)
    HiveType: SYSTEM
    KeyPath: ControlSet001\Control\Session Manager\AppCompatCache
    Recursive: true
