Write-Host 'Hello from test PowerShellScript.'


# PowerShell script to send a sample payload to a webhook

# Define the webhook URL
$webhookUrl = "https://eo1u4qkjzptlhqa.m.pipedream.net"

# Define the payload data (you can customize this)
$payload = @{
    "message" = "Heeeellooooo. Oooohhhh. Kaise ho aapp? Pata hai aaj kazama ne chaddi me he susu kar li. kitana gaanda baccha hai. $env:startTime"
    "user" = "Shinchan Nohara"
}

# Convert the payload to JSON
$jsonPayload = $payload | ConvertTo-Json

# Send the payload to the webhook
Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $jsonPayload -ContentType "application/json"

# Print a success message
Write-Host "Payload sent successfully to $webhookUrl"
