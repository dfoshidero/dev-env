# Configure Windows Terminal to use JetBrains Mono Nerd Font and, when SchemesDir
# is given, the Catppuccin colour schemes (Latte for light mode, Mocha for dark).
param(
    [string]$FontFace = "JetBrainsMono Nerd Font",
    [int]$FontSize = 11,
    [string]$SchemesDir = "",
    [string]$LightScheme = "Catppuccin Latte",
    [string]$DarkScheme = "Catppuccin Mocha"
)

$ErrorActionPreference = "Stop"

$paths = @(
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json",
    "$env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json"
)

if ($SchemesDir -and -not (Test-Path -LiteralPath $SchemesDir)) {
    Write-Error "Colour scheme directory not found: $SchemesDir"
    exit 1
}

function Set-ProfileFont {
    param($Target)

    if ($null -eq $Target) { return }

    if ($null -eq $Target.font) {
        $Target | Add-Member -NotePropertyName font -NotePropertyValue ([PSCustomObject]@{
            face = $FontFace
            size = $FontSize
        })
        return
    }

    $Target.font | Add-Member -NotePropertyName face -NotePropertyValue $FontFace -Force
    if ($null -eq $Target.font.PSObject.Properties['size']) {
        $Target.font | Add-Member -NotePropertyName size -NotePropertyValue $FontSize
    }
}

function Set-ColorSchemes {
    param($Settings)

    $schemes = @(Get-ChildItem -LiteralPath $SchemesDir -Filter *.json | Sort-Object Name | ForEach-Object {
        Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
    })
    $names = @($schemes | ForEach-Object { $_.name })

    # Replace older copies of these schemes, keep every other scheme.
    $kept = @()
    if ($null -ne $Settings.PSObject.Properties['schemes']) {
        $kept = @($Settings.schemes | Where-Object { $names -notcontains $_.name })
    }
    $Settings | Add-Member -NotePropertyName schemes -NotePropertyValue @($kept + $schemes) -Force

    if ($null -eq $Settings.profiles.defaults) {
        $Settings.profiles | Add-Member -NotePropertyName defaults -NotePropertyValue ([PSCustomObject]@{}) -Force
    }
    $Settings.profiles.defaults | Add-Member -NotePropertyName colorScheme -NotePropertyValue ([PSCustomObject]@{
        light = $LightScheme
        dark  = $DarkScheme
    }) -Force

    # The light/dark scheme follows the app theme; "system" makes that follow Windows.
    if ($null -eq $Settings.PSObject.Properties['theme']) {
        $Settings | Add-Member -NotePropertyName theme -NotePropertyValue "system"
    }
}

$updated = $false

foreach ($path in $paths) {
    if (-not (Test-Path -LiteralPath $path)) { continue }

    try {
        $json = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($SchemesDir) { Set-ColorSchemes -Settings $json }
        Set-ProfileFont -Target $json.profiles.defaults

        foreach ($entry in $json.profiles.list) {
            if ($entry.PSObject.Properties.Match("hidden").Count -gt 0 -and $entry.hidden -eq $true) {
                continue
            }
            Set-ProfileFont -Target $entry
        }

        $json | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $path -Encoding UTF8
        Write-Output "Updated Windows Terminal settings: $path"
        $updated = $true
    }
    catch {
        Write-Warning "Failed to update $path : $_"
        exit 1
    }
}

if (-not $updated) {
    Write-Warning "Windows Terminal settings.json not found"
    exit 1
}
