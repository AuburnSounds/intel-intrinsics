/**
* AVX intrinsics.
* https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#techs=AVX
*
* Copyright: Guillaume Piolat 2022.
*            Johan Engelen 2022.
* License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module inteli.avxintrin;

// AVX instructions
// https://software.intel.com/sites/landingpage/IntrinsicsGuide/#techs=AVX
// Note: this header will work whether you have AVX enabled or not.
// With LDC, use "dflags-ldc": ["-mattr=+avx"] or equivalent to actively
// generate AVX instructions.

public import inteli.types;
import inteli.internals;

// Pull in all previous instruction set intrinsics.
public import inteli.tmmintrin;

nothrow @nogc:

/// Extract a 32-bit integer from `a`, selected with `imm8`.
int _mm256_extract_epi32 (__m256i a, const int imm8) pure @trusted
{
    return (cast(int8)a).array[imm8 & 7];
}
unittest
{
    align(16) int[8] data = [-1, 2, -3, 4, 9, -7, 8, -6];
    auto A = _mm256_loadu_si256(cast(__m256i*) data.ptr);
    assert(_mm256_extract_epi32(A, 0) == -1);
    assert(_mm256_extract_epi32(A, 1 + 8) == 2);
    assert(_mm256_extract_epi32(A, 3 + 16) == 4);
    assert(_mm256_extract_epi32(A, 7 + 32) == -6);
}

/// Load 128-bits of integer data from memory. `mem_addr` does not need to be aligned on any particular boundary.
__m256i _mm256_loadu_si256 (const(__m256i)* mem_addr) pure @trusted
{
    pragma(inline, true);
    static if (GDC_with_AVX)
    {
        return cast(__m256i) __builtin_ia32_loaddqu256(cast(const(char*))mem_addr);
    }
    else
    {
        return loadUnaligned!(__m256i)(cast(int*)mem_addr);
    }
}
unittest
{
    align(16) int[8] correct = [-1, 2, -3, 4, 9, -7, 8, -6];
    int8 A = cast(int8) _mm256_loadu_si256(cast(__m256i*) correct.ptr);
    assert(A.array == correct);
}

/// Broadcast 8-bit integer `a` to all elements of the return value.
__m256i _mm256_set1_epi8 (byte a) pure @trusted
{
    version(DigitalMars) // workaround https://issues.dlang.org/show_bug.cgi?id=21469
    {
        byte32 v = a;
        return cast(__m256i) v;
    }
    else
    {
        pragma(inline, true);
        return cast(__m256i)(byte32(a));
    }
}
unittest
{
    byte32 a = cast(byte32) _mm256_set1_epi8(31);
    for (int i = 0; i < 32; ++i)
        assert(a.array[i] == 31);
}

/// Broadcast 16-bit integer `a` to all elements of the return value.
__m256i _mm256_set1_epi16 (short a) pure @trusted
{
    version(DigitalMars) // workaround https://issues.dlang.org/show_bug.cgi?id=21469
    {
        short16 v = a;
        return cast(__m256i) v;
    }
    else
    {
        pragma(inline, true);
        return cast(__m256i)(short16(a));
    }
}
unittest
{
    short16 a = cast(short16) _mm256_set1_epi16(31);
    for (int i = 0; i < 16; ++i)
        assert(a.array[i] == 31);
}

/// Broadcast 32-bit integer `a` to all elements.
__m256i _mm256_set1_epi32 (int a) pure @trusted
{
    pragma(inline, true);
    return cast(__m256i)(int8(a));
}
unittest
{
    int8 a = cast(int8) _mm256_set1_epi32(31);
    for (int i = 0; i < 8; ++i)
        assert(a.array[i] == 31);
}

/// Set packed 8-bit integers with the supplied values in reverse order.
__m256i _mm256_setr_epi8 (byte e31, byte e30, byte e29, byte e28, byte e27, byte e26, byte e25, byte e24,
                          byte e23, byte e22, byte e21, byte e20, byte e19, byte e18, byte e17, byte e16,
                          byte e15, byte e14, byte e13, byte e12, byte e11, byte e10, byte e9,  byte e8,
                          byte e7,  byte e6,  byte e5,  byte e4,  byte e3,  byte e2,  byte e1,  byte e0) pure @trusted
{
    pragma(inline, true);
    byte[32] result = [ e31,  e30,  e29,  e28,  e27,  e26,  e25,  e24,
                        e23,  e22,  e21,  e20,  e19,  e18,  e17,  e16,
                        e15,  e14,  e13,  e12,  e11,  e10,  e9,   e8,
                        e7,   e6,   e5,   e4,   e3,   e2,   e1,   e0];
    return cast(__m256i)( loadUnaligned!(byte32)(result.ptr) );
}
unittest
{
    byte32 A = cast(byte32) _mm256_setr_epi8( -1, 0, -21, 21, 42, 127, -42, -128,
                                              -1, 0, -21, 21, 42, 127, -42, -128,
                                              -1, 0, -21, 21, 42, 127, -42, -128,
                                              -1, 0, -21, 21, 42, 127, -42, -128);
    byte[32] correct = [-1, 0, -21, 21, 42, 127, -42, -128,
                        -1, 0, -21, 21, 42, 127, -42, -128,
                        -1, 0, -21, 21, 42, 127, -42, -128,
                        -1, 0, -21, 21, 42, 127, -42, -128];
    assert(A.array == correct);
}

/// Set packed 32-bit integers with the supplied values in reverse order.
__m256i _mm256_setr_epi32 (int e7, int e6, int e5, int e4, int e3, int e2, int e1, int e0) pure @trusted
{
    pragma(inline, true);
    int[8] result = [e7, e6, e5, e4, e3, e2, e1, e0];
    return cast(__m256i)( loadUnaligned!(int8)(result.ptr) );
}
unittest
{
    int8 A = cast(int8) _mm256_setr_epi32(-1, 0, -2147483648, 2147483647, 42, 666, -42, -666);
    int[8] correct = [-1, 0, -2147483648, 2147483647, 42, 666, -42, -666];
    assert(A.array == correct);
}


/// Return vector of type `__m256i` with all elements set to zero.
__m256i _mm256_setzero_si256() pure @trusted
{
    pragma(inline, true);
    // Note: using loadUnaligned has better -O0 codegen compared to .ptr
    int[8] result = [0, 0, 0, 0, 0, 0, 0, 0];
    return cast(__m256i)( loadUnaligned!(int8)(result.ptr) );
}
