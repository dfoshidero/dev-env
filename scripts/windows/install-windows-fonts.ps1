# Install every .ttf in FontsDir into the current Windows user font store and register it for GDI.
param(
    [Parameter(Mandatory = $true)]
    [string]$FontsDir
)

$ErrorActionPreference = "Stop"

$userFonts = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts"
$regPath = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"

if (-not (Test-Path -LiteralPath $FontsDir)) {
    Write-Error "Font directory not found: $FontsDir"
    exit 1
}

New-Item -ItemType Directory -Force -Path $userFonts | Out-Null

$fontFiles = @(Get-ChildItem -LiteralPath $FontsDir -Filter *.ttf | ForEach-Object { $_.Name })
if ($fontFiles.Count -eq 0) {
    Write-Error "No .ttf files found in $FontsDir"
    exit 1
}

foreach ($file in $fontFiles) {
    $src = Join-Path $FontsDir $file
    $dest = Join-Path $userFonts $file
    Copy-Item -LiteralPath $src -Destination $dest -Force

    $fontTitle = [System.IO.Path]::GetFileNameWithoutExtension($file)
    $regName = "$fontTitle (TrueType)"
    New-ItemProperty -Path $regPath -Name $regName -Value $file -PropertyType String -Force | Out-Null
    Write-Output "Installed $fontTitle"
}

# Tell running apps (including Windows Terminal) to reload the font cache.
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class DevEnvFontNotify {
  [DllImport("user32.dll", CharSet = CharSet.Auto)]
  public static extern IntPtr SendMessageTimeout(
    IntPtr hWnd, int Msg, IntPtr wParam, string lParam,
    int fuFlags, int uTimeout, out IntPtr lpdwResult);
}
"@

$null = [DevEnvFontNotify]::SendMessageTimeout(
    [IntPtr]0xffff, 0x001D, [IntPtr]::Zero, $null, 0, 1000, [ref]([IntPtr]::Zero))
