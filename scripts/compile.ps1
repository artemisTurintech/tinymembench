Set-Location "$PSScriptRoot\.."

if (-not (Get-Command gcc -ErrorAction SilentlyContinue)) {
    Write-Host "gcc not found - installing via scoop..."
    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
        Write-Host "scoop not found - installing scoop..."
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
        if (-not $?) { Write-Error "scoop install failed"; exit 1 }
    }
    scoop install gcc
    if (-not $?) { Write-Error "gcc install failed"; exit 1 }
}

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
