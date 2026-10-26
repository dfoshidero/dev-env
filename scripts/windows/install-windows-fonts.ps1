# Install every .ttf in FontsDir into the current Windows user font store, register it,
# then check Windows can resolve FamilyName. Safe to re-run: it repairs bad registry entries.
param(
    [Parameter(Mandatory = $true)]
    [string]$FontsDir,
    [string]$FamilyName = "JetBrainsMono Nerd Font",
    # Overrides for tests.
    [string]$FontStore = (Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts"),
    [string]$RegistryPath = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts",
    [switch]$SkipCheck
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $FontsDir)) {
    Write-Error "Font directory not found: $FontsDir"
    exit 1
}

$fontFiles = @(Get-ChildItem -LiteralPath $FontsDir -Filter *.ttf)
if ($fontFiles.Count -eq 0) {
    Write-Error "No .ttf files found in $FontsDir"
    exit 1
}

New-Item -ItemType Directory -Force -Path $FontStore | Out-Null
if (-not (Test-Path -LiteralPath $RegistryPath)) {
    New-Item -Path $RegistryPath -Force | Out-Null
}

Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class DevEnvGdi {
  [DllImport("gdi32.dll", CharSet = CharSet.Unicode)]
  public static extern int AddFontResourceW(string fileName);
}
"@

$changed = 0
foreach ($font in $fontFiles) {
    $dest = Join-Path $FontStore $font.Name
    $regName = "$($font.BaseName) (TrueType)"

    $copied = $false
    if (-not (Test-Path -LiteralPath $dest) -or
        (Get-FileHash -LiteralPath $dest).Hash -ne (Get-FileHash -LiteralPath $font.FullName).Hash) {
        Copy-Item -LiteralPath $font.FullName -Destination $dest -Force
        $copied = $true
    }

    # Per-user fonts must be registered by full path; a bare file name is looked up in C:\Windows\Fonts.
    $current = (Get-ItemProperty -LiteralPath $RegistryPath -Name $regName -ErrorAction SilentlyContinue).$regName
    $registered = $false
    if ($current -ne $dest) {
        New-ItemProperty -LiteralPath $RegistryPath -Name $regName -Value $dest -PropertyType String -Force | Out-Null
        $registered = $true
    }

    if ($copied -or $registered) {
        # Load it into this logon session too, as oh-my-posh does. Best effort: the registry
        # entry alone makes the font available to newly started apps.
        if ([DevEnvGdi]::AddFontResourceW($dest) -eq 0) {
            Write-Warning "Could not load $($font.Name) into this session; it will load at next sign-in"
        }
        $changed++
        Write-Output "Installed $($font.BaseName)"
    }
}

if ($changed -eq 0) {
    Write-Output "All $($fontFiles.Count) fonts already installed and registered"
}
else {
    # Apps read the font list once at startup; reopening a window is not enough.
    $running = @(Get-Process -Name Code, Cursor, WindowsTerminal -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty Name -Unique)
    if ($running.Count -gt 0) {
        Write-Warning ("Fully quit and restart these apps to see the new font (check Task Manager): " +
            ($running -join ", "))
    }
}

if (-not $SkipCheck) {
    & (Join-Path $PSScriptRoot "check-windows-font.ps1") -FamilyName $FamilyName
    exit $LASTEXITCODE
}
