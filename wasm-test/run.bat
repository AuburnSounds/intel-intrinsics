dub build -b testing -a wasm32-wasi --compiler ldc2 -f
wasmtime wasm-test.wasm
