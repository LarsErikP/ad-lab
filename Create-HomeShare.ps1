# Create a share for home directories, with correct permissions.
# Correct is defined by this article: https://learn.microsoft.com/en-us/archive/blogs/migreene/ntfs-permissions-for-redirected-folders-or-home-directories
# You need the PS Module for ActiveDirectory installed

[CmdletBinding()]
Param(
  [Parameter(Mandatory=$False)]
    [string]$HomeFolderPath="D:\HOME"
)

Import-Module ActiveDirectory

try {
  $driveLetter = Split-Path -Path $HomeFolderPath -Qualifier
  $drive = Get-ChildItem $driveLetter -ErrorAction Stop
} catch [System.Management.Automation.DriveNotFoundException] {
  Write-Host "$driveLetter is not a valid drive"
  break
}

if  ( -Not (Test-Path -Path $HomeFolderPath) ) {
  Write-Host -BackgroundColor Black -ForegroundColor Green "Creating $HomeFolderPath"
  $homeObj = New-Item -ItemType Directory -Path $HomeFolderPath -Force
  $acl = Get-Acl $homeObj

  Write-Host -BackgroundColor Black -ForegroundColor Green "Disabling inheritance"
  $acl.SetAccessRuleProtection($true, $false)
  Set-Acl  -Path $HomeFolderPath -AclObject $acl

  Write-Host -BackgroundColor Black -ForegroundColor Green "Setting permissions"
  $DomainAdmins = (Get-ADGroup "Domain Admins")

  $FullControl = [System.Security.AccessControl.FileSystemRights]"FullControl"

  $Allow = [System.Security.AccessControl.AccessControlType]::Allow

  $SubFoldersAndFiles = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit, ObjectInherit"
  $ThisFolder = [System.Security.AccessControl.InheritanceFlags]"None"

  $NoInheritance = [System.Security.AccessControl.PropagationFlags]"None"
  $InheritOnly = [System.Security.AccessControl.PropagationFlags]"InheritOnly"

  $systemACE = New-Object System.Security.AccessControl.FileSystemAccessRule("SYSTEM", $FullControl, $SubFoldersAndFiles, $NoInheritance, $Allow)
  $creatorOwnerACE = New-Object System.Security.AccessControl.FileSystemAccessRule("CREATOR OWNER", $FullControl, $SubFoldersAndFiles, $InheritOnly, $Allow)
  $domainAdminsACE = New-Object System.Security.AccessControl.FileSystemAccessRule($DomainAdmins.SID, $FullControl, $SubFoldersAndFiles, $NoInheritance, $Allow)
  $everyoneACE_1 = New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone", "CreateDirectories, AppendData", $ThisFolder, $NoInheritance, $Allow)
  $everyoneACE_2 = New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone", "ListDirectory, ReadData", $ThisFolder, $NoInheritance, $Allow)
  $everyoneACE_3 = New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone", "ReadAttributes", $ThisFolder, $NoInheritance, $Allow)
  $everyoneACE_4 = New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone", "Traverse, ExecuteFile", $ThisFolder, $NoInheritance, $Allow)
  
  $ACEList = @($systemACE, $creatorOwnerACE, $domainAdminsACE, $everyoneACE_1, $everyoneACE_2, $everyoneACE_3, $everyoneACE_4)

  foreach ( $ace in $ACEList ) {
    $acl.AddAccessRule($ace)
  }

  Set-Acl -Path $HomeFolderPath -AclObject $acl

  Write-Host -BackgroundColor Black -ForegroundColor Green "Creating SMB share"
  New-SmbShare -Name "HOME" -Path $HomeFolderPath -FullAccess "Everyone" | Out-Null
} else {
  Write-Host -BackgroundColor Black -ForegroundColor Red "$HomeFolderPath already exists. Doing nothing"
}
