Import-Module .\Modules\runner.utilities\runner.utilities.psm1

Write-Host "Hello from test PowerShellScript. StartTime: $env:startTime"

try {
    Write-Host "Getting Script"
    $Script = Get-Script
    
    Write-Host "Preparing Script for execution"
    $wrapperStart = "function Invoke-Script {param()"
    $wrapperEnd = "}"
    $wrappedScript = "{0}{1}{2}" -f $wrapperStart, $Script, $wrapperEnd

    Write-Host "Invoking Script"
    Invoke-Expression -Command $wrappedScript
    Invoke-Script
    Write-Host "Script Exceution Complete"
}
catch {
    Write-Error "Exception while executing Script."
}


# Define the payload data (you can customize this)
$payload = @{
    "ContainerType" = $env:ContainerType
    "ContainerNumber" = $env:ContainerCount
    "ExecutionId" = $env:ExecutionId
}
# Convert the payload to JSON
$jsonPayload = $payload | ConvertTo-Json

# Send the payload to the webhook
Invoke-RestMethod -Uri $env:WebhookURL -Method Post -Body $jsonPayload -ContentType "application/json"

# Print a success message
Write-Host "Payload sent successfully to $env:WebhookURL"

# #<---- Send payload to webhook ---------
# # Define the webhook URL
# $webhookUrl = "https://eo1u4qkjzptlhqa.m.pipedream.net"

# # Define the payload data (you can customize this)
# $payload = @{
#     "message" = "Heeeellooooo. Oooohhhh. Kaise ho aapp? Pata hai aaj kazama ne chaddi me he susu kar li. kitana gaanda baccha hai. $env:startTime"
#     "user" = "Shinchan Nohara"
# }
# # Convert the payload to JSON
# $jsonPayload = $payload | ConvertTo-Json

# # Send the payload to the webhook
# Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $jsonPayload -ContentType "application/json"

# # Print a success message
# Write-Host "Payload sent successfully to $webhookUrl"
# #>---- Send payload to webhook ---------



Write-Host "Test complete: $(Get-Date)"