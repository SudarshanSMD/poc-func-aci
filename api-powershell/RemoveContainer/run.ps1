using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Interact with query parameters or the body of the request.
$name = $Request.Query.Name
if (-not $name) {
    $name = $Request.Body.Name
}

$body = "This HTTP triggered function executed successfully. Pass a name in the query string or in the request body for a personalized response."

$azurePassword = ConvertTo-SecureString $env:AppSecret -AsPlainText -Force
$PSCredential = New-Object System.Management.Automation.PSCredential($env:AppId, $azurePassword)

Connect-AzAccount -Credential $PSCredential `
                    -Tenant "43548595-c3b2-4c7c-b07b-b97911e6c10c" `
                    -SubscriptionId "16195a49-804b-4707-bb52-686a311b9b98"   `
                    -ServicePrincipal `
                    -ErrorAction Stop 
                    
Remove-AzContainerGroup -Name "testacismdgithub" -ResourceGroupName test-aci
Remove-AzContainerGroup -Name "poc-func-aci-cg-B" -ResourceGroupName test-aci
Remove-AzContainerGroup -Name "poc-func-aci-cg-C" -ResourceGroupName test-aci

if ($name) {
    $body = "Hello, $name. Container has been removed."
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $body
})
