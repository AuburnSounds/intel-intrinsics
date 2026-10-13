dub test --compiler dmd -a x86 -f
dub test --compiler dmd -a x86_64 -f
dub test --compiler ldc2 -a x86 -f
dub test --compiler ldc2 -a x86_64 -f
dub test --compiler dmd -a x86 -b unittest-inst -f
dub test --compiler dmd -a x86_64 -b unittest-inst -f
REM Disabled: -mcpu=native enables AVX/BMI, which trap in 32-bit x86 emulation on Windows ARM64
REM dub test --compiler ldc2 -a x86 -b unittest-inst -f
dub test --compiler ldc2 -a x86_64 -b unittest-inst -f
dub test --compiler ldc2 -a x86 -b unittest-below-avx -f
dub test --compiler ldc2 -a x86_64 -b unittest-below-avx -f
dub test --compiler dmd -a x86 -b unittest-release -f
dub test --compiler dmd -a x86_64 -b unittest-release -f 
dub test --compiler ldc2 -a x86 -b unittest-release -f
dub test --compiler ldc2 -a x86_64 -b unittest-release -f
dub test --compiler dmd -a x86 -b unittest-release-inst -f
dub test --compiler dmd -a x86_64 -b unittest-release-inst -f
REM Disabled: same as above
REM dub test --compiler ldc2 -a x86 -b unittest-release-inst -f
dub test --compiler ldc2 -a x86_64 -b unittest-release-inst -f