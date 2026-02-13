# hackmd_update.ps1 - Update a HackMD note
# Usage:
#   .\hackmd_update.ps1 -NoteId <id> [OPTIONS]
#
# Options:
#   -ReadPerm <owner|signed_in|guest>
#   -WritePerm <owner|signed_in|guest>
#   -Content <text>
#   -File <path>
#   -Permalink <slug>
#   -Delete                Delete the note
#
# Output: JSON status message

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$NoteId,
    [string]$ReadPerm,
    [string]$WritePerm,
    [string]$Content,
    [string]$File,
    [string]$Permalink,
    [switch]$Delete,
    [switch]$Help
)

$ErrorActionPreference = "Stop"
$ConfigDir = Join-Path $env:USERPROFILE ".config\autohackmd"
$ConfigFile = Join-Path $ConfigDir "config.json"
$ApiBase = "https://api.hackmd.io/v1"

function Show-Usage {
    Write-Host @"
Usage: .\hackmd_update.ps1 -NoteId <id> [OPTIONS]

Options:
  -NoteId <id>                        Note ID (required)
  -ReadPerm <owner|signed_in|guest>   Update read permission
  -WritePerm <owner|signed_in|guest>  Update write permission
  -Content <text>                     Update note content
  -File <path>                        Update content from file
  -Permalink <slug>                   Set permalink
  -Delete                             Delete the note
  -Help                               Show this help message

Note: When updating permissions, both -ReadPerm and -WritePerm
must be provided together. WritePerm must be stricter than
or equal to ReadPerm.
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

# Get token
$tkn = Get-HackMDToken
if (-not $tkn) {
    Write-Output '{"status":"error","message":"No token found. Set HACKMD_API_TOKEN env var or run: .\\hackmd_config.ps1 -Token <your-token>"}'
    exit 1
}

$headers = @{
    Authorization = "Bearer $tkn"
}

# Handle delete
if ($Delete) {
    try {
        Invoke-RestMethod -Uri "$ApiBase/notes/$NoteId" -Method Delete -Headers $headers
        Write-Output (@{
            status = "success"
            message = "Note deleted"
            noteId = $NoteId
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
            message = "Delete failed: $($_.Exception.Message)"
        } | ConvertTo-Json -Compress)
        exit 1
    }
    exit 0
}

# Read file if provided
if ($File) {
    if (-not (Test-Path $File)) {
        Write-Output (@{ status = "error"; message = "File not found: $File" } | ConvertTo-Json -Compress)
        exit 1
    }
    $Content = Get-Content $File -Raw -Encoding UTF8
}

# Build update body
$bodyHash = @{}
if ($Content) { $bodyHash.content = $Content }
if ($ReadPerm) { $bodyHash.readPermission = $ReadPerm }
if ($WritePerm) { $bodyHash.writePermission = $WritePerm }
if ($Permalink) { $bodyHash.permalink = $Permalink }

if ($bodyHash.Count -eq 0) {
    Write-Output '{"status":"error","message":"No update fields provided. Use -Content, -ReadPerm, -WritePerm, or -Permalink"}'
    exit 1
}

$body = $bodyHash | ConvertTo-Json -Depth 10
$headers["Content-Type"] = "application/json"

try {
    Invoke-RestMethod -Uri "$ApiBase/notes/$NoteId" -Method Patch -Headers $headers -Body ([System.Text.Encoding]::UTF8.GetBytes($body)) -ContentType "application/json; charset=utf-8"
    Write-Output (@{
        status = "success"
        message = "Note updated"
        noteId = $NoteId
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
        message = "Update failed: $($_.Exception.Message)"
    } | ConvertTo-Json -Compress)
    exit 1
}
