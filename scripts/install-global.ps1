# install-global.ps1 — Windows installer for the Bitontree coding standards.
#
# Symlinks the rulebook into the user's global Claude Code and Codex config
# directories, plus a global git commit-msg hook.
#
# Usage (PowerShell):
#   .\scripts\install-global.ps1            # interactive
#   .\scripts\install-global.ps1 -Force     # overwrite existing files
#   .\scripts\install-global.ps1 -DryRun    # show what would happen
#
# Or double-click scripts\install-global.bat which wraps this.
#
# Symlinks on Windows require ONE of:
#   1. Developer Mode enabled (Settings -> Privacy & security -> For developers)
#   2. Running PowerShell as Administrator
# The script will tell you if neither is available.

#Requires -Version 5.1

[CmdletBinding()]
param(
    [switch]$Force,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

# ---------- Resolve paths ----------------------------------------------------
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot  = Split-Path -Parent $ScriptDir
$ClaudeMd  = Join-Path $RepoRoot 'CLAUDE.md'
$AgentsMd  = Join-Path $RepoRoot 'AGENTS.md'
$HookSrc   = Join-Path $RepoRoot 'templates\commit-msg-hook'

foreach ($f in @($ClaudeMd, $AgentsMd, $HookSrc)) {
    if (-not (Test-Path -LiteralPath $f)) {
        Write-Host "X Missing required file: $f" -ForegroundColor Red
        exit 1
    }
}

# ---------- Helpers ----------------------------------------------------------
function Write-DryOrRun {
    param([string]$Description, [scriptblock]$Action)
    if ($DryRun) {
        Write-Host "[dry-run] $Description"
    } else {
        & $Action | Out-Null
    }
}

function Test-SymlinkSupport {
    $tmpTarget = Join-Path $env:TEMP "bitontree-symlink-target-$([Guid]::NewGuid()).txt"
    $tmpLink   = Join-Path $env:TEMP "bitontree-symlink-link-$([Guid]::NewGuid())"
    try {
        Set-Content -LiteralPath $tmpTarget -Value 'test' -ErrorAction Stop
        New-Item -ItemType SymbolicLink -Path $tmpLink -Target $tmpTarget -ErrorAction Stop | Out-Null
        return $true
    } catch {
        return $false
    } finally {
        if (Test-Path -LiteralPath $tmpLink)   { Remove-Item -LiteralPath $tmpLink   -Force -ErrorAction SilentlyContinue }
        if (Test-Path -LiteralPath $tmpTarget) { Remove-Item -LiteralPath $tmpTarget -Force -ErrorAction SilentlyContinue }
    }
}

function Get-LinkTargetOrNull {
    param([string]$Path)
    try {
        $item = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
        if ($item.LinkType -eq 'SymbolicLink') { return $item.Target | Select-Object -First 1 }
        return $null
    } catch { return $null }
}

function Install-Link {
    param([string]$Source, [string]$Destination)

    $destDir = Split-Path -Parent $Destination
    if (-not (Test-Path -LiteralPath $destDir)) {
        Write-DryOrRun "mkdir -p '$destDir'" { New-Item -ItemType Directory -Path $destDir -Force }
    }

    if (Test-Path -LiteralPath $Destination) {
        $existingTarget = Get-LinkTargetOrNull $Destination
        if ($existingTarget) {
            try {
                $resolvedExisting = (Resolve-Path -LiteralPath $existingTarget -ErrorAction Stop).Path
                $resolvedSource   = (Resolve-Path -LiteralPath $Source -ErrorAction Stop).Path
                if ($resolvedExisting -eq $resolvedSource) {
                    Write-Host "OK $Destination already linked"
                    return
                }
            } catch { }
            Write-Host "  $Destination is a symlink to $existingTarget"
        } else {
            Write-Host "  $Destination already exists (not a symlink)"
        }

        if ($DryRun) {
            Write-Host "  [dry-run] would prompt to overwrite (or use -Force)."
            return
        }
        if (-not $Force) {
            $ans = Read-Host "    Overwrite? [y/N]"
            if ($ans -notmatch '^[Yy]$') {
                Write-Host "  skipped."
                return
            }
        }
        $backup = "$Destination.bak." + (Get-Date -Format 'yyyyMMddHHmmss')
        Write-Host "  backing up to $backup"
        Write-DryOrRun "mv '$Destination' '$backup'" { Move-Item -LiteralPath $Destination -Destination $backup -Force }
    }

    Write-DryOrRun "ln -s '$Source' '$Destination'" {
        New-Item -ItemType SymbolicLink -Path $Destination -Target $Source -Force
    }
    Write-Host "OK linked $Destination -> $Source"
}

# ---------- Run -------------------------------------------------------------
Write-Host "Bitontree rulebook — global install (Windows)"
Write-Host "Repo: $RepoRoot"
Write-Host ""

if (-not $DryRun -and -not (Test-SymlinkSupport)) {
    Write-Host "X Cannot create symbolic links on this system." -ForegroundColor Red
    Write-Host ""
    Write-Host "  Windows requires ONE of:"
    Write-Host "    1. Developer Mode (recommended): Settings -> Privacy & security -> For developers -> Developer Mode = On"
    Write-Host "    2. Running this script in an Administrator PowerShell"
    Write-Host ""
    Write-Host "  Then re-run this installer."
    exit 1
}

# 1. Claude Code
Install-Link $ClaudeMd (Join-Path $env:USERPROFILE '.claude\CLAUDE.md')

# 2. Codex
Install-Link $AgentsMd (Join-Path $env:USERPROFILE '.codex\AGENTS.md')

# 3. Global git commit-msg hook
$HooksDir = Join-Path $env:USERPROFILE '.bitontree-hooks'
Install-Link $HookSrc (Join-Path $HooksDir 'commit-msg')

$currentHooksPath = & git config --global --get core.hooksPath 2>$null
if ($LASTEXITCODE -eq 0 -and $currentHooksPath -eq $HooksDir) {
    Write-Host "OK git core.hooksPath already set to $HooksDir"
} else {
    $shouldSet = $true
    if ($currentHooksPath) {
        Write-Host "  git core.hooksPath is currently: $currentHooksPath"
        if ($DryRun) {
            Write-Host "  [dry-run] would prompt to replace with $HooksDir (or use -Force)."
            $shouldSet = $false
        } elseif (-not $Force) {
            $ans = Read-Host "    Replace with $HooksDir? [y/N]"
            if ($ans -notmatch '^[Yy]$') {
                Write-Host "  skipped hooksPath change."
                $shouldSet = $false
            }
        }
    }
    if ($shouldSet) {
        Write-DryOrRun "git config --global core.hooksPath '$HooksDir'" {
            & git config --global core.hooksPath $HooksDir
        }
        if (-not $DryRun) { Write-Host "OK set git core.hooksPath -> $HooksDir" }
    }
}

Write-Host ""
Write-Host "Done. To verify:"
Write-Host "  Get-Item ~/.claude/CLAUDE.md, ~/.codex/AGENTS.md, ~/.bitontree-hooks/commit-msg | Format-List FullName,Target,LinkType"
Write-Host "  git config --global --get core.hooksPath"
