<#
.SYNOPSIS
    Copies the live OpenCode / OpenChamber configuration into this repository.

.DESCRIPTION
    Mirrors the settings listed in $Items from the live config folders into
    this repo, then commits the change. Secrets (service.json,
    relay-identity.json, git-credential-endpoint.json, env-var API keys) are
    never copied; see RESTORE.md for how they are regenerated.

    Run from this repo's folder. AI agents: this is the "backup" half of
    RESTORE.md.

.PARAMETER Push
    Also push the commit to origin after committing.

.EXAMPLE
    .\backup.ps1

.EXAMPLE
    .\backup.ps1 -Push
#>
[CmdletBinding()]
param(
    [switch]$Push
)

$ErrorActionPreference = 'Stop'

# Live config locations.
$OpenCode = Join-Path $env:USERPROFILE '.config\opencode'
$OpenChamber = Join-Path $env:USERPROFILE '.config\openchamber'

# Relative destination inside this repo  ->  source (folder or file).
$Items = @(
    @{ Dst = 'opencode\opencode.jsonc';            Src = Join-Path $OpenCode 'opencode.jsonc' },
    @{ Dst = 'opencode\AGENTS.md';                 Src = Join-Path $OpenCode 'AGENTS.md' },
    @{ Dst = 'opencode\dcp.jsonc';                 Src = Join-Path $OpenCode 'dcp.jsonc' },
    @{ Dst = 'opencode\cli.json';                  Src = Join-Path $OpenCode 'cli.json' },
    @{ Dst = 'opencode\oh-my-opencode-slim.json';  Src = Join-Path $OpenCode 'oh-my-opencode-slim.json' },
    @{ Dst = 'opencode\skills';                    Src = Join-Path $OpenCode 'skills' },
    @{ Dst = 'openchamber\preferences.json';       Src = Join-Path $OpenChamber 'preferences.json' },
    @{ Dst = 'openchamber\routing.json';           Src = Join-Path $OpenChamber 'routing.json' },
    @{ Dst = 'openchamber\settings.local.json';    Src = Join-Path $OpenChamber 'settings.json' }
)

foreach ($item in $Items) {
    $dst = Join-Path $PSScriptRoot $item.Dst
    if (Test-Path $item.Src -PathType Container) {
        if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
        New-Item -ItemType Directory -Force -Path (Split-Path $dst) | Out-Null
        Copy-Item $item.Src $dst -Recurse -Force
        Write-Host "copied dir   $($item.Src) -> $($item.Dst)"
    }
    elseif (Test-Path $item.Src) {
        New-Item -ItemType Directory -Force -Path (Split-Path $dst) | Out-Null
        Copy-Item $item.Src $dst -Force
        Write-Host "copied file  $($item.Src) -> $($item.Dst)"
    }
    else {
        Write-Warning "missing, skipped: $($item.Src)"
    }
}

git -C $PSScriptRoot add -A
$staged = git -C $PSScriptRoot status --porcelain
if (-not $staged) {
    Write-Host "Nothing changed since the last backup."
    return
}

git -C $PSScriptRoot commit -m "backup $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
if ($Push) {
    git -C $PSScriptRoot push
    Write-Host "Pushed to origin."
}
