# Tests for install-windows-fonts.ps1 and check-windows-font.ps1. Needs real Windows
# (run from WSL via powershell.exe); uses a scratch font store and registry key, so the
# user's fonts are never touched.
$ErrorActionPreference = "Stop"

$repo = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$install = Join-Path $repo "scripts\windows\install-windows-fonts.ps1"
$check = Join-Path $repo "scripts\windows\check-windows-font.ps1"
$ps = (Get-Process -Id $PID).Path
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

$root = Join-Path ([System.IO.Path]::GetTempPath()) ("dev-env-fonts-" + [guid]::NewGuid())
$src = Join-Path $root "src"
$store = Join-Path $root "store"
$regPath = "HKCU:\Software\dev-env-tests\" + [guid]::NewGuid()
New-Item -ItemType Directory -Force -Path $src | Out-Null
"fake regular" | Set-Content -LiteralPath (Join-Path $src "TestFont-Regular.ttf")
"fake bold" | Set-Content -LiteralPath (Join-Path $src "TestFont-Bold.ttf")

# Windows PowerShell turns a child's stderr into a terminating error under "Stop".
function Invoke-Script {
    param([string]$Path, [string[]]$Arguments)
    $ErrorActionPreference = "Continue"
    $out = & $ps -NoProfile -ExecutionPolicy Bypass -File $Path @Arguments 3>&1 2>&1 | Out-String
    return @{ Code = $LASTEXITCODE; Output = $out }
}

function Invoke-Install {
    Invoke-Script $install @("-FontsDir", $src, "-FontStore", $store, "-RegistryPath", $regPath, "-SkipCheck")
}

function Get-Registered {
    param([string]$Name)
    (Get-ItemProperty -LiteralPath $regPath -Name $Name -ErrorAction SilentlyContinue).$Name
}

try {
    Write-Output "Install"
    $r = Invoke-Install
    $regular = Join-Path $store "TestFont-Regular.ttf"
    Assert-True ($r.Code -eq 0) "exits 0"
    Assert-True (Test-Path -LiteralPath $regular) "font copied to the store"
    Assert-True ((Get-Registered "TestFont-Regular (TrueType)") -eq $regular) "registered by full path"
    Assert-True ((Get-Registered "TestFont-Bold (TrueType)") -eq (Join-Path $store "TestFont-Bold.ttf")) "every font registered"

    Write-Output "Re-run"
    $r = Invoke-Install
    Assert-True ($r.Code -eq 0 -and $r.Output -match "already installed") "second run changes nothing"

    Write-Output "Repair"
    # The old installer wrote only the file name, which Windows looks up in C:\Windows\Fonts.
    New-ItemProperty -LiteralPath $regPath -Name "TestFont-Regular (TrueType)" -Value "TestFont-Regular.ttf" -PropertyType String -Force | Out-Null
    $r = Invoke-Install
    Assert-True ((Get-Registered "TestFont-Regular (TrueType)") -eq $regular) "bare file name replaced with full path"
    "changed regular" | Set-Content -LiteralPath (Join-Path $src "TestFont-Regular.ttf")
    $r = Invoke-Install
    Assert-True ((Get-Content -LiteralPath $regular -Raw) -match "changed regular") "changed font file copied again"

    Write-Output "Failures"
    $r = Invoke-Script $install @("-FontsDir", (Join-Path $root "missing"), "-FontStore", $store, "-RegistryPath", $regPath, "-SkipCheck")
    Assert-True ($r.Code -ne 0) "missing FontsDir fails"

    Write-Output "DirectWrite check"
    Assert-True ((Invoke-Script $check @("-FamilyName", "Consolas")).Code -eq 0) "finds an installed family"
    Assert-True ((Invoke-Script $check @("-FamilyName", "dev-env No Such Font")).Code -ne 0) "fails for a missing family"
}
finally {
    Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath (Split-Path -Parent $regPath) -Recurse -Force -ErrorAction SilentlyContinue
}

if ($failures -gt 0) {
    Write-Output "$failures assertion(s) failed"
    exit 1
}
Write-Output "All Windows font install assertions passed"
