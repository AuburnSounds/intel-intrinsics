Advice:

- Correctness with original semantics. Historically contributions to this repositery give tons of work to the maintainer because of insufficient reading of this document and general lack of care for correctness.
  * If your work is not high-quality it will be auto-closed, because fixing it may take more time than creating it.
  * Follow the rules here that stem from experience implementing SIMD intrinsics, a library that shall be very reliable.

Here are the source for semantics:
  - Intel Intrinsics Guide
  - When the guide and the instruction disagree, we look at what C++ compilers do 
    for this intrinsic.

- **GODBOLT EVERYTHING YOU COMMIT**
  * Use `godbolt-template.d` and modify to your wished
  * GDC (version 12 or later) with -mavx -mavx2 (the template doesn't build without -mavx)
  * LDC (version 1.24+ or later) with -mtriple arm64, -O2, -O0, -mattr=+avx2, etc. 

- Do not add AVX-512 or AVX-10 intrinsics, they are out of scope.

- I implore you to do intrinsics **one by one**, not all at once. This is **very** detailed work, it's not possible nor desirable to go fast while writing intrinsics. 
   * Please don't go fast. 
   * Please make small PR because there is a lot of context to communicate.
   * Get pre-approval before working on something big.
   * If you're a first time contributor, PR with only one intrinsic.

- Add PERF comment anywhere you feel that something could be done faster in a supported combination: DMD D_SIMD, LDC x86_64, LDC arm64, LDC x86, GDC x86_64, with or without optimizations, with or without instruction support... 
  * If this is supposed returns a SIMD literal, does it inline?
  * Can this be faster in -O0?
  * If instruction support is not there, is the alternative path fast?

- Later instruction set are allowed to use intrinsics from <= instruction sets.

- Keep in mind all intrinsics should work, whatever the compiler and flags, with same semantics. This is the main appeal of the library.


To be merged a PR:

- need one unittest per intrinsic
- need a slow path that works on all compilers
- fast paths (actual intrinsics) can be added later, but is probably your real interest
- intrinsic order should be like in the Intrinsics Guide page: https://software.intel.com/sites/landingpage/IntrinsicsGuide/#othertechs=SHA
- add yourself to the Copyright list

Your PR doesn't have to implement every intrinsic in a given instruction set. It's best to do one intrinsics right, than several half-done, giving work to the maintainer.