Import-Module ActiveDirectory

################################
# Disse kan endres etter behov #
################################
$homeshare = "\\lab-fileserver\HOME"
$defaultPassword = ConvertTo-SecureString -AsPlainText -Force -String "SUPERHEMMELIG"
$adminUsername = "larserik"
$adminGivenName = "Lars Erik"
$adminSurname = "Pedersen"

#########################
# Ikke endre mer herfra #
#########################

$basedn = (Get-ADDomain).DistinguishedName
$domain = (Get-ADDomain).DNSRoot
$adminbrukere = "OU=Adminbrukere,OU=Brukere,$basedn"
$ansattbrukere = "OU=Ansatte,OU=Brukere,$basedn"
$studentbrukere = "OU=Studenter,OU=Brukere,$basedn"

# Funksjoner
function Create-LabUser {
    param ( 
        [String]$UserName,
        [String]$GivenName,
        [String]$Surname,
        [String]$OU,
        [Parameter(ParameterSetName="ansatt")]
        [Switch]$Ansatt,
        [Parameter(ParameterSetName="student")]
        [Switch]$Student
    )
    
    if($Ansatt) {
        $userPath = "OU=$OU,$ansattbrukere"
    }

    if($Student) {
        $userPath = $studentbrukere
    }
     
    $homedirectory = "$homeshare\$UserName"
  
    New-ADUser -Name $UserName -DisplayName "$GivenName $Surname" -GivenName $GivenName -Surname $Surname -Path $userPath -AccountPassword $defaultPassword -PasswordNeverExpires $true -ChangePasswordAtLogon $false -Enabled $true -UserPrincipalName "$UserName@$domain"
    $userObj = Get-ADUser -Identity $UserName
    $homeObj = New-Item -Path $homedirectory -ItemType Directory -force
    $acl = Get-Acl $homeObj
    $FileSystemRights = [System.Security.AccessControl.FileSystemRights]"FullControl"
    $AccessControlType = [System.Security.AccessControl.AccessControlType]::Allow
    $InheritanceFlags = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit, ObjectInherit"
    $PropagationFlags = [System.Security.AccessControl.PropagationFlags]"None"
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($userObj.SID, $FileSystemRights, $InheritanceFlags, $PropagationFlags, $AccessControlType)
    $acl.AddAccessRule($accessRule)
    Set-Acl -Path $homeObj -AclObject $acl

    Set-ADUser -Identity $UserName -HomeDrive "H:" -HomeDirectory "$homedirectory"
}


# OUer
Write-Host -ForegroundColor Green -BackgroundColor Black "Lager OUer..."
New-ADOrganizationalUnit -Name Brukere -Path $basedn -ErrorAction SilentlyContinue
New-ADOrganizationalUnit -Name Grupper -Path $basedn -ErrorAction SilentlyContinue
New-ADOrganizationalUnit -Name Klienter -Path $basedn -ErrorAction SilentlyContinue
New-ADOrganizationalUnit -Name Servere -Path $basedn -ErrorAction SilentlyContinue

New-ADOrganizationalUnit -Name Adminbrukere -Path "OU=Brukere,$basedn" -ErrorAction SilentlyContinue
New-ADOrganizationalUnit -Name Ansatte -Path "OU=Brukere,$basedn" -ErrorAction SilentlyContinue
New-ADOrganizationalUnit -Name Studenter -Path "OU=Brukere,$basedn" -ErrorAction SilentlyContinue

New-ADOrganizationalUnit -Name Ansatte -Path "OU=Klienter,$basedn" -ErrorAction SilentlyContinue
New-ADOrganizationalUnit -Name Studenter -Path "OU=Klienter,$basedn" -ErrorAction SilentlyContinue

New-ADOrganizationalUnit -Name HR -Path $ansattbrukere -ErrorAction SilentlyContinue
New-ADOrganizationalUnit -Name IT -Path $ansattbrukere -ErrorAction SilentlyContinue
New-ADOrganizationalUnit -Name Regnskap -Path $ansattbrukere -ErrorAction SilentlyContinue
New-ADOrganizationalUnit -Name Studieadm -Path $ansattbrukere -ErrorAction SilentlyContinue

New-ADOrganizationalUnit -Name DHCP -Path "OU=Servere,$basedn" -ErrorAction SilentlyContinue
New-ADOrganizationalUnit -Name Fil -Path "OU=Servere,$basedn" -ErrorAction SilentlyContinue
New-ADOrganizationalUnit -Name Print -Path "OU=Servere,$basedn" -ErrorAction SilentlyContinue

# Generelle grupper
Write-Host -ForegroundColor Green -BackgroundColor Black "Lager grupper..."
New-ADGroup -GroupScope DomainLocal -Name ansatte -Path "OU=Grupper,$basedn" -Description "Alle ansatte"
New-ADGroup -GroupScope DomainLocal -Name studenter -Path "OU=Grupper,$basedn" -Description "Alle studenter"
New-ADGroup -GroupScope DomainLocal -Name studieadm -Path "OU=Grupper,$basedn" -Description "Ansatte i studieadministrasjonen"
New-ADGroup -GroupScope DomainLocal -Name hr -Path "OU=Grupper,$basedn" -Description "Ansatte i HR-avdelingen"
New-ADGroup -GroupScope DomainLocal -Name it -Path "OU=Grupper,$basedn" -Description "Ansatte i IT-avdelingen"
New-ADGroup -GroupScope DomainLocal -Name regnskap -Path "OU=Grupper,$basedn" -Description "Ansatte i regnskap"

