<#
.SYNOPSIS
  Set up the Windows side of the modern terminal workflow.

.DESCRIPTION
  Installs WezTerm and the FiraCode Nerd Font with winget, then places the
  tracked wezterm.lua. The Linux tools (kitty, mise, nvim, theme) live inside
  WSL; run bootstrap.sh there. This script only does the Windows-native parts.

.PARAMETER SkipFont
  Do not install the font (use if it is already present).

.EXAMPLE
  pwsh -ExecutionPolicy Bypass -File scripts\windows\setup.ps1
#>

[CmdletBinding()]
param(
    [switch]$SkipFont
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Repo root is two levels up from this script (scripts\windows\).
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')

function Write-Step { param($Msg) Write-Host "==> $Msg" -ForegroundColor Cyan }
function Write-Ok   { param($Msg) Write-Host "  OK $Msg" -ForegroundColor Green }
function Write-Warn { param($Msg) Write-Host "  !  $Msg" -ForegroundColor Yellow }

# Install one winget package if it is not already present.
function Install-WingetPackage {
    param([string]$Id, [string]$Name)

    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw 'winget not found. Install "App Installer" from the Microsoft Store, then re-run.'
    }
    $installed = winget list --id $Id --exact 2>$null | Select-String $Id
    if ($installed) {
        Write-Ok "$Name already installed"
        return
    }
    Write-Step "Installing $Name"
    winget install --id $Id --exact --silent `
        --accept-package-agreements --accept-source-agreements
    Write-Ok "$Name installed"
}

# 1. WezTerm (native Windows terminal).
Install-WingetPackage -Id 'wez.wezterm' -Name 'WezTerm'

# 2. FiraCode Nerd Font. winget ships the Nerd Fonts collection.
if (-not $SkipFont) {
    Install-WingetPackage -Id 'DEVCOM.FiraCodeNerdFont' -Name 'FiraCode Nerd Font'
}
else {
    Write-Warn 'Skipping font install (-SkipFont)'
}

# 3. Place wezterm.lua at %USERPROFILE%\.config\wezterm\wezterm.lua.
Write-Step 'Installing wezterm.lua'
$WeztermDir = Join-Path $env:USERPROFILE '.config\wezterm'
New-Item -ItemType Directory -Force -Path $WeztermDir | Out-Null
$Src = Join-Path $RepoRoot 'modern\wezterm\wezterm.lua'
Copy-Item -Path $Src -Destination (Join-Path $WeztermDir 'wezterm.lua') -Force
Write-Ok "wezterm.lua -> $WeztermDir"

# 4. Remind about the WSL side.
Write-Step 'Done.'
Write-Warn 'The Linux tools run inside WSL. In your distro, run:'
Write-Warn '  wsl --update   (from Windows, for a current WSLg)'
Write-Warn '  ./bootstrap.sh (inside the repo in WSL) to set up kitty, mise, nvim, and the theme'
Write-Warn 'Start WezTerm; it opens the WSL:Ubuntu domain by default.'
