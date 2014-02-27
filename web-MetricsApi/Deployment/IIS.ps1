$appCmd = "c:\windows\system32\inetsrv\appcmd"
$logRootPath= "D:\PayByPhone\Logs"
$executionAccountGroup = "PayByPhone_AppPoolIdentities"

$global:WhatIf = $false

if ( $scriptsFolder -eq $null ) {
    $scriptsFolder = "."
}

$scriptsFolder = Split-Path -Parent $MyInvocation.MyCommand.Definition
. "$scriptsFolder\Permissions.ps1"

function Set-WhatIf([bool]$whatif)
{
    if ( $whatif ) {
        Write-Host "Entering whatif mode"
    } elseif ( $global:WhatIf ) {
        Write-Host "Leaving whatif mode"
    }

    $global:WhatIf = $whatif
}

function Get-Caller
{ 
    (Get-Variable MyInvocation -Scope 2).Value.MyCommand.Name;
}

function Write-Message(
    [string]$message = '',
    [string]$separator = ":",
    [string]$source)
{   
    if ( $source -eq $null ) {
        $source = Get-Caller
    }

    $fullMessage = "$source $separator $message"
    Write-Host $fullMessage
}

function ExecuteCommand([string]$command)
{
    Write-Message $command -source $(Get-Caller) -separator ">"

    if ( !$global:WhatIf ) {
        Invoke-Expression $command | Write-Output
        if ( $LastExitCode -gt 0 ) { throw "Command failed with exit code $LastExitCode : " + $command }
    }

    Return $null
}

function IisLogPathForProject([string]$projectName)
{
    "$logRootPath\$($projectName)_IisLogs"
}

function SplitVirtualPath([string]$absoluteVirtualPath) 
{
    $siteName, $relativePathParts = $absoluteVirtualPath.Split("/") + ""
    $relativeVirtualPath = "/" + [string]::Join("/", $relativePathParts).TrimEnd("/")
    @($siteName, $relativeVirtualPath)
}

function CreateFilesystemDirectory(
    [Parameter(Mandatory=$true)][string]$path
)
{
    Write-Message "Creating directory $path"

    if( Test-Path $path ) {
        Write-Message 'Directory already exists. Keeping existing one.'
    } else {
        New-Item $path -type Directory | Out-Null
        Write-Message 'Directory created.'
    }
}

function QueryAppCmd([string]$parameters) 
{
    $expression = "$appCmd $parameters /xml"
    Write-Message $expression -source $(Get-Caller) -separator ">"

    $output = Invoke-Expression $expression
#    Write-Host $output

    $result = ([xml]$output).appcmd

    if ( $result -eq "" ) { 
        $result = $null 
    }

    $result
}

function GetAppPool([string]$appPoolName)
{
    QueryAppCmd "list apppool /apppool.name:`"$appPoolName`""
}

function DeleteAppPool([string]$appPoolName)
{
    if ( $(GetAppPool $appPoolName) -ne $null ) {
        ExecuteCommand "$appCmd delete apppool /apppool.name:`"$appPoolName`""
    }    
}

function CreateAppPoolIfNotExists(
    [string]$appPoolName,
    [string]$dotNetVersion = "v4.0",
    [bool]$runAs32Bit = $true
)
{
    Write-Message "Creating app pool $appPoolName"

    if( $(GetAppPool $appPoolName) -ne $null ) {
        Write-Message 'App pool exists - skipping...'
        Return $false
    }
    
    Write-Message 'Pool does not exist - creating...'
    ExecuteCommand "$appCmd add apppool /name:`"$appPoolName`" /managedRuntimeVersion:$dotNetVersion /enable32bitapponwin64:$runAs32Bit"
    Return $true
}

function AssignAppPool(
    [string]$absoluteVirtualPath,
    [string]$appPoolName
)
{
    Write-Message "Assigning pool $appPoolName to `"$absoluteVirtualPath`""
    ExecuteCommand "$appCmd set app /app.name:`"$absoluteVirtualPath`" /applicationPool:`"$appPoolName`""
}

function EnsureTrailingSlash([string]$virtualPath)
{
    if ( $virtualPath.EndsWith("/") ) {
        return $virtualPath
    }
    
    return $virtualPath + "/"
}

function SetAppPhysicalPath(
    [string]$absoluteVirtualPath,
    [string]$physicalPath
)
{
    $absolutePathToUse = EnsureTrailingSlash $absoluteVirtualPath
    Write-Message "Setting physical path for `"$absoluteVirtualPath`" to `"$physicalPath`""
    ExecuteCommand "$appCmd set vdir /vdir.name:`"$absolutePathToUse`" /physicalPath:`"$physicalPath`""
}

