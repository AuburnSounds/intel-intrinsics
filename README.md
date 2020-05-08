
# intel-intrinsics

[![Travis Status](https://travis-ci.org/AuburnSounds/intel-intrinsics.svg?branch=master)](https://travis-ci.org/AuburnSounds/intel-intrinsics)

The DUB package `intel-intrinsics` implements Intel intrinsics for D.

`intel-intrinsics` lets you use x86 SIMD in D with support for LDC / DMD / GDC with a single syntax and API.

```json
"dependencies":
{
    "intel-intrinsics": "~>1.0"
}
```

## Features

### SIMD intrinsics with `_mm_` prefix

|       | DMD          | LDC                    | GDC                  |
|-------|--------------|------------------------|----------------------|
| MMX   | Yes but slow ([#16](https://github.com/AuburnSounds/intel-intrinsics/issues/16)) | Yes                    | Yes (slow in 32-bit) |
| SSE   | Yes but slow  ([#16](https://github.com/AuburnSounds/intel-intrinsics/issues/16)) | Yes                    | Yes (slow in 32-bit) |
| SSE2  | Yes but slow  ([#16](https://github.com/AuburnSounds/intel-intrinsics/issues/16)) | Yes                    | Yes (slow in 32-bit) |
| SSE3  | Yes but slow  ([#16](https://github.com/AuburnSounds/intel-intrinsics/issues/16)) | Yes (use -mattr=+sse3) | Yes but slow ([#39](https://github.com/AuburnSounds/intel-intrinsics/issues/39))  |
| SSSE3 | No           | No                     | No                   |
| ...   | No           | No                     | No                   |

The intrinsics implemented follow the syntax and semantics at: https://software.intel.com/sites/landingpage/IntrinsicsGuide/

The philosophy (and guarantee) of `intel-intrinsics` is:
 - When using LDC, `intel-intrinsics` should generate optimal code else it's a bug.
 - **No promise that the exact instruction is generated**, because it's not always the fastest thing to do.
 - Guarantee that the **semantics** of the intrinsic is preserved, above all other consideration.

### SIMD types

`intel-intrinsics` define the following types whatever the compiler:

`long1`, `float2`, `int2`, `short4`, `byte8`, `float4`, `int4`, `double2`

though most of the time you would deal with
```d
alias __m128 = float4; 
alias __m128i = int4; // and you can rely on __m128i being int4
alias __m128d = double2;
alias __m64 = long1;
```

### Vector Operators for all

`intel-intrinsics` implements Vector Operators for compilers that don't have `__vector` support (DMD with 32-bit x86 target).

**Example:**
```d
__m128 add_4x_floats(__m128 a, __m128 b)
{
    return a + b;
}
```
is the same as:
```d
__m128 add_4x_floats(__m128 a, __m128 b)
{
    return _mm_add_ps(a, b);
}
```

[See available operators...](https://dlang.org/spec/simd.html#vector_op_intrinsics)


### Individual element access

It is recommended to do it in that way for maximum portability:
```d
__m128i A;

// recommended portable way to set a single SIMD element
A.ptr[0] = 42; 

// recommended portable way to get a single SIMD element
int elem = A.array[0];
```

## Why `intel-intrinsics`?

- **Portability** 
  It just works the same for DMD, LDC, and GDC.

- **Capabilities**
  Some instructions just aren't accessible using `core.simd` and `ldc.simd` capabilities. For example: `pmaddwd` which is so important in digital video. Some instructions need an almost exact sequence of LLVM IR to get generated. `ldc.intrinsics` is a moving target and you need a layer on top of it.
  
- **Familiarity**
  Intel intrinsic syntax is more familiar to C and C++ programmers. 
The Intel intrinsics names  aren't good, but they are known identifiers.
The problem with introducing new names is that you need hundreds of new identifiers.

- **Documentation**
There is a convenient online guide provided by Intel:
https://software.intel.com/sites/landingpage/IntrinsicsGuide/
Without this Intel documentation, it's much more difficult to write sizeable SIMD code.





### Notable difference vs C/C++ or `core.simd`

When using `intel-intrinsics`, every implicit conversion of similarly-sized vectors should be done with a `cast` instead.

```d
__m128i b = _mm_set1_epi32(42);
__m128 a = b;             // NO, only works in LDC
__m128 a = cast(__m128)b; // YES, works in all D compilers

```

This is because D does not allow user-defined implicit conversions, and `core.simd` might be emulated (DMD). Use this `cast`, or your code won't work in every D compiler variation.


### Who is using it?

- `dg2d` is a very fast [2D renderer](https://github.com/cerjones/dg2d)
- [Auburn Sounds](https://www.auburnsounds.com/) audio products
- [Cut Through Recordings](https://www.cutthroughrecordings.com/) audio products


### Video introduction

In this DConf 2019 talk, Auburn Sounds:
- introduces how `intel-intrinsics`came to be, 
- demonstrates a 3.5x speed-up for some particular loops,
- reminds that normal D code can be really fast and intrinsics might harm performance

[See the talk: intel-intrinsics: Not intrinsically about intrinsics](https://www.youtube.com/watch?v=cmswsx1_BUQ)
