# Configure Windows Terminal to use MesloLGS NF (Powerlevel10k recommended font).
param(
    [string]$FontFace = "MesloLGS NF"
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
        $Profile | Add-Member -MemberType NoteProperty -Name font -Value ([PSCustomObject]@{ face = $FontFace })
        return
    }

    $Profile.font | Add-Member -MemberType NoteProperty -Name face -NotePropertyValue $FontFace -Force
}

function Test-WslProfile {
    param($Profile)

    if ($null -eq $Profile) { return $false }
    if ($Profile.PSObject.Properties.Match("hidden").Count -gt 0 -and $Profile.hidden -eq $true) { return $false }

    if ($Profile.PSObject.Properties.Match("source").Count -gt 0 -and $Profile.source -like "*WSL*") { return $true }
    if ($Profile.PSObject.Properties.Match("commandline").Count -gt 0 -and $Profile.commandline -match "(?i)wsl|ubuntu|debian") { return $true }
    if ($Profile.PSObject.Properties.Match("name").Count -gt 0 -and $Profile.name -match "(?i)ubuntu|wsl|debian") { return $true }

    return $false
}

$updated = $false

foreach ($path in $paths) {
    if (-not (Test-Path -LiteralPath $path)) { continue }

    try {
        $json = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
        Set-ProfileFont -Profile $json.profiles.defaults

        foreach ($profile in $json.profiles.list) {
            if (Test-WslProfile -Profile $profile) {
                Set-ProfileFont -Profile $profile
            }
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