function AllRecycleEvents
{
    # http://www.iis.net/configreference/system.applicationhost/applicationpools/add/recycling
    @("Time", "Memory", "PrivateMemory", "ConfigChange", "IsapiUnhealthy", "OnDemand", "Requests", "Schedule")
}

function GetLoggedRecycleEvents([string]$appPoolName)
{
    $xpath = "/configuration/system.applicationHost/applicationPools/add[@name=`"$appPoolName`"]"
    $pool = ApplicationHostConfigElement $xpath
    $commaDelimitedEvents = $pool.recycling.logEventOnRecycle
    $commaDelimitedEvents.Split(",") | ForEach { $_.Trim() }
}

function LogAllRecycleEvents([string]$appPoolName)
{
    # There is some craziness with parameter escaping which prevents this from working with ExecuteCommand.
    
    $commaDelimitedEvents = [string]::Join(",", $(AllRecycleEvents))

    $section = "/section:system.applicationHost/applicationPools" 
    $setting = "/[name='$appPoolName'].recycling.logEventOnRecycle:$commaDelimitedEvents"

    Write-Host "$appCmd set config $section $setting"
    & $appCmd set config $section $setting
}

function ApplicationPoolIdentityFor([string]$appPoolName)
{
    "IIS AppPool\$appPoolName"
}

function GrantAppPoolAccessToClientCertificates([string]$appPoolName)
{
    # http://stackoverflow.com/questions/8376468/
    
    $appPoolIdentity = ApplicationPoolIdentityFor $appPoolName
    GrantReadAccessToPrivateKeysOfClientCertificates $appPoolIdentity
}

function AddAppPoolToLocalGroup(
    [string]$appPoolName,
    [string]$groupName
)
{
    $appPoolIdentity = ApplicationPoolIdentityFor $appPoolName
    AddUserToLocalGroup $appPoolIdentity $groupName
}

function AddAppPoolIdentityToExecutionAccountGroup([string]$appPoolName)
{
    AddAppPoolToLocalGroup $appPoolName $executionAccountGroup
}

function CreateAndAssignAppPool(
    [string]$absoluteVirtualPath,
    [string]$appPoolName
)
{
    CreateAppPoolIfNotExists $appPoolName
    LogAllRecycleEvents $appPoolName
    GrantAppPoolAccessToClientCertificates $appPoolName
    AddAppPoolIdentityToExecutionAccountGroup $appPoolName
    AssignAppPool $absoluteVirtualPath $appPoolName
}

function RecycleAppPoolIfExists([string]$appPoolName)
{
    if ( $(GetAppPool $appPoolName) -ne $null ) {
        ExecuteCommand "$appCmd recycle apppool `"$appPoolName`""    
    }    
}

function RecycleAppPoolForProject([string]$project)
{
    # Naming is inconsistent. All new pools created by Pbp.OctopusSupport.Web have the "_AppPool" suffix, but many old ones do not.
    RecycleAppPoolIfExists "$($project)_AppPool"
    RecycleAppPoolIfExists $project
}

function GetApp([string]$absoluteVirtualPath)
{
    $xml = QueryAppCmd "list app /app.name:`"$absoluteVirtualPath`""

    if ( $xml -ne $null -and $xml.app."app.name" -ne $absoluteVirtualPath ) {
        Return $null
    }

    Return $xml
}

function CreateAppIfNotExists(
    [string]$absoluteVirtualPath,
    [string]$physicalPath
)
{    
    $existingApp = GetApp $absoluteVirtualPath

    if ( $existingApp -ne $null ) {
        Write-Message "$absoluteVirtualPath already exists. Keeping existing app."
        Return $false
    }

    $siteName, $relativeVirtualPath = SplitVirtualPath $absoluteVirtualPath
    ExecuteCommand "$appCmd add app /site.name:`"$siteName`" /path:`"$relativeVirtualPath`" /physicalPath:`"$physicalPath`""
    Return $true
}

function CreateAndConfigureApp(
    [string]$absoluteVirtualPath,
    [string]$physicalPath,
    [string]$appPoolName
)
{
    Write-Message "Creating IIS app with virtual path $absoluteVirtualPath, physical path `"$physicalPath`""

    CreateFilesystemDirectory $physicalPath

    $created = CreateAppIfNotExists $absoluteVirtualPath $physicalPath

    if ( $created ) {
        CreateAndAssignAppPool $absoluteVirtualPath $appPoolName
    }
    
    Write-Message 'Done creating app.'
}

function ApplicationHostConfigPath
{
    $paths = @( `
        "C:\windows\system32\inetsrv\config\applicationHost.config",
        "C:\windows\sysnative\inetsrv\config\applicationHost.config" `
    )

    foreach ( $path in $paths) {
        if ( Test-Path $path ) {
            Return $path
        }
    }
    
    throw "Could not find applicationHost.config"
}

