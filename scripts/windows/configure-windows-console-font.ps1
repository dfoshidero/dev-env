# Set the default Windows console (conhost) font to a Nerd Font so that the
# legacy PowerShell and cmd.exe windows render Powerlevel10k / oh-my-posh glyphs
# instead of boxes / question marks. Windows Terminal is configured separately.
param(
    [string]$FontFace = "MesloLGS NF",
    [int]$FontSize = 16
)

$ErrorActionPreference = "Stop"

function Set-ConsoleFont {
    param([string]$KeyPath)

    if (-not (Test-Path -LiteralPath $KeyPath)) {
        New-Item -Path $KeyPath -Force | Out-Null
    }

    # FontFamily 54 (0x36) = TrueType; FontWeight 400 = normal.
    New-ItemProperty -LiteralPath $KeyPath -Name FaceName   -Value $FontFace -PropertyType String -Force | Out-Null
    New-ItemProperty -LiteralPath $KeyPath -Name FontFamily -Value 54        -PropertyType DWord  -Force | Out-Null
    New-ItemProperty -LiteralPath $KeyPath -Name FontWeight -Value 400       -PropertyType DWord  -Force | Out-Null

    # FontSize DWORD: high word = cell height in px, low word = width (0 = auto).
    $size = ([int]$FontSize) -shl 16
    New-ItemProperty -LiteralPath $KeyPath -Name FontSize   -Value $size     -PropertyType DWord  -Force | Out-Null
}

# Default for all new console windows.
Set-ConsoleFont -KeyPath "HKCU:\Console"
Write-Output "Set default console font -> $FontFace"

# Per-application overrides so existing saved profiles don't beat the default.
$apps = @(
    "HKCU:\Console\%SystemRoot%_System32_WindowsPowerShell_v1.0_powershell.exe",
    "HKCU:\Console\%SystemRoot%_SysWOW64_WindowsPowerShell_v1.0_powershell.exe",
    "HKCU:\Console\%SystemRoot%_System32_cmd.exe",
    "HKCU:\Console\%ProgramFiles%_PowerShell_7_pwsh.exe"
)
foreach ($app in $apps) {
    if (Test-Path -LiteralPath $app) {
        Set-ConsoleFont -KeyPath $app
        Write-Output "Updated console profile -> $app"
    }
}

# Best-effort: register the font in the console TrueType font allow-list.
# Needs admin (HKLM); modern Windows lists monospaced fonts without it, so a
# failure here is non-fatal.
try {
    $ttPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Console\TrueTypeFont"
    if (Test-Path -LiteralPath $ttPath) {
        $values = (Get-ItemProperty -LiteralPath $ttPath).PSObject.Properties
        if (-not ($values | Where-Object { $_.Value -eq $FontFace })) {
            $name = "0"
            while ($values.Name -contains $name) { $name = "0$name" }
            New-ItemProperty -LiteralPath $ttPath -Name $name -Value $FontFace -PropertyType String -Force | Out-Null
            Write-Output "Registered console TrueType font -> $FontFace"
        }
    }
}
catch {
    Write-Warning "Could not register console TrueType font (needs admin): $_"
}