# Adminrolle-grupper
New-ADGroup -GroupScope DomainLocal -Name klient-admin -Path "OU=Grupper,$basedn" -Description "Alle klientadministratorer"
New-ADGroup -GroupScope DomainLocal -Name server-admin -Path "OU=Grupper,$basedn" -Description "Alle serveradministratorer"

# Filsshare-grupper
New-ADGroup -GroupScope DomainLocal -Name filshare-admin -Path "OU=Grupper,$basedn" -Description "Full control på alle filshare"
New-ADGroup -GroupScope DomainLocal -Name filshare-ansatte -Path "OU=Grupper,$basedn" -Description "Tilgang til filshare for alle ansatte"
New-ADGroup -GroupScope DomainLocal -Name filshare-studenter -Path "OU=Grupper,$basedn" -Description "Tilgang til filshare for alle studenter"
New-ADGroup -GroupScope DomainLocal -Name filshare-felles -Path "OU=Grupper,$basedn" -Description "Tilgang til felles filshare"
New-ADGroup -GroupScope DomainLocal -Name filshare-regnskap -Path "OU=Grupper,$basedn" -Description "Tilgang til filshare for regnskap"
New-ADGroup -GroupScope DomainLocal -Name filshare-hr -Path "OU=Grupper,$basedn" -Description "Tilgang til filsgare for HR"
New-ADGroup -GroupScope DomainLocal -Name filshare-it -Path "OU=Grupper,$basedn" -Description "Tilgang til filshare for IT-avdelingen"
New-ADGroup -GroupScope DomainLocal -Name filshare-studieadm -Path "OU=Grupper,$basedn" -Description "Tilgang til filshare for studieadministrasjonen"

# Gruppenøsting
Write-Host -ForegroundColor Green -BackgroundColor Black "Nøster sammen litt grupper..."
Add-ADGroupMember -Identity ansatte -Members hr,it,studieadm,regnskap
Add-ADGroupMember -Identity filshare-felles -Members ansatte,studenter
Add-ADGroupMember -Identity filshare-ansatte -Members ansatte
Add-ADGroupMember -Identity filshare-studenter -Members studenter
Add-ADGroupMember -Identity filshare-regnskap -Members regnskap
Add-ADGroupMember -Identity filshare-hr -Members hr
Add-ADGroupMember -Identity filshare-it -Members it
Add-ADGroupMember -Identity filshare-studieadm -Members studieadm

# Admin-brukere
Write-Host -ForegroundColor Green -BackgroundColor Black "Lager et par adminbrukere..."
New-ADUser -Name "admin-$adminUsername" -DisplayName "ADMIN $adminGivenName $adminSurname" -GivenName $adminGivenName -Surname $adminSurname -Path $adminbrukere -AccountPassword $defaultPassword -PasswordNeverExpires $true -ChangePasswordAtLogon $false -Enabled $true
New-ADUser -Name "klientadmin-$adminUsername" -DisplayName "KLIADMIN $adminGivenName $adminSurname" -GivenName $adminGivenName -Surname $adminSurname -Path $adminbrukere -AccountPassword $defaultPassword -PasswordNeverExpires $true -ChangePasswordAtLogon $false -Enabled $true

# Vanlige brukere
Write-Host -ForegroundColor Green -BackgroundColor Black "Lager en bunke ansatte og studenter..."
Create-LabUser -Ansatt -UserName hilde -GivenName Hilde -Surname HR -OU HR
Create-LabUser -Ansatt -UserName roger -GivenName Roger -Surname Regnskap -OU Regnskap
Create-LabUser -Ansatt -UserName ingrid -GivenName Ingrid -Surname IT -OU IT
Create-LabUser -Ansatt -UserName kari -GivenName Kari -Surname Gjere -OU Studieadm
Create-LabUser -Student -UserName sondre -GivenName Sondre -Surname Student -OU Studenter
Create-LabUser -Student -UserName selma -GivenName Selma -Surname Student -OU Studenter

# Gruppemedlemsskap
Write-Host -ForegroundColor Green -BackgroundColor Black "Gir brukerene ymse gruppemedlemskap..."
Add-ADGroupMember -Identity server-admin -Members "admin-$adminUsername"
Add-ADGroupMember -Identity filshare-admin -Members "admin-$adminUsername"
Add-ADGroupMember -Identity klient-admin -Members "klientadmin-$adminUserName"
Add-ADGroupMember -Identity studenter -Members sondre,selma
Add-ADGroupMember -Identity hr -Members hilde
Add-ADGroupMember -Identity it -Members ingrid
Add-ADGroupMember -Identity regnskap -Members roger
Add-ADGroupMember -Identity studieadm -Members kari
