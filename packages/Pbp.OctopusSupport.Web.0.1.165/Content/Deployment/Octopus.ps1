function CopyInConfigFile([string]$fileName)
{
    $fileInTargetFolder = "$OctopusPackageDirectoryPath\Config\$fileName"
    $fileInParentFolder = "$OctopusPackageDirectoryPath\..\Config\$fileName"

    if ( Test-Path $fileInTargetFolder )
    {
        Write-Host "Copying from $fileInTargetFolder"
        Copy $fileInTargetFolder ".\Config\$fileName"
    }
    elseif ( Test-Path $fileInParentFolder )
    {
        Write-Host "Copying from $fileInParentFolder"    
        Copy $fileInParentFolder ".\Config\$fileName"
    }
    else {
        Write-Host "Could not find existing $fileName on the server."
    }
}

function CopyInProductionOnlyConfigFiles
{
    Write-Host "Copying production-only config files (if present) from $OctopusPackageDirectoryPath\Config to $(pwd)\Config"
     
    CopyInConfigFile "ConnectionStrings.config"
    CopyInConfigFile "MachineKey.config"
     
    Write-Host "Done copying."
}

filter Log([string]$prefix)
{
    Write-Host "$prefix $_"
    $_
}

function DeleteRecursively(
    [string]$path, 
    [string]$filePattern
)
{
    Dir $path -include $filePattern -Recurse | Log "deleting" | Remove-Item -Force
}

function DeleteIfExists([string]$filePath) 
{
    if ( Test-Path $filePath ) { 
        Remove-Item $filePath
    }
}

filter RenameWithOverwrite(
    [string]$originalSubstring,
    [string]$replacementSubstring
)
{
    $newName = [regex]::Replace($_.Name, $originalSubstring, $replacementSubstring, [Text.RegularExpressions.RegexOptions]::IgnoreCase)
    $newPath = $(Join-Path $_.DirectoryName $newName)    
    DeleteIfExists $newPath  

    Write-Host "renaming $($_.FullName) to $newName"
    Rename-Item -Path $_.FullName -NewName $newName
}

function RenameRecursively(
    [string]$path,
    [string]$originalSubstring,
    [string]$replacementSubstring
)
{   
    Dir $path -Filter "*$originalSubstring" -Recurse | RenameWithOverwrite $originalSubstring $replacementSubstring
}

function DeleteOctopusFilesFromTargetFolder
{
    # See http://help.octopusdeploy.com/discussions/problems/4458-transforms-are-not-removed-on-deploy
    Write-Host "Deleting deployment files under $OctopusPackageDirectoryPath"

    DeleteRecursively $OctopusPackageDirectoryPath "Web.*.config"
    DeleteRecursively $OctopusPackageDirectoryPath "ConnectionStrings.*.config"
    DeleteRecursively $OctopusPackageDirectoryPath "*.ps1"
}

function PointAdditionalVirtualPathsAtTargetFolder
{
    $additionalPathsString = "$AdditionalVirtualPaths"
    $additionalPaths = $additionalPathsString.Split(",", [StringSplitOptions]::RemoveEmptyEntries)
    Write-Host "Pointing $($additionalPaths.Length) additional virtual paths at $OctopusPackageDirectoryPath ($additionalPaths)"
    
    $additionalPaths | ForEach { SetAppPhysicalPath $_ $OctopusPackageDirectoryPath }
    
    Write-Host "Done re-pointing additional virtual paths."
}

function IsVersionNumber([string]$str)
{
    $str -match "^[0-9.]+$"
}

function GetAppNameFromPhysicalPath([string]$physicalPath)
{
    $pathParts = $physicalPath.Split("\", [StringSplitOptions]::RemoveEmptyEntries);
    
    if ( $(IsVersionNumber $pathParts[-1]) ) {
        Return $pathParts[-2]
    }
    
    Return $pathParts[-1]
}

function UseAlternateTransformsIfDesired
{
    if ( $UseTransformsFromEnvironment -ne $null ) {
        Write-Host "Using transforms from $UseTransformsFromEnvironment environment instead of $OctopusEnvironmentName"
        RenameRecursively "."  ".$($UseTransformsFromEnvironment).config" ".$($OctopusEnvironmentName).config"
    }
}

function PerformStandardPreDeploySteps
{
    UseAlternateTransformsIfDesired
    CopyInProductionOnlyConfigFiles    
}

function PerformStandardPostDeploySteps
{
    PointAdditionalVirtualPathsAtTargetFolder
    DeleteOctopusFilesFromTargetFolder
}
