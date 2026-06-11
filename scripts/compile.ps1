Set-Location "$PSScriptRoot\.."

# --- Prerequisites --------------------------------------------------------
# Required: gcc (includes assembler and linker via MinGW)
# Installed via scoop (https://scoop.sh) if missing

function Refresh-Path {
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("PATH", "User")
    # Also ensure scoop shims are present in case they are not yet in the registry
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

# --- Compile --------------------------------------------------------------

gcc -O2 -c util.c -o util.o
if (-not $?) { exit 1 }
gcc -O2 -c asm-opt.c -o asm-opt.o
if (-not $?) { exit 1 }
gcc -O2 -c x86-sse2.S -o x86-sse2.o
if (-not $?) { exit 1 }
gcc -O2 -c arm-neon.S -o arm-neon.o
if (-not $?) { exit 1 }
gcc -O2 -c aarch64-asm.S -o aarch64-asm.o
if (-not $?) { exit 1 }
gcc -O2 -c mips-32.S -o mips-32.o
if (-not $?) { exit 1 }
gcc -O2 -o tinymembench.exe main.c util.o asm-opt.o x86-sse2.o arm-neon.o mips-32.o aarch64-asm.o -lm
if (-not $?) { exit 1 }
Write-Host "compile OK"
