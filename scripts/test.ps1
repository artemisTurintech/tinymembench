Set-Location "$PSScriptRoot\.."

# --- Prerequisites --------------------------------------------------------

function Refresh-Path {
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("PATH", "User")
    $scoopShims = "$env:USERPROFILE\scoop\shims"
    if ((Test-Path $scoopShims) -and ($env:PATH -notlike "*$scoopShims*")) {
        $env:PATH = "$scoopShims;$env:PATH"
    }
}

function Ensure-Scoop {
    Refresh-Path
    if (Get-Command scoop -ErrorAction SilentlyContinue) { return }
    Write-Host "scoop not found - installing scoop..."
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
    if (-not $?) { Write-Error "scoop install failed"; exit 1 }
    Refresh-Path
}

function Ensure-Package {
    param([string]$Cmd, [string]$Package)
    Refresh-Path
    if (Get-Command $Cmd -ErrorAction SilentlyContinue) { return }
    Write-Host "$Cmd not found - installing $Package via scoop..."
    Ensure-Scoop
    scoop install $Package
    if (-not $?) { Write-Error "$Package install failed"; exit 1 }
    Refresh-Path
    if (-not (Get-Command $Cmd -ErrorAction SilentlyContinue)) {
        Write-Error "$Cmd still not found after installing $Package"; exit 1
    }
}

Ensure-Package -Cmd gcc -Package gcc

# --- Test (reduced iterations for fast verification) ----------------------

gcc -O2 -DMAXREPEATS=2 -DLATBENCH_COUNT=10000 -c util.c -o util.o
if (-not $?) { exit 1 }
gcc -O2 -DMAXREPEATS=2 -DLATBENCH_COUNT=10000 -c asm-opt.c -o asm-opt.o
if (-not $?) { exit 1 }
gcc -O2 -DMAXREPEATS=2 -DLATBENCH_COUNT=10000 -o tinymembench.exe main.c util.o asm-opt.o x86-sse2.o arm-neon.o mips-32.o aarch64-asm.o -lm
if (-not $?) { exit 1 }
.\tinymembench.exe
