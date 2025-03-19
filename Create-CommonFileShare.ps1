# Create a structure of common fileshares (fellesområder)
# This fits together with the hierarchy and setup created by Create-HomeShare.ps1
# and Create-ADBaseStructure.ps1

# You need the PS Module for ActiveDirectory installed
# The script must be run on the fileserver, with as a user that is member of
# the $fileShareAdminGroupName group

[CmdletBinding()]
Param(
  [Parameter(Mandatory=$False)]
    [string]$FellesFolderPath="D:\FELLES"
)

Import-Module ActiveDirectory

$fileshareAdminGroupName = "filshare-admin"
$FileShareAdminGroup = (Get-ADGroup $fileshareAdminGroupName)
$commonFolders =  @('studenter', 'ansatte', 'ansatte\it', 'ansatte\hr', 'ansatte\regnskap', 'ansatte\studieadm')

$FullControl = [System.Security.AccessControl.FileSystemRights]"FullControl"
$ReadOnly = [System.Security.AccessControl.FileSystemRights]"Read"
$ReadAndExecute = [System.Security.AccessControl.FileSystemRights]"ReadAndExecute"
$Write = [System.Security.AccessControl.FileSystemRights]"Write"
$Allow = [System.Security.AccessControl.AccessControlType]::Allow
$SubFoldersAndFiles = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit, ObjectInherit"
$ThisFolder = [System.Security.AccessControl.InheritanceFlags]"None"
$NoInheritance = [System.Security.AccessControl.PropagationFlags]"None"
$InheritOnly = [System.Security.AccessControl.PropagationFlags]"InheritOnly"
$systemACE = New-Object System.Security.AccessControl.FileSystemAccessRule("SYSTEM", $FullControl, $SubFoldersAndFiles, $NoInheritance, $Allow)
$creatorOwnerACE = New-Object System.Security.AccessControl.FileSystemAccessRule("CREATOR OWNER", $FullControl, $SubFoldersAndFiles, $InheritOnly, $Allow)
$fileShareAdminGroupACE = New-Object System.Security.AccessControl.FileSystemAccessRule($FileShareAdminGroup.SID, $FullControl, $SubFoldersAndFiles, $NoInheritance, $Allow)
$authenticatedUsersACE = New-Object System.Security.AccessControl.FileSystemAccessRule("Authenticated Users", $ReadOnly,$SubFoldersAndFiles, $NoInheritance, $Allow)


function Create-CommonFolder {
    param (
        [String]$Path,
        [String]$GroupName = $null
    )

    if ( -Not (Test-Path -Path $Path) ) {
        Write-Host -BackgroundColor Black -ForegroundColor Green "Creating $Path"
        $folderObj = New-Item -ItemType Directory -Path $Path -Force
        $acl = Get-Acl $folderObj

        Write-Host -BackgroundColor Black -ForegroundColor Green "Disabling inheritance"
        $acl.SetAccessRuleProtection($true, $false)
        Set-Acl  -Path $Path -AclObject $acl

        Write-Host -BackgroundColor Black -ForegroundColor Green "Setting permissions for $Path"
        if ($GroupName) {
            $Group = (Get-ADGroup $GroupName)
            $readAndExecuteACE = New-Object System.Security.AccessControl.FileSystemAccessRule($Group.SID, $ReadAndExecute, $SubFoldersAndFiles, $NoInheritance, $Allow)
            $writeACE = New-Object System.Security.AccessControl.FileSystemAccessRule($Group.SID, $Write, $SubFoldersAndFiles, $NoInheritance, $Allow)
            $ACEList = @($systemACE, $creatorOwnerACE, $fileShareAdminGroupACE, $readAndExecuteACE, $writeACE)
        } else {
            $ACEList = @($systemACE, $creatorOwnerACE, $fileShareAdminGroupACE, $authenticatedUsersACE)
        }
        
        foreach ( $ace in $ACEList ) {
            $acl.AddAccessRule($ace)
        }     
        Set-Acl -Path $Path -AclObject $acl
    } else {
      Write-Host -BackgroundColor Black -ForegroundColor Red "$Path already exists. Doing nothing"
    }
}

try {
  $driveLetter = Split-Path -Path $FellesFolderPath -Qualifier
  $drive = Get-ChildItem $driveLetter -ErrorAction Stop
} catch [System.Management.Automation.DriveNotFoundException] {
  Write-Host "$driveLetter is not a valid drive"
  break
}

Create-CommonFolder -Path $FellesFolderPath
foreach ($commonFolder in $commonFolders) {
    if ($commonFolder -match "\\") {
        $groupName = ($commonFolder -split "\\")[-1]
    } else {
        $groupName = $commonFolder
    }
    Write-Host "groupName: $groupName"
    Create-CommonFolder -Path "${FellesFolderPath}\${commonFolder}" -GroupName "filshare-$groupName"
}

Write-Host -BackgroundColor Black -ForegroundColor Green "Creating SMB share"
New-SmbShare -Name "FELLES" -Path $FellesFolderPath -FullAccess "Everyone" | Out-Null
