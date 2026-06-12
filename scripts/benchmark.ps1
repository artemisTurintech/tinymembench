param(
    [int]$Runs = 1
)

Set-Location "$PSScriptRoot\.."

if (-not (Test-Path ".\tinymembench.exe")) {
    Write-Host "tinymembench.exe not found - running compile.ps1..."
    & "$PSScriptRoot\compile.ps1"
    if (-not $?) { exit 1 }
}

for ($i = 1; $i -le $Runs; $i++) {
    if ($Runs -gt 1) { Write-Host "--- Run $i of $Runs ---" }
    .\tinymembench.exe
    if (-not $?) { exit 1 }
}
