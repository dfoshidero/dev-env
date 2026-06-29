# Install MesloLGS NF into the current Windows user font store and register for GDI.
param(
    [Parameter(Mandatory = $true)]
    [string]$FontsDir
)

$ErrorActionPreference = "Stop"

$fontFiles = @(
    "MesloLGS NF Regular.ttf",
    "MesloLGS NF Bold.ttf",
    "MesloLGS NF Italic.ttf",
    "MesloLGS NF Bold Italic.ttf"
)

$userFonts = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts"
$regPath = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"

if (-not (Test-Path -LiteralPath $FontsDir)) {
    Write-Error "Font directory not found: $FontsDir"
    exit 1
}

New-Item -ItemType Directory -Force -Path $userFonts | Out-Null

foreach ($file in $fontFiles) {
    $src = Join-Path $FontsDir $file
    if (-not (Test-Path -LiteralPath $src)) {
        Write-Warning "Missing font file: $src"
        continue
    }

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
