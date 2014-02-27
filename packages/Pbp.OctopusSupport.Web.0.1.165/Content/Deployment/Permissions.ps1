$global:ActiveClientCertOrganizations = @("Parkeon")

function WindowsPrincipalExists([string]$principal)
{
    $account = New-Object Security.Principal.NTAccount($principal)
    if ( $account -eq $null ) { Return $false }
    
    try
    {
        $sid = $account.Translate([Security.Principal.SecurityIdentifier]).Value
        Return $sid -ne $null        
    }
    catch
    {
        Return $false
    }    
}

function AdsiPathForLocalMachine
{
    # http://msdn.microsoft.com/en-us/library/windows/desktop/aa772237(v=vs.85).aspx
    # http://msdn.microsoft.com/en-us/library/windows/desktop/aa746534(v=vs.85).aspx
    "WinNT://$($env:computername)"
}

function AdsiPathForLocalGroup([string]$groupName)
{
    "$(AdsiPathForLocalMachine)/$groupName,group"
}

function AdsiPathForLocalUser([string]$userName)
{
    "$(AdsiPathForLocalMachine)/$userName,user"
}

function LocalUserNameFromAdsiPath([string]$adsiPath)
{
    $pathWithoutClass = $adsiPath.Split(",")[0]
    $pathWithoutClass.Split("/")[-1]
}

function CreateLocalGroup([string]$groupName)
{  
    $machine = [ADSI]$(AdsiPathForLocalMachine)
    $group = $machine.Create("Group", $groupName)
    $group.SetInfo()
}

function LocalGroupExists([string]$groupName)
{
    [ADSI]::Exists($(AdsiPathForLocalGroup $groupName))
}

function DeleteLocalGroup([string]$groupName)
{
    if( $(LocalGroupExists $groupName) ) {
        $machine = [ADSI]$(AdsiPathForLocalMachine)
        $machine.psbase.Children.Remove($(AdsiPathForLocalGroup $groupName))
    }
}

function UserIsInLocalGroup(
    [string]$userName, 
    [string]$groupName
)
{
    # http://stackoverflow.com/questions/16617307
    
    $group = [ADSI]$(AdsiPathForLocalGroup $groupName)
    $members = @($group.psbase.Invoke("Members")) 
    $groupUserNames = $members | foreach { $_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null) }
    $groupUserNames -contains $userName
}

function AddUserToLocalGroup(
    [string]$userName,
    [string]$groupName
)
{
    if( -not $(LocalGroupExists $groupName) ) {
        Write-Host "Did not add $userAdsiPath to local group $groupName : the group did not exist."
        return $false
    }    
    
    if ( $(UserIsInLocalGroup $userName $groupName) ) {        
        Write-Host "$userName was already in local group $groupName."
        return $false
    }
    
    # tried using ADSI for this, but it works for some pools but not others. so shell out to "net".
    # http://stackoverflow.com/questions/18208890/
    
    $command = "net localgroup `"$groupName`" `"$userName`" /add"
    Write-Host $command
    Invoke-Expression $command
}

function GrantFilesystemPermission(
    [string]$path, 
    [string]$principal, 
    [string]$access
)
{
    if ( -not $(WindowsPrincipalExists $principal) ) {
        throw "Windows principal $principal does not exist."
    }
    
    # escaping weirdness prevented me from using invoke-expression for this
    $command = "cacls `"$path`" /E /G `"$principal`":$access"
    Write-Host $command
    & cacls "$path" /E /G `"$principal`":$access
    if ( $LastExitCode -gt 0 ) { throw "cacls failed: $command" }
}

function FindLocalMachineCertificates([string]$subjectSubstring)
{
    Dir cert:\LocalMachine\My | Where { $_.Subject.Contains($subjectSubstring) }
}

function GetPrivateKeyFilePath(
    [Security.Cryptography.X509Certificates.X509Certificate2]$cert
)
{
    $certFolder = "$($env:ProgramData)\Microsoft\Crypto\"
    $fileName = $cert.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName
  
    $files = Dir -Path $certFolder -Recurse -ErrorAction silentlycontinue
    $files | Where { $_.Name -eq $fileName } | ForEach { $_.FullName }
}

function GrantPermissionForPrivateKey(
    [Security.Cryptography.X509Certificates.X509Certificate2]$cert, 
    [string]$principal, 
    [string]$access
)
{
    $certDescription = "[$($cert.Subject)] ($($cert.Thumbprint))"
    $path = GetPrivateKeyFilePath $cert
    
    if ( $path -eq $null ) {
        Write-Host "Private key does not exist or is inaccessible. Could not grant $principal $access access to private key for certificate $certDescription"
    } else {
        Write-Host "Granting $principal $access access to private key for certificate $certDescription"
        GrantFilesystemPermission $path $principal $access
    }
}

function GrantAccessToPrivateKeysOfClientCertificates([string[]]$clientCertOrganizations, [string]$principal, [string]$access)
{
    # http://stackoverflow.com/questions/8376468/
    
    $clientCertOrganizations | ForEach { FindLocalMachineCertificates $_ } | `
        ForEach { GrantPermissionForPrivateKey $_ $principal $access }
}

function GrantReadAccessToPrivateKeysOfClientCertificates([string]$principal)
{    
    GrantAccessToPrivateKeysOfClientCertificates $global:ActiveClientCertOrganizations $principal "R"
}

function GrantFullAccessToPrivateKeysOfClientCertificates([string]$principal)
{    
    GrantAccessToPrivateKeysOfClientCertificates $global:ActiveClientCertOrganizations $principal "F"
}
