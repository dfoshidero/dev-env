# Configure Windows Terminal to use MesloLGS NF (Powerlevel10k recommended font).
param(
    [string]$FontFace = "MesloLGS NF",
    [int]$FontSize = 11
)

$ErrorActionPreference = "Stop"

$paths = @(
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json",
    "$env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json"
)

function Set-ProfileFont {
    param($Profile)

    if ($null -eq $Profile) { return }

    if ($null -eq $Profile.font) {
        $Profile | Add-Member -MemberType NoteProperty -Name font -Value ([PSCustomObject]@{
            face = $FontFace
            size = $FontSize
        })
        return
    }

    $Profile.font | Add-Member -MemberType NoteProperty -Name face -NotePropertyValue $FontFace -Force
    if ($null -eq $Profile.font.PSObject.Properties['size']) {
        $Profile.font | Add-Member -MemberType NoteProperty -Name size -NotePropertyValue $FontSize
    }
}

$updated = $false

foreach ($path in $paths) {
    if (-not (Test-Path -LiteralPath $path)) { continue }

    try {
        $json = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
        Set-ProfileFont -Profile $json.profiles.defaults

        foreach ($profile in $json.profiles.list) {
            if ($profile.PSObject.Properties.Match("hidden").Count -gt 0 -and $profile.hidden -eq $true) {
                continue
            }
            Set-ProfileFont -Profile $profile
        }

        $json | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $path -Encoding UTF8
        Write-Output "Updated Windows Terminal font: $path"
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
