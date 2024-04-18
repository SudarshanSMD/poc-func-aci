using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

Install-Module Az.Storage -RequiredVersion 6.1.2  -Scope CurrentUser -Force -AllowClobber
Import-Module Az.Storage
Install-Module AzTable -RequiredVersion 2.1.0 -Scope CurrentUser -Force -AllowClobber
Import-Module AzTable

function TableContainerUpdate([String] $ContainerType, [String] $ContainerCount, [String] $ExecutionId, [bool] $IsBusy) {    
    $StorageAccountContext = (Get-AzStorageAccount -Name $env:StorageAccountName -ResourceGroupName $env:StorageAccountRG  -ErrorAction Stop).Context
    $cloudTable = (Get-AzStorageTable -Context $StorageAccountContext -Name "Container").CloudTable

    $filter = "(PartitionKey eq '$ContainerType') and (RowKey eq '$ContainerCount')"

    $container = Get-AzTableRow -table $cloudTable -CustomFilter $filter

    # Change the entity.
    $container.ExecutionId = $ExecutionId
    $container.IsBusy = $IsBusy

    # To commit the change, pipe the updated record into the update cmdlet.
    $container | Update-AzTableRow -table $cloudTable
    write-host "Table container updated"
}

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."


# $clientCredential = New-Object Microsoft.IdentityModel.Clients.ActiveDirectory.ClientCredential($env:AppId, $env:AppSecret)
$azurePassword = ConvertTo-SecureString $env:AppSecret -AsPlainText -Force
$PSCredential = New-Object System.Management.Automation.PSCredential($env:AppId, $azurePassword)

Connect-AzAccount -Credential $PSCredential `
    -Tenant "43548595-c3b2-4c7c-b07b-b97911e6c10c" `
    -SubscriptionId "16195a49-804b-4707-bb52-686a311b9b98"   `
    -ServicePrincipal `
    -ErrorAction Stop 
                    

# Interact with query parameters or the body of the request.
$name = $Request.Query.Name
if (-not $name) {
    $name = $Request.Body.Name
}

$ContainerType = $Request.Body.ContainerType
if (-not $ContainerType) {
    Write-Host "ContainerType iS NULLLLLLLLL"
}

$ContainerNumber = $Request.Body.ContainerNumber
if (-not $ContainerNumber) {
    Write-Host "ContainerNumber iS NULLLLLLLLL"
}

$ExecutionId = $Request.Body.ExecutionId
if (-not $ExecutionId) {
    Write-Host "EXECUTION ID IS NULLLLLLLLL"
}

write-host "Updating Conatiner entry. PK: $ContainerType RowKey: $ContainerNumber ExecutionId: $ExecutionId"
TableContainerUpdate -ContainerType $ContainerType -ContainerCount $ContainerNumber -ExecutionId $ExecutionId -IsBusy $false


$body = "Container updated"

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $body
})
