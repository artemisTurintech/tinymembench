Set-Location "$PSScriptRoot\.."
gcc -O2 -DMAXREPEATS=2 -DLATBENCH_COUNT=10000 -c util.c -o util.o
if (-not $?) { exit 1 }
gcc -O2 -DMAXREPEATS=2 -DLATBENCH_COUNT=10000 -c asm-opt.c -o asm-opt.o
if (-not $?) { exit 1 }
gcc -O2 -DMAXREPEATS=2 -DLATBENCH_COUNT=10000 -o tinymembench.exe main.c util.o asm-opt.o x86-sse2.o arm-neon.o mips-32.o aarch64-asm.o -lm
if (-not $?) { exit 1 }
.\tinymembench.exe
