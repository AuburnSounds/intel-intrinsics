dub build -b testing -a wasm32-wasi --compiler ldc2 -f --combined
if errorlevel 1 goto :err
wasmtime wasm-test.wasm
:err
