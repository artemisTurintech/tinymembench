param(
    [int]$Runs = 1
)

Set-Location "$PSScriptRoot\.."

if (-not (Test-Path ".\tinymembench.exe")) {
    Write-Error "tinymembench.exe not found - run scripts\compile.ps1 first"
    exit 1
}

for ($i = 1; $i -le $Runs; $i++) {
    if ($Runs -gt 1) { Write-Host "--- Run $i of $Runs ---" }
    .\tinymembench.exe
    if (-not $?) { exit 1 }
}
