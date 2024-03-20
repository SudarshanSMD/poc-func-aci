
Function Get-Script {
    [CmdletBinding()]
    Param ()
   
    $headers = @{
        'Authorization' = "Bearer $env:scriptToken"
    }

    $params = @{
        "ContentType" = "application/json"
        "Header"      = $headers
        "Method"      = 'Get'
        "URI"         = "$env:scriptURI"
    }
    try {
        Write-Host "Invoking REST method $($params.Method) on $($params.URI)"
        $Result = Invoke-RestMethod @params
        
        return $Result #| ConvertFrom-Json -Depth 100        
    }
    catch {
        Write-Information "API call failed url, $($params.Method) on $($params.URI)"
        Write-Error "Response $($_.Exception.Response | ConvertTo-Json)"
        throw
    }
    return $Result
}
