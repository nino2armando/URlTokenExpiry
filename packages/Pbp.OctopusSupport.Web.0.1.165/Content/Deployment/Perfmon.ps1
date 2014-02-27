function GetMostRecentCollectionSessionNumber(
    [string]$collectionsFolder
)
{
    $folderIdAsInt = 0
    
    $mostRecentFolder = Get-ChildItem $collectionsFolder |
    Where { $_.PSIsContainer } |
    Sort CreationTime -Descending |
    Select -First 1
    
    if ($mostRecentFolder){
        $mostRecentFolderId = $mostRecentFolder.Name.Split("-")[2]
        $folderIdAsInt = [int]$mostRecentFolderId
    }

    return $folderIdAsInt 
}

function TransformDataCollectorSetTemplate(
    [string]$dataCollectorSetName,
    [string]$dataCollectorSetTemplate,
    [string]$dataCollectorPath
)
{
    $xml = get-content $dataCollectorSetTemplate  
    
    $mostRecentCollectionSession = GetMostRecentCollectionSessionNumber $dataCollectorPath
    $nextCollectionSession = $mostRecentCollectionSession + 1
    
    $xml = $xml -replace "{CollectionLocation}", "$dataCollectorPath"
    $xml = $xml -replace "{Date}", (Get-Date -format yyyyMMdd)
    $xml = $xml -replace "{MachineName}", "$env:COMPUTERNAME"
    $xml = $xml -replace "{SerialNumber}", $nextCollectionSession.ToString()
    $xml = $xml -replace "{LastCollectionSession}", $mostRecentCollectionSession.ToString().PadLeft(6,"0")
    $xml = $xml -replace "{NextCollectionSession}", $nextCollectionSession.ToString().PadLeft(6,"0")
    
    return $xml
}

function LoadDataCollectorSet(
    [string]$dataCollectorSetName,
    [string]$dataCollectorSetTemplate,
    [string]$dataCollectorPath
)
{
    if (!(test-path $dataCollectorPath))
    {
        Write-Host "Creating folder for data collection"
        New-Item -ItemType directory -Path $dataCollectorPath
    }    
    
    $transformedXml = TransformDataCollectorSetTemplate $dataCollectorSetName $dataCollectorSetTemplate $dataCollectorPath
    
    $createOrUpdate = 0x0003
    $running = 1
    $stopped = 0
    $dataCollectorSet = New-Object -COM Pla.DataCollectorSet    
    
    try
    {
        $dataCollectorSet.Query($dataCollectorSetName,$null)
    }
    catch
    {
        Write-Host "Set not found, will be created on commit"
    }
    
    if ($dataCollectorSet.Status -eq $running){
        Write-Host "Stopping existing data collector"
        $dataCollectorSet.Stop($false)
    }    
    
    $dataCollectorSet.SetXml($transformedXml)
    $dataCollectorSet.Commit($dataCollectorSetName, $null, $createOrUpdate) | Out-Null  
    $dataCollectorSet.Query($dataCollectorSetName,$null)  
    $dataCollectorSet.Start($false)
    
    do 
        {sleep -m 500; $returnCode = $dataCollectorSet.Status ; $retries++} 
    while ($returnCode -ne $running -and $retries -lt 30)    
    
    if ($retries -eq 30){
        throw "Could not start data collector within the allotted time"
    }
    
    Write-Host "The collector was started successfully"
}