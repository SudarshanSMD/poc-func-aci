using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Interact with query parameters or the body of the request.
# $name = $Request.Query.Name
$name = $Request.Body.name
if (-not $name) {
    $name = "default"
}

$type = $Request.Body.type
if (-not $type) {
    $type = "default"
}

$InstanceId = $Request.Body.InstanceId
if (-not $InstanceId) {
    $InstanceId = "xxx"
}

$body = "Hello, $name. This HTTP triggered function executed successfully. InvocationId: $($TriggerMetadata.InvocationId)"

Push-OutputBinding -Name StartExecution -Value $Request.Body

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $body
    })
