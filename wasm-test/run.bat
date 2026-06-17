dub build -b testing -a wasm32-wasi --compiler ldc2
wasmtime wasm-test.was
