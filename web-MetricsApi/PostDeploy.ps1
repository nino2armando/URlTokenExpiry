$ErrorActionPreference = "stop"

trap
{
    Write-Error $_
    Exit 1
}

. ".\Deployment\IIS.ps1"
. ".\Deployment\Octopus.ps1"

PerformStandardPostDeploySteps

$project = GetAppNameFromPhysicalPath "$OctopusPackageDirectoryPath"
RecycleAppPoolForProject $project

Exit 0
