# sync.ps1 — keep CLAUDE.md and AGENTS.md byte-identical (Windows).
#
# CLAUDE.md is the source of truth. Run after editing it.
# CI uses `.\scripts\sync.ps1 -Check` to fail if drifted.

[CmdletBinding()]
param(
    [switch]$Check
)

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot  = Split-Path -Parent $ScriptDir
$Src = Join-Path $RepoRoot 'CLAUDE.md'
$Dst = Join-Path $RepoRoot 'AGENTS.md'

if (-not (Test-Path -LiteralPath $Src)) {
    Write-Host "X $Src missing." -ForegroundColor Red
    exit 1
}

if ($Check) {
    if (-not (Test-Path -LiteralPath $Dst)) {
        Write-Host "X AGENTS.md missing — run sync.ps1 to fix." -ForegroundColor Red
        exit 1
    }
    $hashSrc = (Get-FileHash -LiteralPath $Src -Algorithm SHA256).Hash
    $hashDst = (Get-FileHash -LiteralPath $Dst -Algorithm SHA256).Hash
    if ($hashSrc -ne $hashDst) {
        Write-Host "X AGENTS.md is out of sync with CLAUDE.md" -ForegroundColor Red
        Write-Host "  Run scripts\sync.ps1 to fix."
        exit 1
    }
    Write-Host "OK AGENTS.md matches CLAUDE.md"
    exit 0
}

Copy-Item -LiteralPath $Src -Destination $Dst -Force
Write-Host "OK synced $Dst from $Src"
