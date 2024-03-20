# Input bindings are passed in via param block.
param($QueueItem, $TriggerMetadata)

# Write out the queue message and insertion time to the information log.
Write-Host "PowerShell queue trigger function processed work item: $QueueItem"
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
Write-Host "Starting new Container Instance at:  $(Get-Date)"

# $container = New-AzContainerInstanceObject -Name "poc-func-api-instance-$QueueItem" -Image testacismdgithub.azurecr.io/testacismdgithub:latest
# $imageRegistryCredential = New-AzContainerGroupImageRegistryCredentialObject -Server "testacismdgithub.azurecr.io" -Username "$env:ACRUserName" -Password (ConvertTo-SecureString "$env:ACRPassword" -AsPlainText -Force) 
# $containerGroup = New-AzContainerGroup -ResourceGroupName test-aci -Name "testacismdgithub" -Location "West Europe" -Container $container -ImageRegistryCredential $imageRegistryCredential -RestartPolicy "OnFailure" 


$startTime = New-AzContainerInstanceEnvironmentVariableObject -Name "startTime" -Value "$(Get-Date)"
$scriptURI = New-AzContainerInstanceEnvironmentVariableObject -Name "scriptURI" -Value "$env:scriptURI"
$scriptToken = New-AzContainerInstanceEnvironmentVariableObject -Name "scriptToken" -Value "$env:scriptToken"

$port1 = New-AzContainerInstancePortObject -Port 8000 -Protocol TCP  
$port2 = New-AzContainerInstancePortObject -Port 8001 -Protocol TCP  
$env2 = New-AzContainerInstanceEnvironmentVariableObject -Name "env2" -SecureValue (ConvertTo-SecureString -String "value2" -AsPlainText -Force)

# $container = New-AzContainerInstanceObject -Name "poc-func-api-instance-$QueueItem" -Image testacismdgithub.azurecr.io/poc-func-aci:latest -EnvironmentVariable @($startTime, $scriptURI, $scriptToken) -Port $port1
# # $container2 = New-AzContainerInstanceObject -Name "poc-func-api-instance-$QueueItem-2" -Image testacismdgithub.azurecr.io/poc-func-aci:latest -EnvironmentVariable @($startTime, $scriptURI, $scriptToken) -Port $port2
# $imageRegistryCredential = New-AzContainerGroupImageRegistryCredentialObject -Server "testacismdgithub.azurecr.io" -Username "$env:ACRUserName" -Password (ConvertTo-SecureString "$env:ACRPassword" -AsPlainText -Force) 
# # $containerGroup = New-AzContainerGroup -ResourceGroupName test-aci -Name "poc-func-aci-container" -Location "West Europe" -Container @($container, $container2) -ImageRegistryCredential $imageRegistryCredential -RestartPolicy "Never" -LogAnalyticWorkspaceId "$env:LAWId" -LogAnalyticWorkspaceKey "$env:LAWKey"
# $containerGroup = New-AzContainerGroup -ResourceGroupName test-aci -Name "poc-func-aci-container" -Location "West Europe" -Container @($container) -ImageRegistryCredential $imageRegistryCredential -RestartPolicy "Never" -LogAnalyticWorkspaceId "$env:LAWId" -LogAnalyticWorkspaceKey "$env:LAWKey"
 

Start-AzContainerGroup -Name "poc-func-aci-container" -ResourceGroupName test-aci
Invoke-AzContainerInstanceCommand `
      -ContainerGroupName "poc-func-aci-container" `
      -ContainerName "poc-func-api-instance-$QueueItem" `
      -ResourceGroupName test-aci `
      -Command "CMD ['pwsh', '-File', 'test.ps1']"


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

Write-Host "Finsihing new Container Instance at:  $(Get-Date)"

write-host "Created ContainerGroup: $containerGroup"
write-host "Created ContainerGroup1: $containerGroup1"


Write-Host "########## FINISH ###########"
