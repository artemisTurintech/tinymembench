param(
    [int]$Runs = 1
)

Set-Location "$PSScriptRoot\.."

for ($i = 1; $i -le $Runs; $i++) {
    if ($Runs -gt 1) { Write-Host "--- Run $i of $Runs ---" }
    .\tinymembench.exe
    if (-not $?) { exit 1 }
}
