# Tests for the Windows PowerShell helpers. Runs with pwsh on any OS against a
# fixture Windows Terminal settings.json; registry and font-store changes are
# only syntax-checked.
$ErrorActionPreference = "Stop"

$repo = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$scriptsDir = Join-Path $repo "scripts/windows"
$schemesDir = Join-Path $repo "config/windows-terminal"
$configure = Join-Path $scriptsDir "configure-windows-terminal.ps1"
$pwsh = (Get-Process -Id $PID).Path
$failures = 0

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if ($Condition) {
        Write-Output "  [OK]    $Message"
    }
    else {
        Write-Output "  [FAIL]  $Message"
        $script:failures++
    }
}

function New-Fixture {
    param([string]$Json)
    $root = Join-Path ([System.IO.Path]::GetTempPath()) ("dev-env-wt-" + [guid]::NewGuid())
    $dir = Join-Path $root "Microsoft/Windows Terminal"
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $Json | Set-Content -LiteralPath (Join-Path $dir "settings.json") -Encoding UTF8
    return $root
}

function Invoke-Configure {
    param([string]$Root, [string[]]$ExtraArgs = @())
    $env:LOCALAPPDATA = $Root
    & $pwsh -NoProfile -File $configure @ExtraArgs *> $null
    return $LASTEXITCODE
}

function Read-Settings {
    param([string]$Root)
    Get-Content -LiteralPath (Join-Path $Root "Microsoft/Windows Terminal/settings.json") -Raw | ConvertFrom-Json
}

Write-Output "PowerShell syntax"
foreach ($file in Get-ChildItem -LiteralPath $scriptsDir -Filter *.ps1) {
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$null, [ref]$errors) | Out-Null
    Assert-True ($errors.Count -eq 0) "$($file.Name) parses"
}

Write-Output "Font and colour schemes"
$root = New-Fixture @'
{
  "profiles": {
    "defaults": {},
    "list": [
      { "name": "Ubuntu", "font": { "face": "MesloLGS NF", "size": 12 } },
      { "name": "PowerShell" },
      { "name": "Azure Cloud Shell", "hidden": true }
    ]
  },
  "schemes": [
    { "name": "Catppuccin Mocha", "background": "#000000" },
    { "name": "My Scheme", "background": "#123456" }
  ]
}
'@
$code = Invoke-Configure -Root $root -ExtraArgs @("-SchemesDir", $schemesDir)
Assert-True ($code -eq 0) "exits 0"
$s = Read-Settings $root
$byName = @{}
foreach ($p in $s.profiles.list) { $byName[$p.name] = $p }
Assert-True ($s.profiles.defaults.font.face -eq "JetBrainsMono Nerd Font") "defaults font face"
Assert-True ($s.profiles.defaults.font.size -eq 11) "defaults font size"
Assert-True ($byName["Ubuntu"].font.face -eq "JetBrainsMono Nerd Font") "existing profile font face replaced"
Assert-True ($byName["Ubuntu"].font.size -eq 12) "existing profile font size kept"
Assert-True ($byName["PowerShell"].font.face -eq "JetBrainsMono Nerd Font") "profile without font gets one"
Assert-True ($null -eq $byName["Azure Cloud Shell"].font) "hidden profile untouched"
Assert-True ($s.profiles.defaults.colorScheme.light -eq "Catppuccin Latte") "light scheme"
Assert-True ($s.profiles.defaults.colorScheme.dark -eq "Catppuccin Mocha") "dark scheme"
Assert-True ($s.theme -eq "system") "theme follows Windows"
$mocha = @($s.schemes | Where-Object { $_.name -eq "Catppuccin Mocha" })
Assert-True ($mocha.Count -eq 1 -and $mocha[0].background -eq "#1E1E2E") "outdated Mocha replaced, not duplicated"
Assert-True (@($s.schemes | Where-Object { $_.name -eq "Catppuccin Latte" }).Count -eq 1) "Latte added"
Assert-True (@($s.schemes | Where-Object { $_.name -eq "My Scheme" }).Count -eq 1) "other schemes kept"

$code = Invoke-Configure -Root $root -ExtraArgs @("-SchemesDir", $schemesDir)
$s = Read-Settings $root
Assert-True ($code -eq 0 -and @($s.schemes).Count -eq 3) "second run changes nothing"
Remove-Item -LiteralPath $root -Recurse -Force

Write-Output "Existing choices"
$root = New-Fixture '{ "theme": "dark", "profiles": { "list": [ { "name": "Ubuntu" } ] } }'
$code = Invoke-Configure -Root $root -ExtraArgs @("-SchemesDir", $schemesDir)
$s = Read-Settings $root
Assert-True ($code -eq 0) "exits 0 without profiles.defaults"
Assert-True ($s.theme -eq "dark") "explicit theme kept"
Assert-True ($s.profiles.defaults.colorScheme.dark -eq "Catppuccin Mocha") "defaults created for the colour scheme"
Remove-Item -LiteralPath $root -Recurse -Force

Write-Output "Font only"
$root = New-Fixture '{ "profiles": { "defaults": {}, "list": [] } }'
$code = Invoke-Configure -Root $root
$s = Read-Settings $root
Assert-True ($code -eq 0 -and $s.profiles.defaults.font.face -eq "JetBrainsMono Nerd Font") "font set without SchemesDir"
Assert-True ($null -eq $s.PSObject.Properties["schemes"]) "no schemes without SchemesDir"
Remove-Item -LiteralPath $root -Recurse -Force

Write-Output "Failures"
$root = New-Fixture '{ "profiles": { "defaults": {}, "list": [] } }'
Assert-True ((Invoke-Configure -Root $root -ExtraArgs @("-SchemesDir", (Join-Path $root "missing"))) -ne 0) "missing SchemesDir fails"
Remove-Item -LiteralPath $root -Recurse -Force
$root = Join-Path ([System.IO.Path]::GetTempPath()) ("dev-env-wt-" + [guid]::NewGuid())
Assert-True ((Invoke-Configure -Root $root) -ne 0) "missing settings.json fails"

if ($failures -gt 0) {
    Write-Output "$failures assertion(s) failed"
    exit 1
}
Write-Output "All Windows Terminal assertions passed"