function ApplicationHostConfigElement([string]$xpath)
{
    $config = [xml](Get-Content $(ApplicationHostConfigPath))
    (select-xml -xml $config -xpath $xpath).Node
}

function GetSiteLogPath([string]$siteName)
{
    # yes, there is no better way to do this... not if running as a limited user.
    $xpath = "/configuration/system.applicationHost/sites/site[@name=`"$siteName`"]"
    $site = ApplicationHostConfigElement $xpath
    $site.logFile.directory
}

function SetSiteLogPath(
    [string]$siteName,
    [string]$logPath
)
{
    Write-Message "Setting IIS site logfile directory to $logPath"
    CreateFilesystemDirectory $logPath
    ExecuteCommand "$appCmd set site `"$siteName`" /logFile.directory:`"$logPath`""
}

function GetSite([string]$siteName)
{    
    QueryAppCmd "list site /name:`"$siteName`""
}

function GetVirtualDirectory([string]$absoluteVirtualPath)
{    
    QueryAppCmd "list vdir /app.name:`"$absoluteVirtualPath`""
}

function DeleteSite([string]$siteName)
{
    if ( $(GetSite $siteName) -ne $null ) {
        ExecuteCommand "$appCmd delete site `"$siteName`""
    }    
}

function CreateSiteIfNotExists(
    [string]$siteName,
    [array]$bindings,
    [string]$physicalPath
)
{
    if ( $(GetSite $siteName) -ne $null) {
        Write-Message "Site '$siteName' already exists. Not recreating it..."
        Return $false
    }

    Write-Message 'Creating IIS site with:'
    Write-Message " Name: $siteName"
    Write-Message " Bindings: $bindings"
    Write-Message " Physical Path: $physicalPath"

    $bindingList = [string]::Join(",", $bindings)
    ExecuteCommand "$appCmd add site /name:`"$siteName`" /physicalPath:`"$physicalPath`" /bindings:`"$bindingList`""
    Return $true
}

function CreateAndConfigureSite(
    [string]$siteName,
    [array]$bindings,
    [string]$physicalPath,
    [string]$logPath
)
{
    # Site Physical Path
    Write-Message "Site Physical Path: $physicalPath"
    CreateFilesystemDirectory $physicalPath

    # Site
    Write-Message 'Creating IIS site'
    $created = CreateSiteIfNotExists $siteName $bindings $physicalPath

    if ( !$created ) { 
        return 
    }

    # Site AppPool
    Write-Message 'Creating site application pool'
    $appPoolName = $siteName + '_AppPool'
    $absoluteVirtualPath = $siteName + "/"
    CreateAndAssignAppPool $absoluteVirtualPath $appPoolName

    # Site Logging
    Write-Message 'Configuring IIS site logging'
    SetSiteLogPath $siteName $logPath

    Write-Message 'Done creating site.'
}

function BindingsFor(
    [string]$ip,
    [string]$hosts
) {
    $hostNames = $hosts.Split(",") | ForEach { $_.Trim() }
    if ( $hostNames.Length -eq 0 ) { $hostNames = @("") }
    if ( $ip.Length -eq 0 ) { $ip = "*" }
    $hostNames | ForEach { "http/$ip`:80`:$_" }
}

function ParseVirtualPaths([string]$absoluteVirtualPaths)
{
    $paths = $absoluteVirtualPaths.Split(",", [StringSplitOptions]::RemoveEmptyEntries)
    if ( $paths.Length -eq 0 ) { throw "Please provide at least one path to the absoluteVirtualPaths parameter." }
    @($paths)
}

function New-PbpWebSite(
    [Parameter(Mandatory=$true)][string]$project,
    [Parameter(Mandatory=$true)][string]$physicalPath,
    [string]$ip,
    [string]$hosts,
    [switch]$whatif
)
{
    Set-WhatIf $whatif

    $bindings = @(BindingsFor $ip $hosts)
    $logPath = IisLogPathForProject $project

    CreateAndConfigureSite $project $bindings $physicalPath $logPath
}

function New-PbpWebApp(
    [Parameter(Mandatory=$true)][string]$project,
    [Parameter(Mandatory=$true)][string]$physicalPath,
    [Parameter(Mandatory=$true)][string]$absoluteVirtualPaths,
    [switch]$whatIf
)
{
    Set-Whatif $whatif
    $appPoolName = $project + "_AppPool"
    
    $parsedVirtualPaths = ParseVirtualPaths $absoluteVirtualPaths
    Write-Message "Creating $($parsedVirtualPaths.Length) IIS app(s) pointing at $physicalPath ($parsedVirtualPaths)"
    
    $parsedVirtualPaths | ForEach { CreateAndConfigureApp $_ $physicalPath $appPoolName }
    
    Write-Message "Done creating app(s)."
}
