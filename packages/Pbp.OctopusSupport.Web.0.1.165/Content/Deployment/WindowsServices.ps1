
function GetService([string]$serviceName){
    return Get-WmiObject -Class Win32_Service -Filter "Name='${serviceName}'"   
}

function SetServicePath([string]$path, [string]$serviceName){
    $serviceControl = "sc.exe"
    Invoke-Expression "${serviceControl} config ${serviceName} binPath= '${path}'"
}

function SetServiceStartupType([string]$serviceName, [string]$startupType){
    # allowed values: [auto, boot, demand, disabled, system]
    $serviceControl = "sc.exe"
    Invoke-Expression "${serviceControl} config ${serviceName} start= ${startupType}"
}

function InstallOrUpdateService([string]$serviceName, [string]$path, [bool]$isTopshelf)
{
    $service = GetService ${serviceName}

    if ($service){
        Write-Host "Service already exists, updating path to binary"
        SetServicePath $path $serviceName
    } else {
        Write-Host "Service not found, installing"
        if ($isTopshelf){
            Write-Host "Using TopShelf install"
            &"${path}" install
        } else {
            Write-Host "Using standard windows install"
            New-Service -Name $serviceName -BinaryPathName $path
        }
    }
}

function SetStartupTypeAndStartServiceIfNecessary([string]$serviceName, [bool]$startServiceAfterInstall){
    $service = GetService ${serviceName}
    
    if ($service){
    	if ($startServiceAfterInstall -eq $true) {
    		Write-Host "Setting startup type to auto"
            SetServiceStartupType $serviceName "auto"
            "Starting service..."
    		& start-service $serviceName
    	}

    	if ($startServiceAfterInstall -eq $false) {
    		"Setting startup type to manual (demand). Not starting service."
    		SetServiceStartupType $serviceName "demand"
    	}        
    } else {
    	Write-Host "Service not found, installation/update failed"
    	Exit 1
    }
}

function StopServiceIfItExists([string]$serviceName){
    $service = GetService ${serviceName}
    
    if ($service){
    	Write-Host "Existing service found. Attempting to stop service."
    	$serviceShutDownDelay = 16
    	if ($service.state.ToString().Equals("Running")) {
    		& stop-service $serviceName
    		Write-Host "Waiting for $serviceShutDownDelay seconds for Service shutdown to complete prior to deployment ..."
    		Start-Sleep -s $serviceShutDownDelay
    	} else {
    		Write-Host "Service is not running, skipping stop process"
    	}
    } else {
    	Write-Host "Service not found, will install in PostDeploy"
    }
}