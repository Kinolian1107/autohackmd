# hackmd_config.ps1 - Configure HackMD API Token
# Usage:
#   .\hackmd_config.ps1 -Token <token>    # Set token
#   .\hackmd_config.ps1 -Verify           # Verify stored token
#   .\hackmd_config.ps1 -Show             # Show current config path
#   .\hackmd_config.ps1 -Remove           # Remove stored token

[CmdletBinding()]
param(
    [string]$Token,
    [switch]$Verify,
    [switch]$Show,
    [switch]$Remove,
    [switch]$Help
)

$ErrorActionPreference = "Stop"
$ConfigDir = Join-Path $env:USERPROFILE ".config\autohackmd"
$ConfigFile = Join-Path $ConfigDir "config.json"
$ApiBase = "https://api.hackmd.io/v1"

function Show-Usage {
    Write-Host @"
Usage: .\hackmd_config.ps1 [OPTIONS]

Options:
  -Token <token>   Save HackMD API token to config
  -Verify          Verify the stored or env token is valid
  -Show            Show config file path and status
  -Remove          Remove stored token
  -Help            Show this help message

Token priority:
  1. `$env:HACKMD_API_TOKEN environment variable
  2. ~\.config\autohackmd\config.json

Get your token from: https://hackmd.io/settings#api
"@
    exit 0
}

function Get-HackMDToken {
    if ($env:HACKMD_API_TOKEN) {
        return $env:HACKMD_API_TOKEN
    }
    if (Test-Path $ConfigFile) {
        $config = Get-Content $ConfigFile -Raw | ConvertFrom-Json
        if ($config.api_token) {
            return $config.api_token
        }
    }
    return $null
}

function Save-Token {
    param([string]$TokenValue)
    if (-not (Test-Path $ConfigDir)) {
        New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
    }
    $config = @{ api_token = $TokenValue } | ConvertTo-Json
    Set-Content -Path $ConfigFile -Value $config -Encoding UTF8
    # Set file permissions (owner only)
    $acl = Get-Acl $ConfigFile
    $acl.SetAccessRuleProtection($true, $false)
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        [System.Security.Principal.WindowsIdentity]::GetCurrent().Name,
        "FullControl", "Allow")
    $acl.AddAccessRule($rule)
    Set-Acl $ConfigFile $acl
    Write-Output (@{
        status = "success"
        message = "Token saved to $ConfigFile"
        config_path = $ConfigFile
    } | ConvertTo-Json -Compress)
}

function Test-Token {
    $tkn = Get-HackMDToken
    if (-not $tkn) {
        Write-Output '{"status":"error","message":"No token found. Set HACKMD_API_TOKEN env var or run: .\\hackmd_config.ps1 -Token <your-token>"}'
        exit 1
    }
    try {
        $headers = @{ Authorization = "Bearer $tkn" }
        $response = Invoke-RestMethod -Uri "$ApiBase/me" -Headers $headers -Method Get
        Write-Output (@{
            status = "success"
            message = "Token is valid"
            user = $response.name
        } | ConvertTo-Json -Compress)
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.Value__
        Write-Output (@{
            status = "error"
            message = "Token is invalid (HTTP $statusCode)"
        } | ConvertTo-Json -Compress)
        exit 1
    }
}

function Show-Config {
    $tokenSource = "none"
    if ($env:HACKMD_API_TOKEN) {
        $tokenSource = "environment"
    }
    elseif (Test-Path $ConfigFile) {
        $tokenSource = "config_file"
    }
    Write-Output (@{
        config_path = $ConfigFile
        token_source = $tokenSource
        config_exists = (Test-Path $ConfigFile)
    } | ConvertTo-Json -Compress)
}

function Remove-StoredToken {
    if (Test-Path $ConfigFile) {
        Remove-Item $ConfigFile -Force
        Write-Output (@{
            status = "success"
            message = "Token removed from $ConfigFile"
        } | ConvertTo-Json -Compress)
    }
    else {
        Write-Output (@{
            status = "info"
            message = "No config file found at $ConfigFile"
        } | ConvertTo-Json -Compress)
    }
}

# Main
if ($Help) { Show-Usage }
elseif ($Token) { Save-Token -TokenValue $Token }
elseif ($Verify) { Test-Token }
elseif ($Show) { Show-Config }
elseif ($Remove) { Remove-StoredToken }
else { Show-Usage }
