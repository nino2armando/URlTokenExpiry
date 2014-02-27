$ErrorActionPreference = "stop"

trap
{
    Write-Error $_
    Exit 1
}

. ".\Deployment\IIS.ps1"
. ".\Deployment\Environment.ps1"
. ".\Deployment\Octopus.ps1"

$project = GetAppNameFromPhysicalPath "$OctopusPackageDirectoryPath"
New-PbpWebApp -project "$project" -physicalPath "$OctopusPackageDirectoryPath" -absoluteVirtualPaths "$OctopusWebSiteName,$AdditionalVirtualPaths"

# If your project is a whole site, uncomment this and change it as needed; comment out the New-PbpWebApp call above.
# Uncomment appropriate line for unprotected or protected ip:
# $ip = getProtectedIpString
# $ip = getUnprotectedIpString
# New-PbpWebsite -project "$project" -physicalPath "OctopusPackageDirectoryPath" -hosts "$WebSiteHosts" -ip "$ip" 

PerformStandardPreDeploySteps

Exit 0
