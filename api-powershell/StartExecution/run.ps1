# Input bindings are passed in via param block.
param($QueueItem, $TriggerMetadata)

Install-Module Az.Storage -RequiredVersion 6.1.2  -Scope CurrentUser -Force -AllowClobber
Import-Module Az.Storage
Install-Module AzTable -RequiredVersion 2.1.0 -Scope CurrentUser -Force -AllowClobber
Import-Module AzTable

function TableContainerGet([String] $ContainerType) {
    write-host "Getting StoraageASccount contexnt"
    $StorageAccountContext = (Get-AzStorageAccount -Name $env:StorageAccountName -ResourceGroupName $env:StorageAccountRG  -ErrorAction Stop).Context
    #write-host "StorageAccountContext: $StorageAccountContext"
    $cloudTable = (Get-AzStorageTable -Context $StorageAccountContext -Name "Container").CloudTable
    #write-host "cloudTable : $($cloudTable | ConvertTo-Json)"

    $rows = Get-AzTableRow -table $cloudTable -partitionKey $ContainerType  
    Write-Host $rows

    return $rows
}

function TableContainerAdd([String] $ContainerType, [String] $ContainerCount, [String] $ExecutionId) {
    $StorageAccountContext = (Get-AzStorageAccount -Name $env:StorageAccountName -ResourceGroupName $env:StorageAccountRG  -ErrorAction Stop).Context
    $cloudTable = (Get-AzStorageTable -Context $StorageAccountContext -Name "Container").CloudTable

    Write-Host "Adding new row PartitionKey: $ContainerType; RowKey: $ContainerCount"
    Add-AzTableRow `
        -table $cloudTable `
        -partitionKey $ContainerType `
        -rowKey $ContainerCount -property @{"ExecutionId" = "$ExecutionId"; "IsBusy" = $true }  

    write-host "Container table: new row added"
}

function TableContainerUpdate([String] $ContainerType, [String] $ContainerCount, [String] $ExecutionId, [bool] $IsBusy) {    
    $StorageAccountContext = (Get-AzStorageAccount -Name $env:StorageAccountName -ResourceGroupName $env:StorageAccountRG  -ErrorAction Stop).Context
    $cloudTable = (Get-AzStorageTable -Context $StorageAccountContext -Name "Container").CloudTable

    $filter = "(PartitionKey eq '$ContainerType') and (RowKey eq '$ContainerCount')"

    $container = Get-AzTableRow -table $cloudTable -CustomFilter $filter
    Write-Host $container

    # Change the entity.
    $container.ExecutionId = $ExecutionId
    $container.IsBusy = $IsBusy

    # To commit the change, pipe the updated record into the update cmdlet.
    $container | Update-AzTableRow -table $cloudTable
    write-host "Table container updated"
}



# Write out the queue message and insertion time to the information log.
Write-Host "PowerShell queue trigger function processed work item:$($QueueItem.name)"
Write-Host "Queue item insertion time: $($TriggerMetadata.InsertionTime)"

Write-Host "APP ID: $($env:AppId)"

# $clientCredential = New-Object Microsoft.IdentityModel.Clients.ActiveDirectory.ClientCredential($env:AppId, $env:AppSecret)
$azurePassword = ConvertTo-SecureString $env:AppSecret -AsPlainText -Force
$PSCredential = New-Object System.Management.Automation.PSCredential($env:AppId, $azurePassword)

Connect-AzAccount -Credential $PSCredential `
    -Tenant "43548595-c3b2-4c7c-b07b-b97911e6c10c" `
    -SubscriptionId "16195a49-804b-4707-bb52-686a311b9b98"   `
    -ServicePrincipal `
    -ErrorAction Stop 
                    


# Set-AzContext -Subscription "16195a49-804b-4707-bb52-686a311b9b98"
Write-Host "####----######"


write-host "Getting Container list from Container table"
$containerList = TableContainerGet($($QueueItem.type))
write-host $containerList
write-host "Conatiner list count: $($containerList.count )"
write-host "ContainerCount: $env:ContainerCount )"

$pickedContainerCount = $containerList.count

# case if new contaner is not yet added
if (-not $containerList -or ($containerList.count -lt $env:ContainerCount)) {
    write-host "ContainerCount is less than $env:ContainerCount, adding new entry for PK: $($QueueItem.type), rowKey: $($containerList.count)"
    TableContainerAdd -ContainerType $QueueItem.type -ContainerCount $containerList.count -ExecutionId $QueueItem.ExecutionId
    write-host "New row added to Container table"
}
else {
    write-host "Finding available Container from Container List"
    $availableContainer = $containerList | Where-Object { $_.IsBusy -like $false }  | Select-Object -First 1

    if ($availableContainer) {
        $pickedContainerCount = $availableContainer.rowKey
        write-host "Conatiner is availabe. Updating Conatiner entry. PK: $($QueueItem.type) RowKey: $($availableContainer.rowKey) ExecutionId: $($QueueItem.ExecutionId)"
        TableContainerUpdate -ContainerType $QueueItem.type -ContainerCount $availableContainer.rowKey -ExecutionId $QueueItem.ExecutionId -IsBusy $true
    }
    else {
        Write-Output "!!!!!!!!!! NO COANTAINER SLOT AVILABLE."
        Write-Output "EXITING! No waitlist available."
        exit
    }
}





Write-Host "Starting new Container Instance at:  $(Get-Date)"

# $container = New-AzContainerInstanceObject -Name "poc-func-api-instance-$QueueItem" -Image testacismdgithub.azurecr.io/testacismdgithub:latest
# $imageRegistryCredential = New-AzContainerGroupImageRegistryCredentialObject -Server "testacismdgithub.azurecr.io" -Username "$env:ACRUserName" -Password (ConvertTo-SecureString "$env:ACRPassword" -AsPlainText -Force) 
# $containerGroup = New-AzContainerGroup -ResourceGroupName test-aci -Name "testacismdgithub" -Location "West Europe" -Container $container -ImageRegistryCredential $imageRegistryCredential -RestartPolicy "OnFailure" 

$resouceGroupName = "test-aci"


$startTime = New-AzContainerInstanceEnvironmentVariableObject -Name "startTime" -Value "$(Get-Date)"
$scriptURI = New-AzContainerInstanceEnvironmentVariableObject -Name "scriptURI" -Value "$env:scriptURI"
$scriptToken = New-AzContainerInstanceEnvironmentVariableObject -Name "scriptToken" -Value "$env:scriptToken"
$ExecutionIdObject = New-AzContainerInstanceEnvironmentVariableObject -Name "ExecutionId" -Value "$($QueueItem.ExecutionId)"
$ContainerTypeObject = New-AzContainerInstanceEnvironmentVariableObject -Name "ContainerType" -Value "$($QueueItem.type)"
$ContainerCountObject = New-AzContainerInstanceEnvironmentVariableObject -Name "ContainerCount" -Value "$pickedContainerCount"
$WebhookURLObject = New-AzContainerInstanceEnvironmentVariableObject -Name "WebhookURL" -Value "$env:FinishExecutionURL"


$port1 = New-AzContainerInstancePortObject -Port 8000 -Protocol TCP  
$port2 = New-AzContainerInstancePortObject -Port 8001 -Protocol TCP  
$env2 = New-AzContainerInstanceEnvironmentVariableObject -Name "env2" -SecureValue (ConvertTo-SecureString -String "value2" -AsPlainText -Force)

$imageRegistryCredential = New-AzContainerGroupImageRegistryCredentialObject -Server "testacismdgithub.azurecr.io" -Username "$env:ACRUserName" -Password (ConvertTo-SecureString "$env:ACRPassword" -AsPlainText -Force) 

if ($QueueItem.type -eq "default") {
    $container = New-AzContainerInstanceObject -Name "poc-func-aci-instance-base" -Image testacismdgithub.azurecr.io/base:latest -EnvironmentVariable @($startTime, $scriptURI, $scriptToken, $ContainerTypeObject, $ExecutionIdObject, $ContainerCountObject, $WebhookURLObject) -Port $port1
    $containerGroup = New-AzContainerGroup -ResourceGroupName $resouceGroupName -Name "poc-func-aci-container-base-$pickedContainerCount" -Location "West Europe" -Container @($container) -ImageRegistryCredential $imageRegistryCredential -RestartPolicy "Never" -LogAnalyticWorkspaceId "$env:LAWId" -LogAnalyticWorkspaceKey "$env:LAWKey"
}
else {
    $container = New-AzContainerInstanceObject -Name "poc-func-aci-instance-$($QueueItem.type)" -Image testacismdgithub.azurecr.io/$($QueueItem.type):latest -EnvironmentVariable @($startTime, $scriptURI, $scriptToken, $ContainerTypeObject, $ExecutionIdObject, $ContainerCountObject, $WebhookURLObject) -Port $port1
    $containerGroup = New-AzContainerGroup -ResourceGroupName test-aci -Name "poc-func-aci-container-$($QueueItem.type)-$pickedContainerCount" -Location "West Europe" -Container @($container) -ImageRegistryCredential $imageRegistryCredential -RestartPolicy "Never" -LogAnalyticWorkspaceId "$env:LAWId" -LogAnalyticWorkspaceKey "$env:LAWKey"
}

# $container = New-AzContainerInstanceObject -Name "poc-func-api-instance-$($QueueItem.name)" -Image testacismdgithub.azurecr.io/poc-func-aci:latest -EnvironmentVariable @($startTime, $scriptURI, $scriptToken) -Port $port1
# # $container2 = New-AzContainerInstanceObject -Name "poc-func-api-instance-$QueueItem-2" -Image testacismdgithub.azurecr.io/poc-func-aci:latest -EnvironmentVariable @($startTime, $scriptURI, $scriptToken) -Port $port2
# $imageRegistryCredential = New-AzContainerGroupImageRegistryCredentialObject -Server "testacismdgithub.azurecr.io" -Username "$env:ACRUserName" -Password (ConvertTo-SecureString "$env:ACRPassword" -AsPlainText -Force) 
# # $containerGroup = New-AzContainerGroup -ResourceGroupName test-aci -Name "poc-func-aci-container" -Location "West Europe" -Container @($container, $container2) -ImageRegistryCredential $imageRegistryCredential -RestartPolicy "Never" -LogAnalyticWorkspaceId "$env:LAWId" -LogAnalyticWorkspaceKey "$env:LAWKey"
# $containerGroup = New-AzContainerGroup -ResourceGroupName test-aci -Name "poc-func-aci-container" -Location "West Europe" -Container @($container) -ImageRegistryCredential $imageRegistryCredential -RestartPolicy "Never" -LogAnalyticWorkspaceId "$env:LAWId" -LogAnalyticWorkspaceKey "$env:LAWKey"
 

# Start-AzContainerGroup -Name "poc-func-aci-container" -ResourceGroupName test-aci
# Invoke-AzContainerInstanceCommand `
#       -ContainerGroupName "poc-func-aci-container" `
#       -ContainerName "poc-func-api-instance-$QueueItem" `
#       -ResourceGroupName test-aci `
#       -Command "CMD ['pwsh', '-File', 'test.ps1']"


# $port1 = New-AzContainerInstancePortObject -Port 8000 -Protocol TCP  
# $port2 = New-AzContainerInstancePortObject -Port 8001 -Protocol TCP  
# $container = New-AzContainerInstanceObject -Name "poc-instance-$QueueItem" -Image nginx -RequestCpu 1 -RequestMemoryInGb 1.5 -Port @($port1, $port2)  
# $containerGroup = New-AzContainerGroup -ResourceGroupName test-aci -Name "testacismdgithub" -Location "West Europe" -Container $container -OsType Linux -RestartPolicy "OnFailure"

# $container1 = New-AzContainerInstanceObject -Name "poc-instance-$QueueItem-1" -Image nginx -RequestCpu 1 -RequestMemoryInGb 1.5 -Port @($port1, $port2)  
# $containerGroup1 = New-AzContainerGroup -ResourceGroupName test-aci -Name "testacismdgithub" -Location "West Europe" -Container $container1 -OsType Linux -RestartPolicy "OnFailure"

# $container1 = New-AzContainerInstanceObject -Name "poc-instance-$QueueItem-2" -Image nginx -RequestCpu 1 -RequestMemoryInGb 1.5 -Port @($port1, $port2)  
# $containerGroup1 = New-AzContainerGroup -ResourceGroupName test-aci -Name "testacismdgithub" -Location "West Europe" -Container $container1 -OsType Linux -RestartPolicy "OnFailure"


# $containerB = New-AzContainerInstanceObject -Name "poc-instance-$QueueItem-B" -Image nginx -RequestCpu 1 -RequestMemoryInGb 1.5 -Port @($port1, $port2)  
# $containerGroupB = New-AzContainerGroup -ResourceGroupName test-aci -Name "poc-func-aci-cg-B" -Location "West Europe" -Container $container1 -OsType Linux -RestartPolicy "Never"

# $containerC = New-AzContainerInstanceObject -Name "poc-instance-$QueueItem-C" -Image nginx -RequestCpu 1 -RequestMemoryInGb 1.5 -Port @($port1, $port2)  
# $containerGroupC = New-AzContainerGroup -ResourceGroupName test-aci -Name "poc-func-aci-cg-C" -Location "West Europe" -Container $container1 -ImageRegistryCredential $imageRegistryCredential -RestartPolicy "Never" 


 

# New-AzContainerGroup -ResourceGroupName test-aci -Name "container-$QueueItem" `
# -Image alpine -OsType Linux `
# -Command "echo 'Hello from an Azure container instance triggered by an Azure function'" `
# -RestartPolicy Never

Write-Host "Finishing new Container Instance at:  $(Get-Date)"
Write-Host "########## FINISH ###########"
