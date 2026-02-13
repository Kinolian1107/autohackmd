# hackmd_upload.ps1 - Upload markdown to HackMD
# Usage:
#   .\hackmd_upload.ps1 -File <path> [-Tags "tag1,tag2"]
#   .\hackmd_upload.ps1 -Title "title" -Content "content" [-Tags "tag1,tag2"]
#
# Output: JSON { "noteId", "publishLink", "shortId", "title" }

[CmdletBinding()]
param(
    [string]$File,
    [string]$Title,
    [string]$Content,
    [string]$Tags,
    [switch]$Help
)

$ErrorActionPreference = "Stop"
$ConfigDir = Join-Path $env:USERPROFILE ".config\autohackmd"
$ConfigFile = Join-Path $ConfigDir "config.json"
$ApiBase = "https://api.hackmd.io/v1"

function Show-Usage {
    Write-Host @"
Usage: .\hackmd_upload.ps1 [OPTIONS]

Options:
  -File <path>       Upload from markdown file
  -Title <title>     Note title (used with -Content)
  -Content <text>    Note content as string
  -Tags <t1,t2>      Comma-separated tags to embed in note
  -Help              Show this help message

Output: JSON with noteId, publishLink, shortId, title

Permissions are set to:
  - readPermission: guest (everyone can read)
  - writePermission: owner (only you can edit)
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

if ($Help) { Show-Usage }

# Validate input
if (-not $File -and -not $Content) {
    Write-Output '{"status":"error","message":"Either -File or -Content is required"}'
    exit 1
}

# Read file content
if ($File) {
    if (-not (Test-Path $File)) {
        Write-Output (@{ status = "error"; message = "File not found: $File" } | ConvertTo-Json -Compress)
        exit 1
    }
    $Content = Get-Content $File -Raw -Encoding UTF8
    if (-not $Title) {
        # Extract title from first H1 header
        $match = [regex]::Match($Content, '^# (.+)$', [System.Text.RegularExpressions.RegexOptions]::Multiline)
        if ($match.Success) {
            $Title = $match.Groups[1].Value.Trim()
        }
        else {
            $Title = [System.IO.Path]::GetFileNameWithoutExtension($File)
        }
    }
}

# Prepend tags if provided
if ($Tags) {
    $tagList = $Tags -split ',' | ForEach-Object { "``$($_.Trim())``" }
    $tagLine = "###### tags: " + ($tagList -join " ")
    if ($Content -notmatch '(?m)^###### tags:') {
        if ($Content -match '(?m)^# .+') {
            # Insert after first H1
            $Content = $Content -replace '(^# .+$)', "`$1`n$tagLine"
        }
        else {
            $Content = "$tagLine`n$Content"
        }
    }
}

# Get token
$tkn = Get-HackMDToken
if (-not $tkn) {
    Write-Output '{"status":"error","message":"No token found. Set HACKMD_API_TOKEN env var or run: .\\hackmd_config.ps1 -Token <your-token>"}'
    exit 1
}

# Build request body
$body = @{
    title = $Title
    content = $Content
    readPermission = "guest"
    writePermission = "owner"
    commentPermission = "everyone"
} | ConvertTo-Json -Depth 10

$headers = @{
    Authorization = "Bearer $tkn"
    "Content-Type" = "application/json"
}

try {
    $response = Invoke-RestMethod -Uri "$ApiBase/notes" -Method Post -Headers $headers -Body ([System.Text.Encoding]::UTF8.GetBytes($body)) -ContentType "application/json; charset=utf-8"

    Write-Output (@{
        status = "success"
        noteId = $response.id
        publishLink = $response.publishLink
        shortId = $response.shortId
        title = $response.title
    } | ConvertTo-Json -Compress)
}
catch {
    $statusCode = 0
    if ($_.Exception.Response) {
        $statusCode = $_.Exception.Response.StatusCode.Value__
    }
    Write-Output (@{
        status = "error"
        httpCode = $statusCode
        message = "Upload failed: $($_.Exception.Message)"
    } | ConvertTo-Json -Compress)
    exit 1
}
