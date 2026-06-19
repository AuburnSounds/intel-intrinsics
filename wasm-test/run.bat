dub build -b testing -a wasm32-wasi --compiler ldc2 -f --combined
wasmtime wasm-test.wasm
