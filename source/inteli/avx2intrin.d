/**
* AVX2 intrinsics.
* https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#techs=AVX2
*
* Copyright: Guillaume Piolat 2022-2024.
*            Johan Engelen 2022.
*            cet 2024.
* License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module inteli.avx2intrin;

// AVX2 instructions
// https://software.intel.com/sites/landingpage/IntrinsicsGuide/#techs=AVX2
// Note: this header will work whether you have AVX2 enabled or not.
// With LDC, use "dflags-ldc": ["-mattr=+avx2"] or equivalent to actively
// generate AVX2 instructions.
// With GDC, use "dflags-gdc": ["-mavx2"] or equivalent to actively
// generate AVX2 instructions.


// Note: many special cases for GDC, because when suporting SIMD_COMPARISON_MASKS_32B but not having AVX2, 
// the replaced operators have terrible performance. Mostly a problem for -mavx on x86

public import inteli.types;
import inteli.internals;

// Pull in all previous instruction set intrinsics.
public import inteli.avxintrin;

nothrow @nogc:

/// Compute the absolute value of packed signed 16-bit integers in `a`.
__m256i _mm256_abs_epi16 (__m256i a) @trusted
{
    // PERF DMD
    version(LDC)
        enum split = true; // always beneficial in LDC neon, ssse3, or even sse2
    else
        enum split = GDC_with_SSSE3;

    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pabsw256(cast(short16)a);
    }
    else static if (__VERSION__ >= 2097 && LDC_with_AVX2)
    {
        // Before LDC 1.27 llvm.abs LLVM intrinsic didn't exist, and hence 
        // no good way to do abs(256-bit)
        return cast(__m256i) inteli_llvm_abs!short16(cast(short16)a, false);
    }    
    else static if (split)
    {
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i r_lo = _mm_abs_epi16(a_lo);
        __m128i r_hi = _mm_abs_epi16(a_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }    
    else
    {        
        short16 sa = cast(short16)a;
        for (int i = 0; i < 16; ++i)
        {
            short s = sa.array[i];
            sa.ptr[i] = s >= 0 ? s : cast(short)(-cast(int)(s));
        }  
        return cast(__m256i)sa;
    }
}
unittest
{
    __m256i A = _mm256_setr_epi16(0, -1, -32768, 32767, 10, -10, 1000, -1000,
                                  1, -1, -32768, 32767, 12, -13, 1000, -1040);
    short16 B = cast(short16) _mm256_abs_epi16(A);
    short[16] correct = [0, 1, -32768, 32767, 10, 10, 1000, 1000,
                         1, 1, -32768, 32767, 12, 13, 1000, 1040];
    assert(B.array == correct);
}

/// Compute the absolute value of packed signed 32-bit integers in `a`.
__m256i _mm256_abs_epi32 (__m256i a) @trusted
{
    // PERF DMD
    version(LDC)
        enum split = true; // always beneficial in LDC neon, ssse3, or even sse2
    else
        enum split = false; // GDC manages to split and use pabsd in SSSE3 without guidance

    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pabsd256(cast(int8)a);
    }
    else static if (__VERSION__ >= 2097 && LDC_with_AVX2)
    {
        // Before LDC 1.27 llvm.abs LLVM intrinsic didn't exist, and hence 
        // no good way to do abs(256-bit)
        return cast(__m256i) inteli_llvm_abs!int8(cast(int8)a, false);
    }
    else static if (split)
    {
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i r_lo = _mm_abs_epi32(a_lo);
        __m128i r_hi = _mm_abs_epi32(a_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
    else
    {
        int8 sa = cast(int8)a;
        for (int i = 0; i < 8; ++i)
        {
            int s = sa.array[i];
            sa.ptr[i] = (s >= 0 ? s : -s);
        }
        return cast(__m256i)sa;
    }
}
unittest
{
    __m256i A = _mm256_setr_epi32(0, -1, -2_147_483_648, -2_147_483_647, -1, 0, -2_147_483_648, -2_147_483_646);
    int8 B = cast(int8) _mm256_abs_epi32(A);
    int[8] correct = [0, 1, -2_147_483_648, 2_147_483_647, 1, 0, -2_147_483_648, 2_147_483_646];
    assert(B.array == correct);
}

/// Compute the absolute value of packed signed 8-bit integers in `a`.
__m256i _mm256_abs_epi8 (__m256i a) @trusted
{
    // PERF DMD
    // PERF GDC in SSSE3 to AVX doesn't use pabsb and split is catastrophic because of _mm_min_epu8
    version(LDC)
        enum split = true; // always beneficial in LDC neon, ssse3, sse2
    else
        enum split = false;

    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pabsb256(cast(ubyte32)a);
    }
    else static if (__VERSION__ >= 2097 && LDC_with_AVX2)
    {
        // Before LDC 1.27 llvm.abs LLVM intrinsic didn't exist, and hence 
        // no good way to do abs(256-bit)
        return cast(__m256i) inteli_llvm_abs!byte32(cast(byte32)a, false);
    }
    else static if (split)
    {
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i r_lo = _mm_abs_epi8(a_lo);
        __m128i r_hi = _mm_abs_epi8(a_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
    else
    {
        // Basically this loop is poison for LDC optimizer
        byte32 sa = cast(byte32)a;
        for (int i = 0; i < 32; ++i)
        {
            byte s = sa.array[i];
            sa.ptr[i] = s >= 0 ? s : cast(byte)(-cast(int)(s));
        }
        return cast(__m256i)sa;
    }
}
unittest
{
    __m256i A = _mm256_setr_epi8(0, -1, -128, -127, 127,  0,  0,  0,  0,  0, 0, 0, 0, 0, 0, 0,
                                 0, -1, -128, -126, 127, -6, -5, -4, -3, -2, 0, 1, 2, 3, 4, 5);
    byte32 B = cast(byte32) _mm256_abs_epi8(A);
    byte[32] correct =          [0,  1, -128,  127, 127,  0,  0,  0,  0,  0, 0, 0, 0, 0, 0, 0,
                                 0,  1, -128,  126, 127,  6,  5,  4,  3,  2, 0, 1, 2, 3, 4, 5];
    assert(B.array == correct);
}

/// Add packed 16-bit integers in `a` and `b`.
__m256i _mm256_add_epi16 (__m256i a, __m256i b) pure @safe
{
    pragma(inline, true);
    return cast(__m256i)(cast(short16)a + cast(short16)b);
}
unittest
{
    __m256i A = _mm256_setr_epi16( -7, -1, 0, 9, -100, 100, 234, 432, -32768, 32767, 0, -1, -20000, 0,  6, -2);
    short16 R = cast(short16) _mm256_add_epi16(A, A);
    short[16] correct         = [ -14, -2, 0, 18, -200, 200, 468, 864,     0,    -2, 0, -2,  25536, 0, 12, -4 ];
    assert(R.array == correct);
}

/// Add packed 32-bit integers in `a` and `b`.
__m256i _mm256_add_epi32(__m256i a, __m256i b) pure @safe
{
    pragma(inline, true);
    return cast(__m256i)(cast(int8)a + cast(int8)b);
}
unittest
{
    __m256i A = _mm256_setr_epi32( -7, -1, 0, 9, -100, 100, 234, 432);
    int8 R = cast(int8) _mm256_add_epi32(A, A);
    int[8] correct = [ -14, -2, 0, 18, -200, 200, 468, 864 ];
    assert(R.array == correct);
}

/// Add packed 64-bit integers in `a` and `b`.
__m256i _mm256_add_epi64 (__m256i a, __m256i b) pure @safe
{
    pragma(inline, true);
    return a + b;
}
unittest
{
    __m256i A = _mm256_setr_epi64(-1, 0x8000_0000_0000_0000, 42, -12);
    long4 R = cast(__m256i) _mm256_add_epi64(A, A);
    long[4] correct = [ -2, 0, 84, -24 ];
    assert(R.array == correct);
}

/// Add packed 8-bit integers in `a` and `b`.
__m256i _mm256_add_epi8 (__m256i a, __m256i b) pure @safe
{
    pragma(inline, true);
    return cast(__m256i)(cast(byte32)a + cast(byte32)b);
}
unittest
{
    __m256i A = _mm256_setr_epi8(4, 8, 13, -7, -1, 0, 9, 77, 4, 8, 13, -7, -1, 0, 9, 78,
                                 4, 9, 13, -7, -1, 0, 9, 77, 4, 8, 13, -7, -2, 0, 10, 78);
    byte32 R = cast(byte32) _mm256_add_epi8(A, A);
    byte[32] correct = [8, 16, 26, -14, -2, 0, 18, -102, 8, 16, 26, -14, -2, 0, 18, -100,
                        8, 18, 26, -14, -2, 0, 18, -102, 8, 16, 26, -14, -4, 0, 20, -100];
    assert(R.array == correct);
}

/// Add packed 16-bit signed integers in `a` and `b` using signed saturation.
__m256i _mm256_adds_epi16 (__m256i a, __m256i b) pure @trusted
{
    // PERF DMD
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_paddsw256(cast(short16)a, cast(short16)b);
    }
    else static if(LDC_with_saturated_intrinsics)
    {
        return cast(__m256i) inteli_llvm_adds!short16(cast(short16)a, cast(short16)b);
    }
    else
    {
        short16 r;
        short16 sa = cast(short16)a;
        short16 sb = cast(short16)b;
        foreach(i; 0..16)
            r.ptr[i] = saturateSignedIntToSignedShort(sa.array[i] + sb.array[i]);
        return cast(__m256i)r;
    }
}
unittest
{
    short16 res = cast(short16) _mm256_adds_epi16(_mm256_setr_epi16( 7,  6,  5, -32768, 3, 3, 32767,   0,  7,  6,  5, -32768, 3, 3, 32767,   0),
                                                  _mm256_setr_epi16( 7,  6,  5, -30000, 3, 1,     1, -10,  7,  6,  5, -30000, 3, 1,     1, -10));
    static immutable short[16] correctResult                    =  [14, 12, 10, -32768, 6, 4, 32767, -10, 14, 12, 10, -32768, 6, 4, 32767, -10];
    assert(res.array == correctResult);
}

/// Add packed 8-bit signed integers in `a` and `b` using signed saturation.
__m256i _mm256_adds_epi8 (__m256i a, __m256i b) pure @trusted
{
    // PERF DMD
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_paddsb256(cast(ubyte32)a, cast(ubyte32)b);
    }
    else static if(LDC_with_saturated_intrinsics)
    {
        return cast(__m256i) inteli_llvm_adds!byte32(cast(byte32)a, cast(byte32)b);
    }
    else
    {
        byte32 r;
        byte32 sa = cast(byte32)a;
        byte32 sb = cast(byte32)b;
        foreach(i; 0..32)
            r.ptr[i] = saturateSignedWordToSignedByte(sa.array[i] + sb.array[i]);
        return cast(__m256i)r;
    }
}
unittest
{
    byte32 res = cast(byte32) _mm256_adds_epi8(_mm256_setr_epi8(15, 14, 13, 12, 11, 127, 9, 8, 7, 6, 5, -128, 3, 2, 1, 0, 15, 14, 13, 12, 11, 127, 9, 8, 7, 6, 5, -128, 3, 2, 1, 0),
                                               _mm256_setr_epi8(15, 14, 13, 12, 11,  10, 9, 8, 7, 6, 5,   -4, 3, 2, 1, 0, 15, 14, 13, 12, 11,  10, 9, 8, 7, 6, 5,   -4, 3, 2, 1, 0));
    static immutable byte[32] correctResult                  = [30, 28, 26, 24, 22, 127,18,16,14,12,10, -128, 6, 4, 2, 0, 30, 28, 26, 24, 22, 127,18,16,14,12,10, -128, 6, 4, 2, 0]; 
    assert(res.array == correctResult);
}

/// Add packed 16-bit unsigned integers in `a` and `b` using unsigned saturation.
__m256i _mm256_adds_epu16 (__m256i a, __m256i b) pure @trusted
{
    // PERF DMD
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_paddusw256(cast(short16)a, cast(short16)b);
    }
    else static if(LDC_with_saturated_intrinsics)
    {
        return cast(__m256i) inteli_llvm_addus!short16(cast(short16)a, cast(short16)b);
    }
    else
    {
        short16 r;
        short16 sa = cast(short16)a;
        short16 sb = cast(short16)b;
        foreach(i; 0..16)
            r.ptr[i] = saturateSignedIntToUnsignedShort(cast(ushort)(sa.array[i]) + cast(ushort)(sb.array[i]));
        return cast(__m256i)r;
    }
}
unittest
{
    short16 res = cast(short16) _mm256_adds_epu16(_mm256_set_epi16(3, 2, cast(short)65535, 0, 3, 2, cast(short)65535, 0, 3, 2, cast(short)65535, 0, 3, 2, cast(short)65535, 0),
                                             _mm256_set_epi16(3, 2, 1, 0, 3, 2, 1, 0, 3, 2, 1, 0, 3, 2, 1, 0));
    static immutable short[16] correctResult = [0, cast(short)65535, 4, 6, 0, cast(short)65535, 4, 6, 0, cast(short)65535, 4, 6, 0, cast(short)65535, 4, 6];
    assert(res.array == correctResult);
}

/// Add packed 8-bit unsigned integers in `a` and `b` using unsigned saturation.
__m256i _mm256_adds_epu8 (__m256i a, __m256i b) pure @trusted
{
    // PERF DMD
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_paddusb256(cast(ubyte32)a, cast(ubyte32)b);
    }
    else static if(LDC_with_saturated_intrinsics)
    {
        return cast(__m256i) inteli_llvm_addus!byte32(cast(byte32)a, cast(byte32)b);
    }
    else
    {
        byte32 r;
        byte32 sa = cast(byte32)a;
        byte32 sb = cast(byte32)b;
        foreach(i; 0..32)
            r.ptr[i] = saturateSignedWordToUnsignedByte(cast(ubyte)(sa.array[i]) + cast(ubyte)(sb.array[i]));
        return cast(__m256i)r;
    }
}
unittest
{
    __m256i A          = _mm256_setr_epi8(0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, cast(byte)255, 0, 0, 0, 0, 0, 0, 0, 0, cast(byte)136, 0, 0, 0, cast(byte)136, 0, 0, 0, 0, 0, 0);
    __m256i B          = _mm256_setr_epi8(0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0,             1, 0, 0, 0, 0, 0, 0, 0, 0, cast(byte)136, 0, 0, 0,            40, 0, 0, 0, 0, 0, 0);
    byte32 R = cast(byte32) _mm256_adds_epu8(A, B);
    static immutable byte[32] correct =  [0, 0, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0, cast(byte)255, 0, 0, 0, 0, 0, 0, 0, 0, cast(byte)255, 0, 0, 0, cast(byte)176, 0, 0, 0, 0, 0, 0];
    assert(R.array == correct);
}

/// Concatenate pairs of 16-byte blocks in `a` and `b` into a 32-byte temporary result, shift the 
/// result right by `imm8` bytes, and return the low 16 bytes of that in each lane.
__m256i _mm256_alignr_epi8(ubyte count)(__m256i a, __m256i b) pure @trusted
{

    // PERF DMD
    static if (GDC_with_AVX2)
    {
        return cast(__m256i)__builtin_ia32_palignr256(a, b, count * 8);
    }
    else
    {
        // Note that palignr 256-bit does the same as palignr 128-bit by lane. Can split.
        // With LDC 1.24 + avx2 feature + -02, that correctly gives a AVX2 vpalignr despite being split.
        // I guess we could do it with a big 32-items shufflevector but not sure if best.
        // 2 inst on ARM64 neon, which is optimal.
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i b_lo = _mm256_extractf128_si256!0(b);
        __m128i b_hi = _mm256_extractf128_si256!1(b);
        __m128i r_lo = _mm_alignr_epi8!count(a_lo, b_lo);
        __m128i r_hi = _mm_alignr_epi8!count(a_hi, b_hi);
        return _mm256_set_m128i(r_hi, r_lo);   
    }
}
unittest
{
    __m128i A = _mm_setr_epi8( 1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16);
    __m128i B = _mm_setr_epi8(17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32);
    __m256i AA = _mm256_set_m128i(A, A);
    __m256i BB = _mm256_set_m128i(B, B);

    {
        byte32 C = cast(byte32) _mm256_alignr_epi8!0(AA, BB);
        byte[32] correct = [17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32];
        assert(C.array == correct);
    }
    {
        byte32 C = cast(byte32) _mm256_alignr_epi8!20(AA, BB);
        byte[32] correct = [5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 0, 0, 0, 0, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 0, 0, 0, 0];
        assert(C.array == correct);
    }
    {
        byte32 C = cast(byte32) _mm256_alignr_epi8!34(AA, BB);
        byte[32] correct = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        assert(C.array == correct);
    }
}

/// Compute the bitwise AND of 256 bits (representing integer data) in `a` and `b`.
__m256i _mm256_and_si256 (__m256i a, __m256i b) pure @safe
{
    pragma(inline, true);
    return a & b;
}
unittest
{
    __m256i A = _mm256_set1_epi32(7);
    __m256i B = _mm256_set1_epi32(14);
    int8 R = cast(int8) _mm256_and_si256(A, B);
    int[8] correct = [6, 6, 6, 6, 6, 6, 6, 6];
    assert(R.array == correct);
}

/// Compute the bitwise NOT of 256 bits (representing integer data) in `a` and then AND with `b`.
__m256i _mm256_andnot_si256 (__m256i a, __m256i b) pure @safe
{
    // See: https://issues.dlang.org/show_bug.cgi?id=24283, 
    // need workaround if we ever use DMD AVX codegen

    pragma(inline, true);
    return (~a) & b;
}
unittest
{
    __m256i A = _mm256_setr_epi32(7, -2, 9, 54654, 7, -2, 9, 54654);
    __m256i B = _mm256_setr_epi32(14, 78, 111, -256, 14, 78, 111, -256);
    int8 R = cast(int8) _mm256_andnot_si256(A, B);
    int[8] correct = [8, 0, 102, -54784, 8, 0, 102, -54784];
    assert(R.array == correct);
}

/// Average packed unsigned 16-bit integers in `a` and `b`.
__m256i _mm256_avg_epu16 (__m256i a, __m256i b) pure @trusted
{
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pavgw256(cast(short16)a, cast(short16)b);
    }
    else static if (LDC_with_AVX2 && __VERSION__ >= 2094)
    {
        return cast(__m256i) __builtin_ia32_pavgw256(cast(short16)a, cast(short16)b);
    }
    else
    {
        // Splitting is always beneficial here, except -O0
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i b_lo = _mm256_extractf128_si256!0(b);
        __m128i b_hi = _mm256_extractf128_si256!1(b);
        __m128i r_lo = _mm_avg_epu16(a_lo, b_lo);
        __m128i r_hi = _mm_avg_epu16(a_hi, b_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
}
unittest
{
    __m256i A = _mm256_set1_epi16(31457);
    __m256i B = _mm256_set1_epi16(cast(short)64000);
    short16 avg = cast(short16)(_mm256_avg_epu16(A, B));
    foreach(i; 0..16)
        assert(avg.array[i] == cast(short)47729);
}

/// Average packed unsigned 8-bit integers in `a` and `b`.
__m256i _mm256_avg_epu8 (__m256i a, __m256i b) pure @trusted
{
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pavgb256(cast(ubyte32)a, cast(ubyte32)b);
    }
    else static if (LDC_with_AVX2 && __VERSION__ >= 2094)
    {
        return cast(__m256i) __builtin_ia32_pavgb256(cast(byte32)a, cast(byte32)b);
    }
    else
    {
        // Splitting is always beneficial here, except -O0
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i b_lo = _mm256_extractf128_si256!0(b);
        __m128i b_hi = _mm256_extractf128_si256!1(b);
        __m128i r_lo = _mm_avg_epu8(a_lo, b_lo);
        __m128i r_hi = _mm_avg_epu8(a_hi, b_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
}
unittest
{
    __m256i A = _mm256_set1_epi8(-1);
    __m256i B = _mm256_set1_epi8(13);
    byte32 avg = cast(byte32)(_mm256_avg_epu8(A, B));
    foreach(i; 0..32)
        assert(avg.array[i] == cast(byte)134);
}

/// Blend packed 16-bit integers from `a` and `b` within 128-bit lanes using 8-bit control
/// mask `imm8`, in each of the two lanes.
/// Note: this is functionally equivalent to two `_mm_blend_epi16`.
__m256i _mm256_blend_epi16(int imm8) (__m256i a, __m256i b) pure @trusted
{
    // PERF DMD
    assert(imm8 >= 0 && imm8 < 256);
    enum bool split = true; // makes things better, except on ARM32 which is no better than naive

    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pblendw256(cast(short16)a, cast(short16)b, imm8);
    }
    else static if (split)
    {
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i b_lo = _mm256_extractf128_si256!0(b);
        __m128i b_hi = _mm256_extractf128_si256!1(b);
        __m128i r_lo = _mm_blend_epi16!(imm8)(a_lo, b_lo);
        __m128i r_hi = _mm_blend_epi16!(imm8)(a_hi, b_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
}
unittest
{
    __m256i A = _mm256_setr_epi16(0, 1,  2,  3,  4,  5,  6,  7,  0, -1,  -2,  -3,  -4,  -5,  -6,  -7);
    __m256i B = _mm256_setr_epi16(8, 9, 10, 11, 12, 13, 14, 15, -8, -9, -10, -11, -12, -13, -14, -15);
    short16 C = cast(short16) _mm256_blend_epi16!147(A, B); // 10010011 10010011
    short[16] correct =        [8, 9,  2,  3, 12,  5,  6, 15, -8, -9,  -2, -3, -12,  -5,  -6, -15];
    assert(C.array == correct);
}

/// Blend packed 32-bit integers from `a` and `b` using 4-bit control mask `imm8`.
__m128i _mm_blend_epi32(int imm8)(__m128i a, __m128i b) pure @trusted
{
    // This one is interesting, it is functionally equivalent to SSE4.1 blendps (_mm_blend_ps)
    // So without AVX2 we can always fallback to _mm_blend_ps
    // And indeed, a shufflevector!int4 doesn't even use vpblendd with LDC, and prefer
    // blendps and shufps so why bother.

    // PERF DMD
    static assert(imm8 >= 0 && imm8 < 16);
    static if (GDC_with_AVX2)
    {
        return __builtin_ia32_pblendd128(a, b, imm8);
    }
    else
    {
        return cast(__m128i) _mm_blend_ps!imm8(cast(__m128)a, cast(__m128)b);
    }
}
unittest
{
    __m128i A = _mm_setr_epi32(0, 1,  2,  3);
    __m128i B = _mm_setr_epi32(8, 9, 10, 11);
    int4 C = _mm_blend_epi32!13(A, B); // 1101
    int[4] correct =    [8, 1, 10, 11];
    assert(C.array == correct);
}

/// Blend packed 32-bit integers from `a` and `b` using 8-bit control mask `imm8`.
__m256i _mm256_blend_epi32(int imm8)(__m256i a, __m256i b) pure @trusted
{
    // This one is functionally equivalent to AVX _mm256_blend_ps, except with integers.
    // With LDC, doing a shufflevector here would select the vblendps instruction anyway,
    // so we might as well defer to _mm256_blend_ps.

    // PERF DMD
    static assert(imm8 >= 0 && imm8 < 256);
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pblendd256 (cast(int8)a, cast(int8)b, imm8);
    }
    else
    {
        return cast(__m256i) _mm256_blend_ps!imm8(cast(__m256)a, cast(__m256)b);
    }
}
unittest
{
    __m256i A = _mm256_setr_epi32(0, 1,  2,  3,  4,  5,  6,  7);
    __m256i B = _mm256_setr_epi32(8, 9, 10, 11, 12, 13, 147, 15);
    int8 C = cast(int8) _mm256_blend_epi32!0xe7(A, B);
    int[8] correct =             [8, 9, 10,  3,  4, 13, 147, 15];
    assert(C.array == correct);
}

/// Blend packed 8-bit integers from `a` and `b` using `mask`.
/// Select from `b` if the high-order bit of the corresponding 8-bit element in `mask` is set, else select from `a`.
 __m256i _mm256_blendv_epi8 (__m256i a, __m256i b, __m256i mask) pure @safe
 {
    static if (GDC_with_AVX2)
        return cast(__m256i)__builtin_ia32_pblendvb256(cast(ubyte32)a, cast(ubyte32)b, cast(ubyte32)mask);
    else static if (LDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pblendvb256(cast(byte32)a, cast(byte32)b, cast(byte32)mask);
    }
    else
    {
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i b_lo = _mm256_extractf128_si256!0(b);
        __m128i b_hi = _mm256_extractf128_si256!1(b);
        __m128i m_lo = _mm256_extractf128_si256!0(mask);
        __m128i m_hi = _mm256_extractf128_si256!1(mask);
        __m128i r_lo = _mm_blendv_epi8(a_lo, b_lo, m_lo);
        __m128i r_hi = _mm_blendv_epi8(a_hi, b_hi, m_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
}
unittest
{
    __m128i A = _mm_setr_epi8( 0,  1,  2,  3,  4,  5,  6,  7,  
                               8,  9, 10, 11, 12, 13, 14, 15);
    __m128i B = _mm_setr_epi8(16, 17, 18, 19, 20, 21, 22, 23, 
                              24, 25, 26, 27, 28, 29, 30, 31);
    __m128i M = _mm_setr_epi8( 1, -1,  1,  1, -4,  1, -8,  127,  
                               1,  1, -1, -1,  4,  1,  8, -128);
    __m256i AA = _mm256_set_m128i(A, A);
    __m256i BB = _mm256_set_m128i(B, B);
    __m256i MM = _mm256_set_m128i(M, M);
    byte32 R = cast(byte32) _mm256_blendv_epi8(AA, BB, MM);
    byte[32] correct =      [  0, 17,  2,  3, 20,  5, 22,  7, 8,  9, 26, 27, 12, 13, 14, 31,
                               0, 17,  2,  3, 20,  5, 22,  7, 8,  9, 26, 27, 12, 13, 14, 31 ];
    assert(R.array == correct);
}

/// Broadcast the low packed 8-bit integer from `a` to all elements of result.
__m128i _mm_broadcastb_epi8 (__m128i a) pure @safe
{
    byte16 ba = cast(byte16)a;
    byte16 r;
    r = ba.array[0];
    return cast(__m128i)r;
}
unittest
{
    byte16 A;
    A.ptr[0] = 2;
    byte16 B = cast(byte16) _mm_broadcastb_epi8(cast(__m128i)A);
    byte[16] correct = [2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2];
    assert(B.array == correct);
}

/// Bro0adcast the low packed 8-bit integer from `a` to all elements of result.
__m256i _mm256_broadcastb_epi8(__m128i a) pure @safe
{
    byte16 ba = cast(byte16)a;
    byte32 r;
    r = ba.array[0];
    return cast(__m256i)r;
}
unittest
{
    byte16 A;
    A.ptr[0] = 2;
    byte32 B = cast(byte32) _mm256_broadcastb_epi8(cast(__m128i)A);
    byte[32] correct = [2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
                        2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2];
    assert(B.array == correct);
}

/// Broadcast the low packed 32-bit integer from `a` to all elements of result.
__m128i _mm_broadcastd_epi32 (__m128i a) pure @safe
{
    int4 ba = cast(int4)a;
    int4 r;
    r = ba.array[0];
    return cast(__m128i)r;
}
unittest
{
    int4 A;
    A.ptr[0] = -2;
    int4 B = cast(int4) _mm_broadcastd_epi32(cast(__m128i)A);
    int[4] correct = [-2, -2, -2, -2];
    assert(B.array == correct);
}

/// Broadcast the low packed 32-bit integer from `a` to all elements of result.
__m256i _mm256_broadcastd_epi32 (__m128i a) pure @safe
{
    int4 ba = cast(int4)a;
    int8 r;
    r = ba.array[0];
    return cast(__m256i)r;
}
unittest
{
    int4 A;
    A.ptr[0] = -2;
    int8 B = cast(int8) _mm256_broadcastd_epi32(cast(__m128i)A);
    int[8] correct = [-2, -2, -2, -2, -2, -2, -2, -2];
    assert(B.array == correct);
}

/// Broadcast the low packed 64-bit integer from `a` to all elements of result.
__m128i _mm_broadcastq_epi64 (__m128i a) pure @safe
{
    long2 ba = cast(long2)a;
    long2 r;
    r = ba.array[0];
    return cast(__m128i)r;
}
unittest
{
    long2 A;
    A.ptr[0] = -2;
    long2 B = cast(long2) _mm_broadcastq_epi64(cast(__m128i)A);
    long[2] correct = [-2, -2];
    assert(B.array == correct);
}

/// Broadcast the low packed 64-bit integer from `a` to all elements of result.
__m256i _mm256_broadcastq_epi64 (__m128i a) pure @safe
{
    long2 ba = cast(long2)a;
    long4 r;
    r = ba.array[0];
    return cast(__m256i)r;
}
unittest
{
    long2 A;
    A.ptr[0] = -2;
    long4 B = cast(long4) _mm256_broadcastq_epi64(cast(__m128i)A);
    long[4] correct = [-2, -2, -2, -2];
    assert(B.array == correct);
}

/// Broadcast the low double-precision (64-bit) floating-point element from `a` to all elements of result.
__m128d _mm_broadcastsd_pd (__m128d a) pure @safe
{
    double2 r;
    r = a.array[0];
    return r;
}
unittest
{
    double2 A;
    A.ptr[0] = 2;
    double2 B = _mm_broadcastsd_pd(A);
    double[2] correct = [2.0, 2.0];
    assert(B.array == correct);
}

/// Broadcast the low double-precision (64-bit) floating-point element from `a` to all elements of result.
__m256d _mm256_broadcastsd_pd (__m128d a) pure @safe
{
    double4 r;
    r = a.array[0];
    return r;
}
unittest
{
    double2 A;
    A.ptr[0] = 3;
    double4 B = _mm256_broadcastsd_pd(A);
    double[4] correct = [3.0, 3, 3, 3];
    assert(B.array == correct);
}

/// Broadcast 128 bits of integer data from ``a to all 128-bit lanes in result.
/// Note: also exist with name `_mm256_broadcastsi128_si256` which is identical.
__m256i _mm_broadcastsi128_si256 (__m128i a) pure @trusted
{
    // Note that GDC will prefer vinserti128 to vbroadcast, for some reason
    // So in the end it's the same as naive code.
    // For this reason, __builtin_ia32_vbroadcastsi256 isn't used
    long2 ba = cast(long2)a;
    long4 r;
    r.ptr[0] = ba.array[0];
    r.ptr[1] = ba.array[1];
    r.ptr[2] = ba.array[0];
    r.ptr[3] = ba.array[1];
    return cast(__m256i)r;
}
unittest
{
    long2 A;
    A.ptr[0] = 34;
    A.ptr[1] = -56;
    long4 B = cast(long4) _mm_broadcastsi128_si256(cast(__m128i)A);
    long[4] correct = [34, -56, 34, -56];
    assert(B.array == correct);
}

///ditto
alias _mm256_broadcastsi128_si256 = _mm_broadcastsi128_si256; // intrinsics is duplicated in the Guide, for some reason

/// Broadcast the low single-precision (32-bit) floating-point element from `a` to all elements of result.
__m128 _mm_broadcastss_ps (__m128 a) pure @safe
{
    float4 r;
    r = a.array[0];
    return r;
}
unittest
{
    float4 A;
    A.ptr[0] = 2;
    float4 B = _mm_broadcastss_ps(A);
    float[4] correct = [2.0f, 2, 2, 2];
    assert(B.array == correct);
}

/// Broadcast the low single-precision (32-bit) floating-point element from `a` to all elements of result.
__m256 _mm256_broadcastss_ps (__m128 a) pure @safe
{
    float8 r;
    r = a.array[0];
    return r;
}
unittest
{
    float4 A;
    A.ptr[0] = 2;
    float8 B = _mm256_broadcastss_ps(A);
    float[8] correct = [2.0f, 2, 2, 2, 2, 2, 2, 2];
    assert(B.array == correct);
}

/// Broadcast the low packed 16-bit integer from `a` to all elements of result.
__m128i _mm_broadcastw_epi16 (__m128i a) pure @safe
{
    short8 ba = cast(short8)a;
    short8 r;
    r = ba.array[0];
    return cast(__m128i)r;
}
unittest
{
    short8 A;
    A.ptr[0] = 13;
    short8 B = cast(short8) _mm_broadcastw_epi16(cast(__m128i)A);
    short[8] correct = [13, 13, 13, 13, 13, 13, 13, 13];
    assert(B.array == correct);
}

/// Broadcast the low packed 16-bit integer from `a` to all elements of result.
__m256i _mm256_broadcastw_epi16 (__m128i a) pure @safe
{
    short8 ba = cast(short8)a;
    short16 r;
    r = ba.array[0];
    return cast(__m256i)r;
}
unittest
{
    short8 A;
    A.ptr[0] = 13;
    short16 B = cast(short16) _mm256_broadcastw_epi16(cast(__m128i)A);
    short[16] correct = [13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13];
    assert(B.array == correct);
}


/// Shift 128-bit lanes in `a` left by `bytes` bytes while shifting in zeroes.
__m256i _mm256_bslli_epi128(ubyte bytes)(__m256i a) pure @trusted
{
    // Note: can't use __builtin_ia32_pslldqi256 with GDC, wants an immediate
    //       and even string mixin do not make it
    // PERF: hence GDC AVX2 doesn't use the instruction, and nothing inlines very well in GDC either
    static if (bytes >= 16)
    {
        return _mm256_setzero_si256();
    }
    else static if (LDC_with_AVX2)
    {
        return cast(__m256i)__asm!(long4)("vpslldq $2, $1, $0", "=v,v,I", a, bytes);
    }
    else // split
    {
        __m128i lo = _mm_slli_si128!bytes(_mm256_extractf128_si256!0(a));
        __m128i hi = _mm_slli_si128!bytes(_mm256_extractf128_si256!1(a));
        return _mm256_set_m128i(hi, lo);
    }
}
unittest
{
    __m256i a = _mm256_setr_epi8(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32);
    assert(_mm256_bslli_epi128!7(a).array == [72057594037927936, 650777868590383874, 1224979098644774912, 1808220633999610642]);
}

/// Shift 128-bit lanes in `a` right by `bytes` bytes while shifting in zeroes.
__m256i _mm256_bsrli_epi128(ubyte bytes)(__m256i a) pure @trusted
{
    // Note: can't use __builtin_ia32_psrldqi256 with GDC, wants an immediate
    //       and even string mixin do not make it
    // PERF: hence GDC AVX2 doesn't use the instruction, and nothing inlines very well in GDC either
    static if (bytes >= 16)
    {
        return _mm256_setzero_si256();
    }
    else static if (LDC_with_AVX2)
    {
        return cast(__m256i)__asm!(long4)("vpsrldq $2, $1, $0", "=v,v,I", a, bytes);
    }
    else // split
    {
        __m128i lo = _mm_srli_si128!bytes(_mm256_extractf128_si256!0(a));
        __m128i hi = _mm_srli_si128!bytes(_mm256_extractf128_si256!1(a));
        return _mm256_set_m128i(hi, lo);
    }
}
unittest
{
    __m256i a = _mm256_setr_epi8(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32);
    assert(_mm256_bsrli_epi128!7(a).array == [1084818905618843912, 16, 2242261671028070680, 32]);
}

/// Compare packed 16-bit integers in `a` and `b` for equality.
__m256i _mm256_cmpeq_epi16 (__m256i a, __m256i b) pure @trusted
{
    // PERF: GDC without AVX
    // PERF: DMD
    static if (SIMD_COMPARISON_MASKS_32B)
    {
        // PERF: catastrophic in GDC without AVX2
        return cast(__m256i)(cast(short16)a == cast(short16)b);
    }
    else static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pcmpeqw256(cast(short16)a, cast(short16)b);
    }
    else version(LDC)
    {
        return cast(__m256i) equalMask!short16(cast(short16)a, cast(short16)b);
    }
    else
    {
        short16 sa = cast(short16)a;
        short16 sb = cast(short16)b;
        short16 sr;
        for (int n = 0; n < 16; ++n)
        {
            bool cond = sa.array[n] == sb.array[n];
            sr.ptr[n] = cond ? -1 : 0;
        }
        return cast(__m256i) sr;
    }
}
unittest
{
    short16   A = [-3, -2, -1,  0,  0,  1,  2,  3, -3, -2, -1,  0,  0,  1,  2,  3];
    short16   B = [ 4,  3,  2,  1,  0, -1, -2, -3, -3,  3,  2,  1,  0, -1, -2, -3];
    short[16] E = [ 0,  0,  0,  0, -1,  0,  0,  0, -1,  0,  0,  0, -1,  0,  0,  0];
    short16   R = cast(short16)(_mm256_cmpeq_epi16(cast(__m256i)A, cast(__m256i)B));
    assert(R.array == E);
}

/// Compare packed 32-bit integers in `a` and `b` for equality.
__m256i _mm256_cmpeq_epi32 (__m256i a, __m256i b) pure @trusted
{
    // PERF: GDC without AVX
    // PERF: DMD
    static if (SIMD_COMPARISON_MASKS_32B)
    {
        // Quite bad in GDC -mavx (with no AVX2)
        return cast(__m256i)(cast(int8)a == cast(int8)b);
    }
    else static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pcmpeqd256(cast(int8)a, cast(int8)b);
    }
    else version(LDC)
    {
        return cast(__m256i) equalMask!int8(cast(int8)a, cast(int8)b);
    }
    else
    {
        int8 ia = cast(int8)a;
        int8 ib = cast(int8)b;
        int8 ir;
        for (int n = 0; n < 8; ++n)
        {
            bool cond = ia.array[n] == ib.array[n];
            ir.ptr[n] = cond ? -1 : 0;
        }
        return cast(__m256i) ir;
    }
}
unittest
{
    int8   A = [-3, -2, -1,  0, -3, -2, -1,  0];
    int8   B = [ 4, -2,  2,  0,  4, -2,  2,  0];
    int[8] E = [ 0, -1,  0, -1,  0, -1,  0, -1];
    int8   R = cast(int8)(_mm256_cmpeq_epi32(cast(__m256i)A, cast(__m256i)B));
    assert(R.array == E);
}

/// Compare packed 64-bit integers in `a` and `b` for equality.
__m256i _mm256_cmpeq_epi64 (__m256i a, __m256i b) pure @trusted
{
    // PERF: GDC without AVX
    // PERF: DMD
    static if (SIMD_COMPARISON_MASKS_32B)
    {
        // Note: enabling this with DMD will probably lead to same bug as _mm_cmpeq_epi64
        return cast(__m256i)(cast(long4)a == cast(long4)b);
    }
    else static if (GDC_with_AVX2)
    {
        return cast(__m256i)__builtin_ia32_pcmpeqq256(cast(long4)a, cast(long4)b);
    }
    else version(LDC)
    {
        return cast(__m256i) equalMask!long4(cast(long4)a, cast(long4)b);
    }
    else
    {
        long4 la = cast(long4)a;
        long4 lb = cast(long4)b;
        long4 res;
        res.ptr[0] = (la.array[0] == lb.array[0]) ? -1 : 0;
        res.ptr[1] = (la.array[1] == lb.array[1]) ? -1 : 0;
        res.ptr[2] = (la.array[2] == lb.array[2]) ? -1 : 0;
        res.ptr[3] = (la.array[3] == lb.array[3]) ? -1 : 0;
        return cast(__m256i)res;
    }
}
unittest
{
    __m256i A = _mm256_setr_epi64(-1, -2, -1, -2);
    __m256i B = _mm256_setr_epi64(-3, -2, -3, -3);
    __m256i C = _mm256_setr_epi64(-1, -4, -1, -2);
    long4 AB = cast(long4) _mm256_cmpeq_epi64(A, B);
    long4 AC = cast(long4) _mm256_cmpeq_epi64(A, C);
    long[4] correct1 = [ 0, -1,  0,  0];
    long[4] correct2 = [-1,  0, -1, -1];
    assert(AB.array == correct1);
    assert(AC.array == correct2);
}

/// Compare packed 8-bit integers in `a` and `b` for equality.
__m256i _mm256_cmpeq_epi8 (__m256i a, __m256i b) pure @trusted
{
    // PERF: GDC without AVX2, need split
    // PERF: DMD
    static if (SIMD_COMPARISON_MASKS_32B)
    {
        return cast(__m256i)(cast(byte32)a == cast(byte32)b);
    }
    else static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pcmpeqb256(cast(ubyte32)a, cast(ubyte32)b);
    }
    else version(LDC)
    {
        return cast(__m256i) equalMask!byte32(cast(byte32)a, cast(byte32)b);
    }
    else
    {
        byte32 ba = cast(byte32)a;
        byte32 bb = cast(byte32)b;
        byte32 br;
        for (int n = 0; n < 32; ++n)
        {
            bool cond = ba.array[n] == bb.array[n];
            br.ptr[n] = cond ? -1 : 0;
        }
        return cast(__m256i) br;
    }
}
unittest
{
    __m256i A = _mm256_setr_epi8(1, 2, 3, 1, 2, 1, 1, 2, 3, 2, 1, 0, 0, 1, 2, 1,
                                 1, 2, 3, 1, 2, 1, 1, 2, 3, 2, 1, 0, 0, 1, 2, 42);
    __m256i B = _mm256_setr_epi8(2, 2, 1, 2, 3, 1, 2, 3, 2, 1, 0, 0, 1, 2, 1, 1,
                                 2, 2, 1, 2, 3, 1, 2, 3, 2, 1, 0, 0, 1, 2, 1, 1);
    byte32 C = cast(byte32) _mm256_cmpeq_epi8(A, B);
    byte[32] correct =       [0,-1, 0, 0, 0,-1, 0, 0, 0, 0, 0,-1, 0, 0, 0, -1,
                              0,-1, 0, 0, 0,-1, 0, 0, 0, 0, 0,-1, 0, 0, 0,  0];
    assert(C.array == correct);
}

/// Compare packed signed 16-bit integers in `a` and `b` for greater-than.
__m256i _mm256_cmpgt_epi16 (__m256i a, __m256i b) pure @safe
{
    version(GNU)
        enum bool mayUseComparisonOperator = GDC_with_AVX2; // too slow in GDC without AVX2
    else
        enum bool mayUseComparisonOperator = true;

    static if (SIMD_COMPARISON_MASKS_32B && mayUseComparisonOperator)
    {
        return cast(__m256i)(cast(short16)a > cast(short16)b);
    }
    else static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pcmpgtw256(cast(short16)a, cast(short16)b);
    }
    else // split
    {
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i b_lo = _mm256_extractf128_si256!0(b);
        __m128i b_hi = _mm256_extractf128_si256!1(b);
        __m128i r_lo = _mm_cmpgt_epi16(a_lo, b_lo);
        __m128i r_hi = _mm_cmpgt_epi16(a_hi, b_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
}
unittest
{
    short16   A = [-3, -2, -1,  0,  0,  1,  2,  3, -3, -2, -1,  0,  0,  1,  2,  3];
    short16   B = [ 4,  3,  2,  1,  0, -1, -2, -3,  4, -3,  2,  1,  0, -1, -2, -3];
    short[16] E = [ 0,  0,  0,  0,  0, -1, -1, -1,  0, -1,  0,  0,  0, -1, -1, -1];
    short16   R = cast(short16)(_mm256_cmpgt_epi16(cast(__m256i)A, cast(__m256i)B));
    assert(R.array == E);
}

/// Compare packed signed 32-bit integers in `a` and `b` for greater-than.
__m256i _mm256_cmpgt_epi32 (__m256i a, __m256i b) pure @safe
{
    version(GNU)
        enum bool mayUseComparisonOperator = GDC_with_AVX2; // too slow in GDC else
    else
        enum bool mayUseComparisonOperator = true;

    static if (SIMD_COMPARISON_MASKS_32B && mayUseComparisonOperator)
    {
        return cast(__m256i)(cast(int8)a > cast(int8)b);
    }
    else static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pcmpgtd256(cast(int8)a, cast(int8)b);
    }
    else // split
    {
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i b_lo = _mm256_extractf128_si256!0(b);
        __m128i b_hi = _mm256_extractf128_si256!1(b);
        __m128i r_lo = _mm_cmpgt_epi32(a_lo, b_lo);
        __m128i r_hi = _mm_cmpgt_epi32(a_hi, b_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
}
unittest
{
    int8   A = [-3,  2, -1,  0, -3,  2, -1,  0];
    int8   B = [ 4, -2,  2,  0,  4, -2,  2,  0];
    int[8] E = [ 0, -1,  0,  0,  0, -1,  0,  0];
    int8   R = cast(int8) _mm256_cmpgt_epi32(cast(__m256i)A, cast(__m256i)B);
    assert(R.array == E);
}

__m256i _mm256_cmpgt_epi64 (__m256i a, __m256i b) pure @safe
{
    version(GNU)
        enum bool mayUseComparisonOperator = GDC_with_AVX2; // too slow in GDC else
    else
        enum bool mayUseComparisonOperator = true;

    static if (SIMD_COMPARISON_MASKS_32B && mayUseComparisonOperator)
    {
        return cast(__m256i)(cast(long4)a > cast(long4)b);
    }
    else static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pcmpgtq256(cast(long4)a, cast(long4)b);
    }
    else // split
    {
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i b_lo = _mm256_extractf128_si256!0(b);
        __m128i b_hi = _mm256_extractf128_si256!1(b);
        __m128i r_lo = _mm_cmpgt_epi64(a_lo, b_lo);
        __m128i r_hi = _mm_cmpgt_epi64(a_hi, b_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
}
unittest
{
    __m256i A = _mm256_setr_epi64(-3,  2, 70,  2);
    __m256i B = _mm256_setr_epi64 (4, -2,  4, -2);
    long[4] correct = [ 0, -1, -1, -1 ];
    long4 R = cast(long4)(_mm256_cmpgt_epi64(A, B));
    assert(R.array == correct);
}

/// Compare packed signed 8-bit integers in `a` and `b` for greater-than.
__m256i _mm256_cmpgt_epi8 (__m256i a, __m256i b) pure @safe
{
    version(GNU)
        enum bool mayUseComparisonOperator = GDC_with_AVX2; // too slow in GDC without AVX2
    else
        enum bool mayUseComparisonOperator = true;

    static if (SIMD_COMPARISON_MASKS_32B && mayUseComparisonOperator)
    {
        return cast(__m256i)(cast(byte32)a > cast(byte32)b);
    }
    else static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pcmpgtb256(cast(short16)a, cast(short16)b);
    }
    else // split
    {
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i b_lo = _mm256_extractf128_si256!0(b);
        __m128i b_hi = _mm256_extractf128_si256!1(b);
        __m128i r_lo = _mm_cmpgt_epi8(a_lo, b_lo);
        __m128i r_hi = _mm_cmpgt_epi8(a_hi, b_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
}
unittest
{
    __m256i A = _mm256_setr_epi8(1, 2, 3, 1,  127, -80, 1, 2, 3, 2, 1, 0, 0, 1, 2, 1,   1, 2, 3, 1,  127, -80, 1, 2, 3, 2, 1, 0, 0, 1, 2, 1);
    __m256i B = _mm256_setr_epi8(2, 2, 1, 2, -128, -42, 2, 3, 2, 1, 0, 0, 1, 2, 1, 1,   2, 2, 1, 2, -128, -42, 2, 3, 2, 1, 0, 0, 1, 2, 1, 0);
    byte32 C = cast(byte32) _mm256_cmpgt_epi8(A, B);
    byte[32] correct =          [0, 0,-1, 0,   -1,   0, 0, 0,-1,-1,-1, 0, 0, 0,-1, 0,   0, 0,-1, 0,   -1,   0, 0, 0,-1,-1,-1, 0, 0, 0,-1,-1];
    assert(C.array == correct);
}


/// Sign extend packed 16-bit integers in `a` to packed 32-bit integers.
__m256i _mm256_cvtepi16_epi32 (__m128i a) pure @trusted
{
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pmovsxwd256(cast(short8)a);
    }
    else static if (LDC_with_optimizations)
    {
        enum ir = `
            %r = sext <8 x i16> %0 to <8 x i32>
            ret <8 x i32> %r`;
        return cast(__m256i) LDCInlineIR!(ir, int8, short8)(cast(short8)a);
    }
    else
    {
        short8 sa = cast(short8)a;
        int8 r;
        r.ptr[0] = sa.array[0];
        r.ptr[1] = sa.array[1];
        r.ptr[2] = sa.array[2];
        r.ptr[3] = sa.array[3];
        r.ptr[4] = sa.array[4];
        r.ptr[5] = sa.array[5];
        r.ptr[6] = sa.array[6];
        r.ptr[7] = sa.array[7];
        return cast(__m256i)r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi16(-1, 0, -32768, 32767, -1, 0, -32768, 32767);
    int8 C = cast(int8) _mm256_cvtepi16_epi32(A);
    int[8] correct = [-1, 0, -32768, 32767, -1, 0, -32768, 32767];
    assert(C.array == correct);
}


/// Sign extend packed 16-bit integers in `a` to packed 64-bit integers.
__m256i _mm256_cvtepi16_epi64 (__m128i a) pure @trusted
{
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pmovsxwq256(cast(short8)a);
    }
    else static if (LDC_with_optimizations)
    {
        enum ir = `
            %v = shufflevector <8 x i16> %0,<8 x i16> %0, <4 x i32> <i32 0, i32 1,i32 2, i32 3>
            %r = sext <4 x i16> %v to <4 x i64>
            ret <4 x i64> %r`;
        return cast(__m256i) LDCInlineIR!(ir, long4, short8)(cast(short8)a);
    }
    else
    {
        // LDC x86 generates vpmovsxwq since LDC 1.12 -O1
        short8 sa = cast(short8)a;
        long4 r;
        r.ptr[0] = sa.array[0];
        r.ptr[1] = sa.array[1];
        r.ptr[2] = sa.array[2];
        r.ptr[3] = sa.array[3];
        return cast(__m256i)r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi16(-1, 0, short.min, short.max, 2, 3, 4, 5);
    long4 C = cast(long4) _mm256_cvtepi16_epi64(A);
    long[4] correct = [-1, 0, short.min, short.max];
    assert(C.array == correct);
}

/// Sign extend packed 32-bit integers in `a` to packed 64-bit integers.
__m256i _mm256_cvtepi32_epi64 (__m128i a) pure @trusted
{
    long4 r;
    r.ptr[0] = a.array[0];
    r.ptr[1] = a.array[1];
    r.ptr[2] = a.array[2];
    r.ptr[3] = a.array[3];
    return cast(__m256i)r;
}
unittest
{
    __m128i A = _mm_setr_epi32(-1, 0, int.min, int.max);
    long4 C = cast(long4) _mm256_cvtepi32_epi64(A);
    long[4] correct = [-1, 0, int.min, int.max];
    assert(C.array == correct);
}

/// Sign extend packed 8-bit integers in `a` to packed 16-bit integers.
__m256i _mm256_cvtepi8_epi16 (__m128i a) pure @trusted
{
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pmovsxbw256(cast(ubyte16)a);
    }
    else static if (LDC_with_optimizations)
    {
        enum ir = `
            %r = sext <16 x i8> %0 to <16 x i16>
            ret <16 x i16> %r`;
        return cast(__m256i) LDCInlineIR!(ir, short16, byte16)(cast(byte16)a);
    }
    else
    {
        short16 r;
        byte16 ba = cast(byte16)a;
        for (int n = 0; n < 16; ++n)
        {
            r.ptr[n] = ba.array[n];
        }
        return cast(__m256i)r; 
    }
}
unittest
{
    __m128i A = _mm_setr_epi8(-1, 0, byte.min, byte.max, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13);
    short16 C = cast(short16) _mm256_cvtepi8_epi16(A);
    short[16] correct = [-1, 0, byte.min, byte.max, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13];
    assert(C.array == correct);
}

/// Sign extend packed 8-bit integers in `a` to packed 32-bit integers.
__m256i _mm256_cvtepi8_epi32 (__m128i a) pure @trusted
{
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pmovsxbd256(cast(ubyte16)a);
    }
    else static if (LDC_with_optimizations)
    {
        enum ir = `
            %v = shufflevector <16 x i8> %0,<16 x i8> undef, <8 x i32> <i32 0, i32 1,i32 2, i32 3, i32 4, i32 5,i32 6, i32 7>
            %r = sext <8 x i8> %v to <8 x i32>
            ret <8 x i32> %r`;
        return cast(__m256i) LDCInlineIR!(ir, int8, byte16)(cast(byte16)a);
    }
    else
    {
        // PERF This is rather bad in GDC without AVX, or with DMD
        // should split that
        int8 r;
        byte16 ba = cast(byte16)a;
        for (int n = 0; n < 8; ++n)
        {
            r.ptr[n] = ba.array[n];
        }
        return cast(__m256i)r; 
    }
}
unittest
{
    __m128i A = _mm_setr_epi8(-1, 0, byte.min, byte.max, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13);
    int8 C = cast(int8) _mm256_cvtepi8_epi32(A);
    int[8] correct = [-1, 0, byte.min, byte.max, 2, 3, 4, 5];
    assert(C.array == correct);
}

/// Sign extend packed 8-bit integers in the low 8 bytes of `a` to packed 64-bit integers.
__m256i _mm256_cvtepi8_epi64 (__m128i a) pure @trusted
{
    // PERF This is rather bad in GDC without AVX
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pmovsxbq256(cast(ubyte16)a);
    }
    else static if (LDC_with_ARM64)
    {
        // 4 inst since LDC 1.22 -O2 
        return _mm256_cvtepi16_epi64(_mm_cvtepi8_epi16(a));
    }
    else static if (LDC_with_optimizations)
    {
        enum ir = `
            %v = shufflevector <16 x i8> %0,<16 x i8> undef, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
            %r = sext <4 x i8> %v to <4 x i64>
            ret <4 x i64> %r`;
        return cast(__m256i) LDCInlineIR!(ir, long4, byte16)(cast(byte16)a);
    }
    else
    {
        long4 r;
        byte16 ba = cast(byte16)a;
        for (int n = 0; n < 4; ++n)
        {
            r.ptr[n] = ba.array[n];
        }
        return cast(__m256i)r; 
    }
}
unittest
{
    __m128i A = _mm_setr_epi8(-1, 0, byte.min, byte.max, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13);
    long4 C = cast(long4) _mm256_cvtepi8_epi64(A);
    long[4] correct = [-1, 0, byte.min, byte.max];
    assert(C.array == correct);
}

/// Zero-extend packed unsigned 16-bit integers in `a` to packed 32-bit integers.
__m256i _mm256_cvtepu16_epi32(__m128i a) pure @trusted
{
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pmovzxwd256(cast(short8)a);
    }
    else
    {
        short8 sa = cast(short8)a;
        int8 r;
        r.ptr[0] = cast(ushort)sa.array[0];
        r.ptr[1] = cast(ushort)sa.array[1];
        r.ptr[2] = cast(ushort)sa.array[2];
        r.ptr[3] = cast(ushort)sa.array[3];
        r.ptr[4] = cast(ushort)sa.array[4];
        r.ptr[5] = cast(ushort)sa.array[5];
        r.ptr[6] = cast(ushort)sa.array[6];
        r.ptr[7] = cast(ushort)sa.array[7];
        return cast(__m256i)r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi16(-1, 0, -32768, 32767, -1, 0, -32768, 32767);
    int8 C = cast(int8) _mm256_cvtepu16_epi32(A);
    int[8] correct = [65535, 0, 32768, 32767, 65535, 0, 32768, 32767];
    assert(C.array == correct);
}

/// Zero-extend packed unsigned 16-bit integers in `a` to packed 64-bit integers.
__m256i _mm256_cvtepu16_epi64(__m128i a) pure @trusted
{
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pmovzxwq256(cast(short8)a);
    }
    else static if (LDC_with_optimizations)
    {
        enum ir = `
            %v = shufflevector <8 x i16> %0,<8 x i16> %0, <4 x i32> <i32 0, i32 1,i32 2, i32 3>
            %r = zext <4 x i16> %v to <4 x i64>
            ret <4 x i64> %r`;
        return cast(__m256i) LDCInlineIR!(ir, long4, short8)(cast(short8)a);
    }
    else
    {
        short8 sa = cast(short8)a;
        long4 r;
        r.ptr[0] = cast(ushort)sa.array[0];
        r.ptr[1] = cast(ushort)sa.array[1];
        r.ptr[2] = cast(ushort)sa.array[2];
        r.ptr[3] = cast(ushort)sa.array[3];
        return cast(__m256i)r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi16(-1, 0, -32768, 32767, 2, 3, 4, 5);
    long4 C = cast(long4) _mm256_cvtepu16_epi64(A);
    long[4] correct = [65535, 0, 32768, 32767];
    assert(C.array == correct);
}

/// Zero-extend packed unsigned 32-bit integers in `a` to packed 64-bit integers.
__m256i _mm256_cvtepu32_epi64 (__m128i a) pure @trusted
{
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pmovzxdq256(cast(int4)a);
    }
    else static if (LDC_with_optimizations)
    {
        enum ir = `
            %r = zext <4 x i32> %0 to <4 x i64>
            ret <4 x i64> %r`;
        return cast(__m256i) LDCInlineIR!(ir, long4, int4)(cast(int4)a);
    }
    else
    {
        long4 r;
        r.ptr[0] = cast(uint)a.array[0];
        r.ptr[1] = cast(uint)a.array[1];
        r.ptr[2] = cast(uint)a.array[2];
        r.ptr[3] = cast(uint)a.array[3];
        return cast(__m256i)r; 
    }
}
unittest
{
    __m128i A = _mm_setr_epi32(-1, 0, int.min, int.max);
    long4 C = cast(long4) _mm256_cvtepu32_epi64(A);
    long[4] correct = [uint.max, 0, 2_147_483_648, int.max];
    assert(C.array == correct);
}

/// Zero-extend packed unsigned 8-bit integers in `a` to packed 16-bit integers.
__m256i _mm256_cvtepu8_epi16 (__m128i a) pure @trusted
{
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pmovzxbw256(cast(ubyte16)a);
    }
    else static if (LDC_with_optimizations)
    {
        enum ir = `
            %r = zext <16 x i8> %0 to <16 x i16>
            ret <16 x i16> %r`;
        return cast(__m256i) LDCInlineIR!(ir, short16, byte16)(cast(byte16)a);
    }
    else
    {
        short16 r;
        byte16 ba = cast(byte16)a;
        for (int n = 0; n < 16; ++n)
        {
            r.ptr[n] = cast(ubyte)ba.array[n];
        }
        return cast(__m256i)r; 
    }
}
unittest
{
    __m128i A = _mm_setr_epi8(-1, 0, -128, 127, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13);
    short16 C = cast(short16) _mm256_cvtepu8_epi16(A);
    short[16] correct     = [255, 0,  128, 127, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13];
    assert(C.array == correct);
}

/// Zero-extend packed unsigned 8-bit integers in `a` to packed 32-bit integers.
__m256i _mm256_cvtepu8_epi32 (__m128i a) pure @trusted
{
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pmovzxbd256(cast(ubyte16)a);
    }
    else static if (LDC_with_optimizations)
    {
        enum ir = `
            %v = shufflevector <16 x i8> %0,<16 x i8> %0, <8 x i32> <i32 0, i32 1,i32 2, i32 3, i32 4, i32 5,i32 6, i32 7>
            %r = zext <8 x i8> %v to <8 x i32>
            ret <8 x i32> %r`;
        return cast(__m256i) LDCInlineIR!(ir, int8, byte16)(cast(byte16)a);
    }
    else
    {
        int8 r;
        byte16 ba = cast(byte16)a;
        for (int n = 0; n < 8; ++n)
        {
            r.ptr[n] = cast(ubyte)ba.array[n];
        }
        return cast(__m256i)r; 
    }
}
unittest
{
    __m128i A = _mm_setr_epi8(-1, 0, -128, 127, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13);
    int8 C = cast(int8) _mm256_cvtepu8_epi32(A);
    int[8] correct     = [255, 0,  128, 127, 2, 3, 4, 5];
    assert(C.array == correct);
}

/// Zero-extend packed unsigned 8-bit integers in `a` to packed 64-bit integers.
__m256i _mm256_cvtepu8_epi64 (__m128i a) pure @trusted
{
    // PERF ARM64+LDC, not awesome
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pmovzxbq256(cast(ubyte16)a);
    }
    else static if (LDC_with_optimizations)
    {
        enum ir = `
            %v = shufflevector <16 x i8> %0,<16 x i8> %0, <4 x i32> <i32 0, i32 1,i32 2, i32 3>
            %r = zext <4 x i8> %v to <4 x i64>
            ret <4 x i64> %r`;
        return cast(__m256i) LDCInlineIR!(ir, long4, byte16)(cast(byte16)a);
    }
    else
    {
        long4 r;
        byte16 ba = cast(byte16)a;
        for (int n = 0; n < 4; ++n)
        {
            r.ptr[n] = cast(ubyte)ba.array[n];
        }
        return cast(__m256i)r; 
    }
}
unittest
{
    __m128i A = _mm_setr_epi8(-1, 0, -128, 127, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13);
    long4 C = cast(long4) _mm256_cvtepu8_epi64(A);
    long[4] correct     = [255, 0,  128, 127];
    assert(C.array == correct);
}

/// Extract a 16-bit integer from `a`, selected with index.
int _mm256_extract_epi16 (__m256i a, int index) pure @trusted
{
    short16 sa = cast(short16)a;
    return sa.ptr[index & 15];
}
unittest
{
    short16 b;
    b = 43;
    assert(_mm256_extract_epi16(cast(__m256i)b, 7) == 43);
}

/// Extract a 8-bit integer from `a`, selected with index.
int _mm256_extract_epi8 (__m256i a, int index) pure @trusted
{
    byte32 sa = cast(byte32)a;
    return sa.ptr[index & 31];
}
unittest
{
    byte32 b;
    b = -44;
    assert(_mm256_extract_epi8(cast(__m256i)b, 5) == -44);
    assert(_mm256_extract_epi8(cast(__m256i)b, 5 + 32) == -44);
}

/// Extract 128 bits (composed of integer data) from `a`, selected with `imm8`.
__m128i _mm256_extracti128_si256(int imm8)(__m256i a) pure @trusted
    if ( (imm8 == 0) || (imm8 == 1) )
{
    pragma(inline, true);

    static if (GDC_with_AVX2)
    {
        return cast(__m128i) __builtin_ia32_extract128i256(a, imm8);
    }
    else static if (LDC_with_optimizations)
    {
        enum str = (imm8 == 1) ? "<i32 2, i32 3>" : "<i32 0, i32 1>";
        enum ir = "%r = shufflevector <4 x i64> %0, <4 x i64> undef, <2 x i32>" ~ str ~ "\n" ~
                  "ret <2 x i64> %r";
        return cast(__m128i) LDCInlineIR!(ir, ulong2, ulong4)(cast(ulong4)a);
    }
    else
    {
        long4 al = cast(long4) a;
        long2 ret;
        ret.ptr[0] = (imm8==1) ? al.array[2] : al.array[0];
        ret.ptr[1] = (imm8==1) ? al.array[3] : al.array[1];
        return cast(__m128i) ret;
    }
}
unittest
{
    __m256i A = _mm256_setr_epi32( -7, -1, 0, 9, -100, 100, 234, 432 );
    int[4] correct0 = [ -7, -1, 0, 9 ];
    int[4] correct1 = [ -100, 100, 234, 432 ];
    __m128i R0 = _mm256_extracti128_si256!(0)(A);
    __m128i R1 = _mm256_extracti128_si256!(1)(A);
    assert(R0.array == correct0);
    assert(R1.array == correct1);
}

/// Horizontally add adjacent pairs of 16-bit integers in `a` and `b`, and pack the signed 16-bit results.
__m256i _mm256_hadd_epi16 (__m256i a, __m256i b) pure @safe
{
    static if (GDC_or_LDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_phaddw256(cast(short16)a, cast(short16)b);
    }
    else
    {
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i b_lo = _mm256_extractf128_si256!0(b);
        __m128i b_hi = _mm256_extractf128_si256!1(b);
        __m128i r_lo = _mm_hadd_epi16(a_lo, b_lo);
        __m128i r_hi = _mm_hadd_epi16(a_hi, b_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
}
unittest
{
    __m256i A = _mm256_setr_epi16(1, -2, 4, 8, 16, 32, -1, -32768, 1, -2, 4, 8, 16, 32, -1, -32768);
    short16 C = cast(short16) _mm256_hadd_epi16(A, A);
    short[16] correct = [ -1, 12, 48, 32767, -1, 12, 48, 32767,  -1, 12, 48, 32767, -1, 12, 48, 32767];
    assert(C.array == correct);
}

/// Horizontally add adjacent pairs of 32-bit integers in `a` and `b`, and pack the signed 32-bit results.
__m256i _mm256_hadd_epi32 (__m256i a, __m256i b) pure @safe
{
    static if (GDC_or_LDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_phaddd256(cast(int8)a, cast(int8)b);
    }
    else
    {
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i b_lo = _mm256_extractf128_si256!0(b);
        __m128i b_hi = _mm256_extractf128_si256!1(b);
        __m128i r_lo = _mm_hadd_epi32(a_lo, b_lo);
        __m128i r_hi = _mm_hadd_epi32(a_hi, b_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
}
unittest
{
    __m256i A = _mm256_setr_epi32(1, -2, int.min, -1, 1, -2, int.min, -1);
    __m256i B = _mm256_setr_epi32(1, int.max, 4, -4, 1, int.max, 4, -4);
    int8 C = cast(int8) _mm256_hadd_epi32(A, B);
    int[8] correct = [ -1, int.max, int.min, 0, -1, int.max, int.min, 0 ];
    assert(C.array == correct);
}

/// Horizontally add adjacent pairs of signed 16-bit integers in `a` and `b` using saturation, and pack the signed 16-bit results.
__m256i _mm256_hadds_epi16 (__m256i a, __m256i b) pure @safe
{
    static if (GDC_or_LDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_phaddsw256(cast(short16)a, cast(short16)b);
    }
    else
    {
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i b_lo = _mm256_extractf128_si256!0(b);
        __m128i b_hi = _mm256_extractf128_si256!1(b);
        __m128i r_lo = _mm_hadds_epi16(a_lo, b_lo);
        __m128i r_hi = _mm_hadds_epi16(a_hi, b_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
}
unittest
{
    __m256i A = _mm256_setr_epi16(1, -2, 4, 8, 16, 32, -1, -32768, 1, -2, 4, 8, 16, 32, -1, -32768);
    short16 C = cast(short16) _mm256_hadds_epi16(A, A);
    short[16] correct = [ -1, 12, 48, -32768, -1, 12, 48, -32768, -1, 12, 48, -32768, -1, 12, 48, -32768];
    assert(C.array == correct);
}

/// Horizontally subtract adjacent pairs of 16-bit integers in `a` and `b`, and pack the signed 16-bit results.
__m256i _mm256_hsub_epi16 (__m256i a, __m256i b) pure @safe
{
    static if (GDC_or_LDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_phsubw256(cast(short16)a, cast(short16)b);
    }
    else
    {
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i b_lo = _mm256_extractf128_si256!0(b);
        __m128i b_hi = _mm256_extractf128_si256!1(b);
        __m128i r_lo = _mm_hsub_epi32(a_lo, b_lo);
        __m128i r_hi = _mm_hsub_epi32(a_hi, b_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
}
unittest
{
    __m256i A = _mm256_setr_epi32(1, 2, int.min, 1, 1, 2, int.min, 1);
    __m256i B = _mm256_setr_epi32(int.max, -1, 4, 4, int.max, -1, 4, 4);
    int8 C = cast(int8) _mm256_hsub_epi32(A, B);
    int[8] correct = [ -1, int.max, int.min, 0, -1, int.max, int.min, 0 ];
    assert(C.array == correct);
}

/// Horizontally subtract adjacent pairs of 32-bit integers in `a` and `b`, and pack the signed 32-bit results.
__m256i _mm256_hsub_epi32 (__m256i a, __m256i b) pure @safe
{
    static if (GDC_or_LDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_phsubd256(cast(int8)a, cast(int8)b);
    }
    else
    {
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i b_lo = _mm256_extractf128_si256!0(b);
        __m128i b_hi = _mm256_extractf128_si256!1(b);
        __m128i r_lo = _mm_hsub_epi32(a_lo, b_lo);
        __m128i r_hi = _mm_hsub_epi32(a_hi, b_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
}
unittest
{
    __m256i A = _mm256_setr_epi32(1, 2, int.min, 1, 1, 2, int.min, 1);
    __m256i B = _mm256_setr_epi32(int.max, -1, 4, 4, int.max, -1, 4, 4);
    int8 C = cast(int8) _mm256_hsub_epi32(A, B);
    int[8] correct = [ -1, int.max, int.min, 0,  -1, int.max, int.min, 0 ];
    assert(C.array == correct);
}

/// Horizontally subtract adjacent pairs of signed 16-bit integers in `a` and `b` using saturation, and pack the signed 16-bit results.
__m256i _mm256_hsubs_epi16 (__m256i a, __m256i b) pure @safe
{
    static if (GDC_or_LDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_phsubsw256(cast(short16)a, cast(short16)b);
    }
    else
    {
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i b_lo = _mm256_extractf128_si256!0(b);
        __m128i b_hi = _mm256_extractf128_si256!1(b);
        __m128i r_lo = _mm_hsubs_epi16(a_lo, b_lo);
        __m128i r_hi = _mm_hsubs_epi16(a_hi, b_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
}
unittest
{
    __m256i A = _mm256_setr_epi16(1, -2, 4, 8, 32767, -1, -10, 32767, 1, -2, 4, 8, 32767, -1, -10, 32767);
    short16 C = cast(short16) _mm256_hsubs_epi16(A, A);
    short[16] correct = [ 3, -4, 32767, -32768, 3, -4, 32767, -32768, 3, -4, 32767, -32768, 3, -4, 32767, -32768 ];
    assert(C.array == correct);
}


// TODO __m128i _mm_i32gather_epi32 (int const* base_addr, __m128i vindex, const int scale) pure @safe
// TODO __m128i _mm_mask_i32gather_epi32 (__m128i src, int const* base_addr, __m128i vindex, __m128i mask, const int scale) pure @safe
// TODO __m256i _mm256_i32gather_epi32 (int const* base_addr, __m256i vindex, const int scale) pure @safe
// TODO __m256i _mm256_mask_i32gather_epi32 (__m256i src, int const* base_addr, __m256i vindex, __m256i mask, const int scale) pure @safe
// TODO __m128i _mm_i32gather_epi64 (__int64 const* base_addr, __m128i vindex, const int scale) pure @safe
// TODO __m128i _mm_mask_i32gather_epi64 (__m128i src, __int64 const* base_addr, __m128i vindex, __m128i mask, const int scale) pure @safe
// TODO __m256i _mm256_i32gather_epi64 (__int64 const* base_addr, __m128i vindex, const int scale) pure @safe
// TODO __m256i _mm256_mask_i32gather_epi64 (__m256i src, __int64 const* base_addr, __m128i vindex, __m256i mask, const int scale) pure @safe
// TODO __m128d _mm_i32gather_pd (double const* base_addr, __m128i vindex, const int scale) pure @safe
// TODO __m128d _mm_mask_i32gather_pd (__m128d src, double const* base_addr, __m128i vindex, __m128d mask, const int scale) pure @safe
// TODO __m256d _mm256_i32gather_pd (double const* base_addr, __m128i vindex, const int scale) pure @safe
// TODO __m256d _mm256_mask_i32gather_pd (__m256d src, double const* base_addr, __m128i vindex, __m256d mask, const int scale) pure @safe
// TODO __m128 _mm_i32gather_ps (float const* base_addr, __m128i vindex, const int scale) pure @safe
// TODO __m128 _mm_mask_i32gather_ps (__m128 src, float const* base_addr, __m128i vindex, __m128 mask, const int scale) pure @safe
// TODO __m256 _mm256_i32gather_ps (float const* base_addr, __m256i vindex, const int scale) pure @safe
// TODO __m256 _mm256_mask_i32gather_ps (__m256 src, float const* base_addr, __m256i vindex, __m256 mask, const int scale) pure @safe
// TODO __m128i _mm_i64gather_epi32 (int const* base_addr, __m128i vindex, const int scale) pure @safe
// TODO __m128i _mm_mask_i64gather_epi32 (__m128i src, int const* base_addr, __m128i vindex, __m128i mask, const int scale) pure @safe
// TODO __m128i _mm256_i64gather_epi32 (int const* base_addr, __m256i vindex, const int scale) pure @safe
// TODO __m128i _mm256_mask_i64gather_epi32 (__m128i src, int const* base_addr, __m256i vindex, __m128i mask, const int scale) pure @safe
// TODO __m128i _mm_i64gather_epi64 (__int64 const* base_addr, __m128i vindex, const int scale) pure @safe
// TODO __m128i _mm_mask_i64gather_epi64 (__m128i src, __int64 const* base_addr, __m128i vindex, __m128i mask, const int scale) pure @safe
// TODO __m256i _mm256_i64gather_epi64 (__int64 const* base_addr, __m256i vindex, const int scale) pure @safe
// TODO __m256i _mm256_mask_i64gather_epi64 (__m256i src, __int64 const* base_addr, __m256i vindex, __m256i mask, const int scale) pure @safe
// TODO __m128d _mm_i64gather_pd (double const* base_addr, __m128i vindex, const int scale) pure @safe
// TODO __m128d _mm_mask_i64gather_pd (__m128d src, double const* base_addr, __m128i vindex, __m128d mask, const int scale) pure @safe
// TODO __m256d _mm256_i64gather_pd (double const* base_addr, __m256i vindex, const int scale) pure @safe
// TODO __m256d _mm256_mask_i64gather_pd (__m256d src, double const* base_addr, __m256i vindex, __m256d mask, const int scale) pure @safe
// TODO __m128 _mm_i64gather_ps (float const* base_addr, __m128i vindex, const int scale) pure @safe
// TODO __m128 _mm_mask_i64gather_ps (__m128 src, float const* base_addr, __m128i vindex, __m128 mask, const int scale) pure @safe
// TODO __m128 _mm256_i64gather_ps (float const* base_addr, __m256i vindex, const int scale) pure @safe
// TODO __m128 _mm256_mask_i64gather_ps (__m128 src, float const* base_addr, __m256i vindex, __m128 mask, const int scale) pure @safe


/// Copy `a` to result, then insert 128 bits from `b` into result at the location specified by 
/// `imm8`.
__m256i _mm256_inserti128_si256 (__m256i a, __m128i b, const int imm8) pure @trusted
{
    long2 lb = cast(long2)b;
    a.ptr[(imm8 & 1)*2  ] = lb.array[0];
    a.ptr[(imm8 & 1)*2+1] = lb.array[1];
    return a; 
}
unittest
{
    __m256i A = [0, 1, 2, 3];
    long2 B = [4, 5];
    __m256i C = _mm256_inserti128_si256(A, cast(__m128i)B, 0 + 8);
    __m256i D = _mm256_inserti128_si256(A, cast(__m128i)B, 1);
    long[4] correctC = [4, 5, 2, 3]; 
    long[4] correctD = [0, 1, 4, 5];
    assert(C.array == correctC);
    assert(D.array == correctD);
}

/// Multiply packed signed 16-bit integers in `a` and `b`, producing intermediate
/// signed 32-bit integers. Horizontally add adjacent pairs of intermediate 32-bit integers,
/// and pack the results in destination.
__m256i _mm256_madd_epi16 (__m256i a, __m256i b) pure @trusted
{
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pmaddwd256(cast(short16)a, cast(short16)b);
    }
    else static if (LDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pmaddwd256(cast(short16)a, cast(short16)b);
    }
    else
    {
        // split is beneficial for ARM64, LDC and GDC without AVX2
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i b_lo = _mm256_extractf128_si256!0(b);
        __m128i b_hi = _mm256_extractf128_si256!1(b);
        __m128i r_lo = _mm_madd_epi16(a_lo, b_lo);
        __m128i r_hi = _mm_madd_epi16(a_hi, b_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
}
unittest
{
    short16 A = [0, 1, 2, 3, -32768, -32768, 32767, 32767, 0, 1, 2, 3, -32768, -32768, 32767, 32767];
    short16 B = [0, 1, 2, 3, -32768, -32768, 32767, 32767, 0, 1, 2, 3, -32768, -32768, 32767, 32767];
    int8 R = cast(int8) _mm256_madd_epi16(cast(__m256i)A, cast(__m256i)B);
    int[8] correct = [1, 13, -2147483648, 2*32767*32767, 1, 13, -2147483648, 2*32767*32767];
    assert(R.array == correct);
}

/// Vertically multiply each unsigned 8-bit integer from `a` with the corresponding 
/// signed 8-bit integer from `b`, producing intermediate signed 16-bit integers. 
/// Horizontally add adjacent pairs of intermediate signed 16-bit integers, 
/// and pack the saturated results.
__m256i _mm256_maddubs_epi16 (__m256i a, __m256i b) @safe
{
    static if (GDC_with_AVX2)
    {
        return cast(__m256i)__builtin_ia32_pmaddubsw256(cast(ubyte32)a, cast(ubyte32)b);
    }
    else static if (LDC_with_AVX2)
    {
        return cast(__m256i)__builtin_ia32_pmaddubsw256(cast(byte32)a, cast(byte32)b);
    }
    else
    {
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i b_lo = _mm256_extractf128_si256!0(b);
        __m128i b_hi = _mm256_extractf128_si256!1(b);
        __m128i r_lo = _mm_maddubs_epi16(a_lo, b_lo);
        __m128i r_hi = _mm_maddubs_epi16(a_hi, b_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
}
unittest
{
    __m128i A = _mm_setr_epi8(  -1,  10, 100, -128, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0); // u8
    __m128i B = _mm_setr_epi8(-128, -30, 100,  127, -1, 2, 4, 6, 0, 0, 0, 0, 0, 0, 0, 0); // i8
    __m256i AA = _mm256_set_m128i(A, A);
    __m256i BB = _mm256_set_m128i(B, B);
    short16 C = cast(short16) _mm256_maddubs_epi16(AA, BB);
    short[16] correct =       [   -32768,     26256, 0, 0, 0, 0, 0, 0,
                                  -32768,     26256, 0, 0, 0, 0, 0, 0];
    assert(C.array == correct);
}

version(DigitalMars)
{
    // this avoids a bug with DMD < 2.099 -a x86 -O
    private enum bool maskLoadWorkaroundDMD = (__VERSION__ < 2099);
}
else
{
    private enum bool maskLoadWorkaroundDMD = false;
}

/// Load packed 32-bit integers from memory using `mask` (elements are zeroed out when the highest
/// bit is not set in the corresponding element).
/// Warning: See "Note about mask load/store" to know why you must address valid memory only.
__m128i _mm_maskload_epi32 (const(int)* mem_addr, __m128i mask) /* pure */ @system
{
    // PERF DMD
    static if (LDC_with_AVX2)
    {
        // MAYDO report that the builtin is impure
        return __builtin_ia32_maskloadd(mem_addr, mask);
    }
    else static if (GDC_with_AVX2)
    {
        return __builtin_ia32_maskloadd(cast(__m128i*)mem_addr, mask);
    }
    else
    {
        return cast(__m128i) _mm_maskload_ps(cast(const(float)*)mem_addr, mask);
    }
}
unittest
{
    static if (!maskLoadWorkaroundDMD)
    {
        int[4] A = [7, 1, 2, 3];
        int4 B = _mm_maskload_epi32(A.ptr, _mm_setr_epi32(1, -1, -1, 1));  // can NOT address invalid memory with mask load and writes!
        int[4] correct = [0, 1, 2, 0];
        assert(B.array == correct);
    }
}

/// Load packed 32-bit integers from memory using `mask` (elements are zeroed out when the highest 
/// bit is not set in the corresponding element).
/// Warning: See "Note about mask load/store" to know why you must address valid memory only.
__m256i _mm256_maskload_epi32 (const(int)* mem_addr, __m256i mask) /* pure */ @system
{
    static if (LDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_maskloadd256(mem_addr, cast(int8)mask);
    }
    else static if (GDC_with_AVX2)
    {
        return cast(__m256i)__builtin_ia32_maskloadd256(cast(__m256i*)mem_addr, cast(int8)mask);
    }
    else
    {
        return cast(__m256i) _mm256_maskload_ps(cast(const(float*)) mem_addr, mask);
    }
}
unittest
{
    int[8] A = [7, 1, 2, 3, 8, -2, 4, 5];
    int8 B = cast(int8) _mm256_maskload_epi32(A.ptr, _mm256_setr_epi32(1, -1, -1, 1, -1, -1, 1, 1));
    int[8] correct = [0, 1, 2, 0, 8, -2, 0, 0];
    assert(B.array == correct);
}

/// Load packed 64-bit integers from memory using `mask` (elements are zeroed out when the highest 
/// bit is not set in the corresponding element).
/// Warning: See "Note about mask load/store" to know why you must address valid memory only.
__m128i _mm_maskload_epi64 (const(long)* mem_addr, __m128i mask) @system
{
    // PERF DMD
    static if (LDC_with_AVX2)
    {
        return cast(__m128i) __builtin_ia32_maskloadq(mem_addr, cast(long2) mask);
    }
    else static if (GDC_with_AVX2)
    {
        return cast(__m128i) __builtin_ia32_maskloadq(cast(long2*)mem_addr, cast(long2) mask);
    }
    else
    {
        return cast(__m128i) _mm_maskload_pd(cast(const(double)*)mem_addr, mask);
    }
}
unittest
{
    static if (!maskLoadWorkaroundDMD)
    {
        long[2] A = [-7, -8];
        long2 B = cast(long2) _mm_maskload_epi64(A.ptr, _mm_setr_epi64(1, -1));
        long[2] correct = [0, -8];
        assert(B.array == correct);
    }
}

/// Load packed 64-bit integers from memory using `mask` (elements are zeroed out when the highest 
/// bit is not set in the corresponding element).
/// Warning: See "Note about mask load/store" to know why you must address valid memory only.
__m256i _mm256_maskload_epi64 (const(long)* mem_addr, __m256i mask) /* pure */ @system
{
    static if (LDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_maskloadq256(mem_addr, cast(long4)mask);
    }
    else static if (GDC_with_AVX2)
    {
        return cast(__m256i)__builtin_ia32_maskloadq256(cast(__m256i*)mem_addr, cast(long4)mask);
    }
    else
    {
        return cast(__m256i) _mm256_maskload_pd(cast(const(double*)) mem_addr, mask);
    }
}
unittest
{
    long[4] A = [ 8, -2, 4, 5];
    long4 B = cast(long4) _mm256_maskload_epi64(A.ptr, _mm256_setr_epi64(1, -1, -1, 1));
    long[4] correct = [0, -2, 4, 0];
}

/// Compare packed signed 16-bit integers in `a` and `b`, and return packed maximum values.
__m256i _mm256_max_epi16 (__m256i a, __m256i b) pure @safe
{
    // PERF D_SIMD
    version(GNU)
        enum bool split = true;
    else static if (SIMD_COMPARISON_MASKS_32B)
        enum bool split = false;
    else
        enum bool split = true;

    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pmaxsw256(cast(short16)a, cast(short16)b);
    }
    else static if (split)
    {
        // split
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i b_lo = _mm256_extractf128_si256!0(b);
        __m128i b_hi = _mm256_extractf128_si256!1(b);
        __m128i r_lo = _mm_max_epi16(a_lo, b_lo);
        __m128i r_hi = _mm_max_epi16(a_hi, b_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
    else static if (SIMD_COMPARISON_MASKS_32B)
    {
        // catastrophic with GDC x86 for some reason. Sad.
        short16 sa = cast(short16)a;
        short16 sb = cast(short16)b;
        short16 greater = sa > sb;
        return cast(__m256i)( (greater & sa) | (~greater & sb) );
    }
    else
        static assert(0);    
}
unittest
{
    short16 R = cast(short16) _mm256_max_epi16(_mm256_setr_epi16(32767, 1, -4, -8, 9,     7, 0,-57, 1, 0, 0, 0, 1, 0, 0, 0),
                                               _mm256_setr_epi16(   -4,-8,  9,  7, 0,-32768, 0,  0, 0, 2, 0, 4, 2, 1, 2, -4));
    short[16] correct =                                         [32767, 1,  9,  7, 9,     7, 0,  0, 1, 2, 0, 4, 2, 1, 2, 0];
    assert(R.array == correct);
}

/// Compare packed signed 32-bit integers in `a` and `b`, and return packed maximum values.
__m256i _mm256_max_epi32 (__m256i a, __m256i b) pure @safe
{
    // PERF D_SIMD
    version(GNU)
        enum bool split = true;
    else static if (SIMD_COMPARISON_MASKS_32B)
        enum bool split = false;
    else
        enum bool split = true;

    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pmaxsd256(cast(int8)a, cast(int8)b);
    }
    else static if (split)
    {
        // split
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i b_lo = _mm256_extractf128_si256!0(b);
        __m128i b_hi = _mm256_extractf128_si256!1(b);
        __m128i r_lo = _mm_max_epi32(a_lo, b_lo);
        __m128i r_hi = _mm_max_epi32(a_hi, b_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
    else static if (SIMD_COMPARISON_MASKS_32B) 
    {
        // catastrophic with GDC x86 for some reason, like for 16-bit numbers.
        int8 sa = cast(int8)a;
        int8 sb = cast(int8)b;
        int8 greater = sa > sb;
        return cast(__m256i)( (greater & sa) | (~greater & sb) );
    }
    else
        static assert(0);    
}
unittest
{
    int8 R = cast(int8) _mm256_max_epi32(_mm256_setr_epi32(0x7fffffff, 1, -4,  7, 0x7fffffff, 2, -4,  7),
                                         _mm256_setr_epi32(        -4,-8,  9, -8,-0x80000000,-8,  9, -8));
    int[8] correct =                                      [0x7fffffff, 1,  9,  7, 0x7fffffff, 2,  9,  7];
    assert(R.array == correct);
}

/// Compare packed signed 8-bit integers in `a` and `b`, and return packed maximum values.
__m256i _mm256_max_epi8 (__m256i a, __m256i b) pure @trusted
{
    // PERF D_SIMD
    version(GNU)
        enum bool split = true;
    else static if (SIMD_COMPARISON_MASKS_32B)
        enum bool split = false;
    else
        enum bool split = true;
    static if (GDC_with_AVX2)
    {
        // Strangely, GDC asks for unsigned ubyte32
        return cast(__m256i) __builtin_ia32_pmaxsb256(cast(ubyte32)a, cast(ubyte32)b);
    }
    else static if (split)
    {
        // split
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i b_lo = _mm256_extractf128_si256!0(b);
        __m128i b_hi = _mm256_extractf128_si256!1(b);
        __m128i r_lo = _mm_max_epi8(a_lo, b_lo);
        __m128i r_hi = _mm_max_epi8(a_hi, b_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
    else static if (SIMD_COMPARISON_MASKS_32B)
    {
        // This is real bad with GDC, again
        byte32 sa = cast(byte32)a;
        byte32 sb = cast(byte32)b;
        byte32 greater = cast(byte32)(sa > sb);
        return cast(__m256i)( (greater & sa) | (~greater & sb) );
    }
    else
        static assert(false);
}
unittest
{
    __m256i A = _mm256_setr_epi8(127,  1, -4, -8, 9,    7, 0, 57, 0, 0, 0, 0, 0, 0, 0, 0,   127,  1, -4, -8, 9,    7, 0, 57, 0, 0, 0, 0, 0, 0, 0, 0);
    __m256i B = _mm256_setr_epi8(  4, -8,  9, -7, 0, -128, 0,  0, 0, 0, 0, 0, 0, 0, 0, 0,     4, -8,  9, -7, 0, -128, 0,  0, 0, 0, 0, 0, 0, 4, 0, 0);
    byte32 R = cast(byte32) _mm256_max_epi8(A, B);
    byte[32] correct =          [127,  1,  9, -7, 9,    7, 0, 57, 0, 0, 0, 0, 0, 0, 0, 0,   127,  1,  9, -7, 9,    7, 0, 57, 0, 0, 0, 0, 0, 4, 0, 0];
    assert(R.array == correct);
}

/// Compare packed unsigned 16-bit integers in `a` and `b`, and return packed maximum values.
__m256i _mm256_max_epu16 (__m256i a, __m256i b) pure @trusted
{
    // PERF D_SIMD
    version(GNU)
        enum bool split = true;
    else static if (SIMD_COMPARISON_MASKS_32B)
        enum bool split = false;
    else
        enum bool split = true;

    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pmaxuw256(cast(short16)a, cast(short16)b);
    }
    else static if (split)
    {
        // split
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i b_lo = _mm256_extractf128_si256!0(b);
        __m128i b_hi = _mm256_extractf128_si256!1(b);
        __m128i r_lo = _mm_max_epu16(a_lo, b_lo);
        __m128i r_hi = _mm_max_epu16(a_hi, b_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
    else static if (SIMD_COMPARISON_MASKS_32B)
    {
        // catastrophic with GDC x86_64, good with LDC
        short16 sa = cast(short16)a;
        short16 sb = cast(short16)b;
        short16 greater = cast(short16)(cast(ushort16)sa > cast(ushort16)sb);
        return cast(__m256i)( (greater & sa) | (~greater & sb) );
    }
    else
        static assert(false);
}
unittest
{
    short16 R = cast(short16) _mm256_max_epu16(_mm256_setr_epi16(32767, 1, -4, -8, 9,     7, 0,-57, 1, 0, 0, 0, 1, 0, 0, -6),
                                                _mm256_setr_epi16(  -4,-8,  9,  7, 0,-32768, 0,  0, 0, 2, 0, 4, 2, 1, 2, -4));
    short[16] correct =                                            [-4,-8, -4, -8, 9,-32768, 0,-57, 1, 2, 0, 4, 2, 1, 2, -4];
    assert(R.array == correct);
}

/// Compare packed unsigned 32-bit integers in `a` and `b`, and return packed maximum values.
__m256i _mm256_max_epu32 (__m256i a, __m256i b) pure @safe
{
    // PERF D_SIMD
    version(GNU)
        enum bool split = true;
    else static if (SIMD_COMPARISON_MASKS_32B)
        enum bool split = false;
    else
        enum bool split = true;

    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pmaxud256(cast(int8)a, cast(int8)b);
    }
    else static if (split)
    {
        // split
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i b_lo = _mm256_extractf128_si256!0(b);
        __m128i b_hi = _mm256_extractf128_si256!1(b);
        __m128i r_lo = _mm_max_epu32(a_lo, b_lo);
        __m128i r_hi = _mm_max_epu32(a_hi, b_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
    else static if (SIMD_COMPARISON_MASKS_32B) 
    {
        // catastrophic with GDC x86 for some reason, like for 16-bit numbers.
        uint8 sa = cast(uint8)a;
        uint8 sb = cast(uint8)b;
        uint8 greater = sa > sb;
        return cast(__m256i)( (greater & sa) | (~greater & sb) );
    }
    else
        static assert(0);
}
unittest
{
    int8 R = cast(int8) _mm256_max_epu32(_mm256_setr_epi32(0x7fffffff, 1,  4, -7, 0x7fffffff, 1, 11, -7),
                                         _mm256_setr_epi32(        -4,-8,  9, -8,         -4,-8,  9, -8));
    int[8] correct =                                      [        -4,-8,  9, -7,         -4,-8, 11, -7];
    assert(R.array == correct);
}

/// Compare packed unsigned 8-bit integers in `a` and `b`, and return packed maximum values.
__m256i _mm256_max_epu8 (__m256i a, __m256i b) pure @safe
{
    // PERF D_SIMD
    version(GNU)
        enum bool split = true;
    else static if (SIMD_COMPARISON_MASKS_32B)
        enum bool split = false;
    else
        enum bool split = true;
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pmaxub256(cast(ubyte32)a, cast(ubyte32)b);
    }
    else static if (split)
    {
        // split
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i b_lo = _mm256_extractf128_si256!0(b);
        __m128i b_hi = _mm256_extractf128_si256!1(b);
        __m128i r_lo = _mm_max_epu8(a_lo, b_lo);
        __m128i r_hi = _mm_max_epu8(a_hi, b_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
    else static if (SIMD_COMPARISON_MASKS_32B)
    {
        // This is real bad with GDC, again
        ubyte32 sa = cast(ubyte32)a;
        ubyte32 sb = cast(ubyte32)b;
        ubyte32 greater = cast(ubyte32)(sa > sb);
        return cast(__m256i)( (greater & sa) | (~greater & sb) );
    }
    else
        static assert(false);
}
unittest
{
    byte32 R = cast(byte32) _mm256_max_epu8(_mm256_setr_epi8(45, 1, -4, -8, 9,  7, 0,-57, -4,-8,  9,  7, 0,-57, 0,  0,   45, 1, -4, -8, 9,  7, 0,-57, -4,-8,  9,  7, 0,-57, 0,  0),
                                            _mm256_setr_epi8(-4,-8,  9,  7, 0,-57, 0,  0, 45, 1, -4, -8, 9,  7, 0,-57,   -4,-8,  9,  7, 0,-57, 0,  0, 45, 1, -4, -8, 9,  7, 0,-57));
    byte[32] correct =                                      [-4,-8, -4, -8, 9,-57, 0,-57, -4,-8, -4, -8, 9,-57, 0,-57,   -4,-8, -4, -8, 9,-57, 0,-57, -4,-8, -4, -8, 9,-57, 0,-57];
    assert(R.array == correct);
}

// Compare packed signed 16-bit integers in `a` and `b`, and return packed minimum values.
__m256i _mm256_min_epi16 (__m256i a, __m256i b) pure @safe
{
    // PERF D_SIMD
    version(GNU)
        enum bool split = true;
    else static if (SIMD_COMPARISON_MASKS_32B)
        enum bool split = false;
    else
        enum bool split = true;

    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pminsw256(cast(short16)a, cast(short16)b);
    }
    else static if (split)
    {
        // split
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i b_lo = _mm256_extractf128_si256!0(b);
        __m128i b_hi = _mm256_extractf128_si256!1(b);
        __m128i r_lo = _mm_min_epi16(a_lo, b_lo);
        __m128i r_hi = _mm_min_epi16(a_hi, b_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
    else static if (SIMD_COMPARISON_MASKS_32B)
    {
        // same as _mm256_min_epi16, this is catastrophic with GDC -mavx
        short16 sa = cast(short16)a;
        short16 sb = cast(short16)b;
        short16 greater = sa > sb;
        return cast(__m256i)( (~greater & sa) | (greater & sb) );
    }
    else
        static assert(0);
}
unittest
{
    short16 R = cast(short16) _mm256_min_epi16(_mm256_setr_epi16(32767, 1, -4, -8, 9,     7, 0,-57, 1, 0, 0, 0, 1, 0, 0,  0),
                                               _mm256_setr_epi16(   -4,-8,  9,  7, 0,-32768, 0,  0, 0, 2, 0, 4, 2, 1, 2, -4));
    short[16] correct =                                         [   -4,-8, -4, -8, 0,-32768, 0,-57, 0, 0, 0, 0, 1, 0, 0, -4];
    assert(R.array == correct);
}

/// Compare packed signed 32-bit integers in `a` and `b`, and return packed minimum values.
__m256i _mm256_min_epi32 (__m256i a, __m256i b) pure @safe
{
    // PERF D_SIMD
    version(GNU)
        enum bool split = true;
    else static if (SIMD_COMPARISON_MASKS_32B)
        enum bool split = false;
    else
        enum bool split = true;

    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pminsd256(cast(int8)a, cast(int8)b);
    }
    else static if (split)
    {
        // split
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i b_lo = _mm256_extractf128_si256!0(b);
        __m128i b_hi = _mm256_extractf128_si256!1(b);
        __m128i r_lo = _mm_min_epi32(a_lo, b_lo);
        __m128i r_hi = _mm_min_epi32(a_hi, b_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
    else static if (SIMD_COMPARISON_MASKS_32B) 
    {
        // Not checked this one, probably same badness issue with GDC
        int8 sa = cast(int8)a;
        int8 sb = cast(int8)b;
        int8 greater = sa > sb;
        return cast(__m256i)( (~greater & sa) | (greater & sb) );
    }
    else
        static assert(0);    
}
unittest
{
    int8 R = cast(int8) _mm256_min_epi32(_mm256_setr_epi32(0x7fffffff, 1, -4,  7, 0x7fffffff, 2, -4,  7),
                                         _mm256_setr_epi32(        -4,-8,  9, -8,-0x80000000,-8,  9, -8));
    int[8] correct =                                      [ -       4,-8, -4, -8,-0x80000000,-8, -4, -8];
    assert(R.array == correct);
}


/// Compare packed signed 8-bit integers in `a` and `b`, and return packed minimum values.
__m256i _mm256_min_epi8 (__m256i a, __m256i b) pure @trusted
{
    // PERF D_SIMD
    version(GNU)
        enum bool split = true;
    else static if (SIMD_COMPARISON_MASKS_32B)
        enum bool split = false;
    else
        enum bool split = true;
    static if (GDC_with_AVX2)
    {
        // Strangely, GDC asks for unsigned ubyte32
        return cast(__m256i) __builtin_ia32_pminsb256(cast(ubyte32)a, cast(ubyte32)b);
    }
    else static if (split)
    {
        // split
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i b_lo = _mm256_extractf128_si256!0(b);
        __m128i b_hi = _mm256_extractf128_si256!1(b);
        __m128i r_lo = _mm_min_epi8(a_lo, b_lo);
        __m128i r_hi = _mm_min_epi8(a_hi, b_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
    else static if (SIMD_COMPARISON_MASKS_32B)
    {
        // This is real bad with GDC, again
        byte32 sa = cast(byte32)a;
        byte32 sb = cast(byte32)b;
        byte32 greater = cast(byte32)(sa > sb);
        return cast(__m256i)( (~greater & sa) | (greater & sb) );
    }
    else
        static assert(false);
}
unittest
{
    __m256i A = _mm256_setr_epi8(127,  1, -4, -8, 9,    7, 0, -57, 0, 0, 0, 0, 0, 0, 0, 0,   127,  1, -4, -8, 9,    7, 0, 57, 0, 0, 0, 0, 0, 0, 0, 0);
    __m256i B = _mm256_setr_epi8(  4, -8,  9, -7, 0, -128, 0,   0, 0, 0, 0, 0, 0, 0, 0, 0,     4, -8,  9, -7, 0, -128, 0,  0, 0, 0, 0, 0, 0, -4, 0, 0);
    byte32 R = cast(byte32) _mm256_min_epi8(A, B);
    byte[32] correct =          [  4, -8, -4, -8, 0, -128, 0, -57, 0, 0, 0, 0, 0, 0, 0, 0,     4, -8, -4, -8, 0, -128, 0,  0, 0, 0, 0, 0, 0, -4, 0, 0];
    assert(R.array == correct);
}

/// Compare packed unsigned 16-bit integers in `a` and `b`, and return packed minimum values.
__m256i _mm256_min_epu16 (__m256i a, __m256i b) pure @trusted
{
    // PERF D_SIMD
    version(GNU)
        enum bool split = true;
    else static if (SIMD_COMPARISON_MASKS_32B)
        enum bool split = false;
    else
        enum bool split = true;

    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pminuw256(cast(short16)a, cast(short16)b);
    }
    else static if (split)
    {
        // split
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i b_lo = _mm256_extractf128_si256!0(b);
        __m128i b_hi = _mm256_extractf128_si256!1(b);
        __m128i r_lo = _mm_min_epu16(a_lo, b_lo);
        __m128i r_hi = _mm_min_epu16(a_hi, b_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
    else static if (SIMD_COMPARISON_MASKS_32B)
    {
        // catastrophic with GDC x86_64
        short16 sa = cast(short16)a;
        short16 sb = cast(short16)b;
        short16 greater = cast(short16)(cast(ushort16)sa > cast(ushort16)sb);
        return cast(__m256i)( (~greater & sa) | (greater & sb) );
    }
    else
        static assert(false);
}
unittest
{
    short16 R = cast(short16) _mm256_min_epu16(_mm256_setr_epi16(32767, 1, -4, -8, 9,     7, 0,-57, 1, 0, 0, 0, 1, 0, 0, -6),
                                               _mm256_setr_epi16(  -4, -8,  9,  7, 0,-32768, 0,  0, 0, 2, 0, 4, 2, 1, 2, -4));
    short[16] correct =                                         [32767, 1,  9,  7, 0,     7, 0,  0, 0, 0, 0, 0, 1, 0, 0, -6];
    assert(R.array == correct);
}

/// Compare packed unsigned 32-bit integers in `a` and `b`, and return packed minimum values.
__m256i _mm256_min_epu32 (__m256i a, __m256i b) pure @safe
{
    // PERF D_SIMD
    version(GNU)
        enum bool split = true;
    else static if (SIMD_COMPARISON_MASKS_32B)
        enum bool split = false;
    else
        enum bool split = true;

    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pminud256(cast(int8)a, cast(int8)b);
    }
    else static if (split)
    {
        // split
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i b_lo = _mm256_extractf128_si256!0(b);
        __m128i b_hi = _mm256_extractf128_si256!1(b);
        __m128i r_lo = _mm_min_epu32(a_lo, b_lo);
        __m128i r_hi = _mm_min_epu32(a_hi, b_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
    else static if (SIMD_COMPARISON_MASKS_32B) 
    {
        // catastrophic with GDC, so in this case split instead
        uint8 sa = cast(uint8)a;
        uint8 sb = cast(uint8)b;
        uint8 greater = sa > sb;
        return cast(__m256i)( (greater & sb) | (~greater & sa) );
    }
    else
        static assert(0);
}
unittest
{
    int8 R = cast(int8) _mm256_min_epu32(_mm256_setr_epi32(0x7fffffff, 1,  4, -7, 0x7fffffff, 1, 11, -7),
                                         _mm256_setr_epi32(        -4,-8,  9, -8,         -4,-8,  9, -8));
    int[8] correct =                                      [0x7fffffff, 1,  4, -8, 0x7fffffff, 1,  9, -8];
    assert(R.array == correct);
}

/// Compare packed unsigned 8-bit integers in `a` and `b`, and return packed minimum values.
__m256i _mm256_min_epu8 (__m256i a, __m256i b) pure @safe
{
    // PERF D_SIMD
    version(GNU)
        enum bool split = true;
    else static if (SIMD_COMPARISON_MASKS_32B)
        enum bool split = false;
    else
        enum bool split = true;
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pminub256(cast(ubyte32)a, cast(ubyte32)b);
    }
    else static if (split)
    {
        // split
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i b_lo = _mm256_extractf128_si256!0(b);
        __m128i b_hi = _mm256_extractf128_si256!1(b);
        __m128i r_lo = _mm_min_epu8(a_lo, b_lo);
        __m128i r_hi = _mm_min_epu8(a_hi, b_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
    else static if (SIMD_COMPARISON_MASKS_32B)
    {
        ubyte32 sa = cast(ubyte32)a;
        ubyte32 sb = cast(ubyte32)b;
        ubyte32 greater = cast(ubyte32)(sa > sb);
        return cast(__m256i)( (~greater & sa) | (greater & sb) );
    }
    else
        static assert(false);
}
unittest
{
    byte32 R = cast(byte32) _mm256_min_epu8(_mm256_setr_epi8(45, 1, -4, -8, 9,  7, 0,-57, -4,-8,  9,  7, 0,-57, 0,  0,   45, 1, -4, -8, 9,  7, 0,-57, -4,-8,  9,  7, 0,-57, 0,  0),
                                            _mm256_setr_epi8(-4,-8,  9,  7, 0,-57, 0,  0, 45, 1, -4, -8, 9,  7, 0,-57,   -4,-8,  9,  7, 0,-57, 0,  0, 45, 1, -4, -8, 9,  7, 0,-57));
    byte[32] correct =                                      [45, 1,  9,  7, 0,  7, 0,  0, 45, 1,  9,  7, 0,  7, 0,  0,   45, 1,  9,  7, 0,  7, 0,  0, 45, 1,  9,  7, 0,  7, 0,  0];
    assert(R.array == correct);
}

/// Create mask from the most significant bit of each 8-bit element in `a`.
int _mm256_movemask_epi8 (__m256i a) pure @trusted
{
    static if (GDC_with_AVX2)
    {
        return __builtin_ia32_pmovmskb256(cast(ubyte32)a);
    }
    else static if (LDC_with_AVX2)
    {
        return __builtin_ia32_pmovmskb256(cast(byte32)a);
    }
    else
    {
        // ARM64 splitting makes it 33 inst instead of 48 for naive version.
        //       PERF not sure if there is something better, sounds likely
        // Otherwise, beneficial for every case.
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        return (_mm_movemask_epi8(a_hi) << 16) | _mm_movemask_epi8(a_lo);
    }
}
unittest
{
    assert(0x9D37_9C36 == _mm256_movemask_epi8(_mm256_set_epi8(-1, 1, 2, -3, -1, -1, 4,-8, 127, 0, -1, -1, 0, -1, -1, -1,
                                                               -1, 1, 2, -3, -1, -1, 4, 8, 127, 0, -1, -1, 0, -1, -1, 0)));
}

// TODO __m256i _mm256_mpsadbw_epu8 (__m256i a, __m256i b, const int imm8) pure @safe

/// Multiply the low signed 32-bit integers from each packed 64-bit element in `a` and `b`, and 
/// return the signed 64-bit results.
__m256i _mm256_mul_epi32 (__m256i a, __m256i b) pure @trusted
{
    // PERF LDC + SSE2 to SSSE3. I don't quite see what to do, same problem in _mm_mul_epi32.
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pmuldq256(cast(int8)a, cast(int8)b);
    }
    else static if ( (LDC_with_SSE41 || LDC_with_AVX2) && LDC_with_optimizations) 
    {
        // good with LDC + SSE4.1 to AVX2, else need to split
        enum ir = `
            %ia = shufflevector <8 x i32> %0,<8 x i32> %0, <4 x i32> <i32 0, i32 2, i32 4, i32 6>
            %ib = shufflevector <8 x i32> %1,<8 x i32> %1, <4 x i32> <i32 0, i32 2, i32 4, i32 6>
            %la = sext <4 x i32> %ia to <4 x i64>
            %lb = sext <4 x i32> %ib to <4 x i64>
            %r = mul <4 x i64> %la, %lb
            ret <4 x i64> %r`;
        return cast(__m256i) LDCInlineIR!(ir, long4, int8, int8)(cast(int8)a, cast(int8)b);
    }
    else
    {
        // split, very beneficial with LDC+ARM64
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i b_lo = _mm256_extractf128_si256!0(b);
        __m128i b_hi = _mm256_extractf128_si256!1(b);
        __m128i r_lo = _mm_mul_epi32(a_lo, b_lo);
        __m128i r_hi = _mm_mul_epi32(a_hi, b_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
}
unittest
{
    __m256i A = _mm256_setr_epi32(61616461, 1915324654, 4564061, 3, 61616466, 1915324654, 4564061, 3);
    __m256i B = _mm256_setr_epi32(49716422, -915616216, -121144, 0, 49716422, -915616216, -121145, 0);
    long4 R = cast(long4) _mm256_mul_epi32(A, B);
    long[4] correct = [cast(long)61616461 * 49716422, cast(long)4564061 * -121144, cast(long)61616466 * 49716422, cast(long)4564061 * -121145];
    assert(R.array == correct);
}

/// Multiply the low unsigned 32-bit integers from each packed 64-bit element in `a` and `b`, and 
/// return the unsigned 64-bit results.
__m256i _mm256_mul_epu32 (__m256i a, __m256i b) pure @trusted
{
    // PERF DMD
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pmuludq256(cast(int8)a, cast(int8)b);
    }
    else version(GNU)
    {
        // explicit split needed for GDC without avx2
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i b_lo = _mm256_extractf128_si256!0(b);
        __m128i b_hi = _mm256_extractf128_si256!1(b);
        __m128i r_lo = _mm_mul_epu32(a_lo, b_lo);
        __m128i r_hi = _mm_mul_epu32(a_hi, b_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }       
    else
    {
        // Works well in all LDC cases, surprisingly.
        int8 ia = cast(int8)a;
        int8 ib = cast(int8)b;
        long4 r;
        r.ptr[0] = cast(long)cast(uint)ia.array[0] * cast(long)cast(uint)ib.array[0];
        r.ptr[1] = cast(long)cast(uint)ia.array[2] * cast(long)cast(uint)ib.array[2];
        r.ptr[2] = cast(long)cast(uint)ia.array[4] * cast(long)cast(uint)ib.array[4];
        r.ptr[3] = cast(long)cast(uint)ia.array[6] * cast(long)cast(uint)ib.array[6];
        return cast(__m256i)r;
    }
}
unittest
{
    __m256i A = _mm256_set_epi32(42, 0xDEADBEEF, 42, 0xffffffff, 42, 0xDEADBEEF, 42, 0xffffffff);
    __m256i B = _mm256_set_epi32(42, 0xCAFEBABE, 42, 0xffffffff, 42, 0xCAFEBABE, 42, 0xffffffff);
    __m256i C = _mm256_mul_epu32(A, B);
    long4 LC = cast(long4)C;
    long[4] correct = [18446744065119617025uL, 12723420444339690338uL, 18446744065119617025uL, 12723420444339690338uL];
    assert(LC.array == correct);
}

/// Multiply the packed signed 16-bit integers in `a` and `b`, 
/// producing intermediate 32-bit integers, and return the high 
/// 16 bits of the intermediate integers.
__m256i _mm256_mulhi_epi16 (__m256i a, __m256i b) pure @safe
{
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pmulhw256(cast(short16)a, cast(short16)b);
    }
    else static if (LDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pmulhw256(cast(short16)a, cast(short16)b);
    }
    else
    {
        // split
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i b_lo = _mm256_extractf128_si256!0(b);
        __m128i b_hi = _mm256_extractf128_si256!1(b);
        __m128i r_lo = _mm_mulhi_epi16(a_lo, b_lo);
        __m128i r_hi = _mm_mulhi_epi16(a_hi, b_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
}
unittest
{
    __m256i A = _mm256_setr_epi16(0, -16, 2, 3, 4, 8, 16, 7, 0, -16, 2, 3, 4, 8, 16, 8);
    __m256i B = _mm256_set1_epi16(16384);
    short16 R = cast(short16)_mm256_mulhi_epi16(A, B);
    short[16] correct = [0, -4, 0, 0, 1, 2, 4, 1, 0, -4, 0, 0, 1, 2, 4, 2];
    assert(R.array == correct);
}

/// Multiply the packed unsigned 16-bit integers in `a` and `b`, 
/// producing intermediate 32-bit integers, and return the high 
/// 16 bits of the intermediate integers.
__m256i _mm256_mulhi_epu16 (__m256i a, __m256i b) pure @safe
{
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pmulhuw256(cast(short16)a, cast(short16)b);
    }
    else static if (LDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pmulhuw256(cast(short16)a, cast(short16)b);
    }
    else
    {
        // split
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i b_lo = _mm256_extractf128_si256!0(b);
        __m128i b_hi = _mm256_extractf128_si256!1(b);
        __m128i r_lo = _mm_mulhi_epu16(a_lo, b_lo);
        __m128i r_hi = _mm_mulhi_epu16(a_hi, b_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
}

// TODO __m256i _mm256_mulhrs_epi16 (__m256i a, __m256i b) pure @safe

/// Multiply the packed signed 16-bit integers in `a` and `b`, producing intermediate 32-bit integers, 
/// and return the low 16 bits of the intermediate integers.
__m256i _mm256_mullo_epi16 (__m256i a, __m256i b) pure @safe
{
    // PERF D_SIMD
    static if (GDC_with_AVX)
    {
        return cast(__m256i)(cast(short16)a * cast(short16)b);
    }
    else version(LDC)
    {
        return cast(__m256i)(cast(short16)a * cast(short16)b);
    }
    else
    {
        // split
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i b_lo = _mm256_extractf128_si256!0(b);
        __m128i b_hi = _mm256_extractf128_si256!1(b);
        __m128i r_lo = _mm_mullo_epi16(a_lo, b_lo);
        __m128i r_hi = _mm_mullo_epi16(a_hi, b_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
}
unittest
{
    __m256i A = _mm256_setr_epi16(16384, -16, 0,      3, 4, 1, 16, 7, 16384, -16, 0,      3, 4, 1, 16, 7);
    __m256i B = _mm256_set1_epi16(16384);
    short16 R = cast(short16)_mm256_mullo_epi16(A, B);
    short[16] correct = [0, 0, 0, -16384, 0, 16384, 0, -16384, 0, 0, 0, -16384, 0, 16384, 0, -16384];
    assert(R.array == correct);
}

/// Multiply the packed signed 32-bit integers in `a` and `b`, producing intermediate 64-bit integers,
/// and store the low 32 bits of the intermediate integer.
__m256i _mm256_mullo_epi32 (__m256i a, __m256i b) pure @safe
{
    // PERF D_SIMD
    static if (GDC_with_AVX)
    {
        return cast(__m256i)(cast(int8)a * cast(int8)b);
    }
    else version(LDC)
    {
        return cast(__m256i)(cast(int8)a * cast(int8)b);
    }
    else
    {
        // split
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i b_lo = _mm256_extractf128_si256!0(b);
        __m128i b_hi = _mm256_extractf128_si256!1(b);
        __m128i r_lo = _mm_mullo_epi32(a_lo, b_lo);
        __m128i r_hi = _mm_mullo_epi32(a_hi, b_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
}
unittest
{
    __m256i A = _mm256_setr_epi32(61616461, 1915324654, 4564061, 3, 61616461, 1915324654, 4564061, 3);
    __m256i B = _mm256_setr_epi32(49716422, -915616216, -121144, 0, 49716422, -915616216, -121144, 1);
    int8 R = cast(int8) _mm256_mullo_epi32(A, B);
    int[8] correct = [cast(int)0xBF370D8E, cast(int)(1915324654 * -915616216), cast(int)(4564061 * -121144), 0,
                      cast(int)0xBF370D8E, cast(int)(1915324654 * -915616216), cast(int)(4564061 * -121144), 3];
    assert(R.array == correct);
}

/// Compute the bitwise OR of 256 bits (representing integer data) in `a` and `b`.
__m256i _mm256_or_si256 (__m256i a, __m256i b) pure @safe
{
    return a | b;
}
unittest
{
    long A = 0x55555555_55555555;
    long B = 0xAAAAAAAA_AAAAAAAA;
    __m256i vA = _mm256_set_epi64(A, B, A, B);
    __m256i vB = _mm256_set_epi64(B, A, 0, B);
    __m256i R  = _mm256_or_si256(vA, vB);
    long[4] correct = [B, A, -1, -1];
    assert(R.array == correct);
}

/// Convert packed signed 16-bit integers from `a` and `b `to packed 8-bit integers using signed saturation.
/// Warning: `a` and `b` are interleaved per-lane. 
///           Result has: `a` lane 0, `b` lane 0, `a` lane 1, `b` lane 1.
__m256i _mm256_packs_epi16 (__m256i a, __m256i b) pure @safe
{
    // PERF D_SIMD
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_packsswb256(cast(short16)a, cast(short16)b);
    }
    else static if (LDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_packsswb256(cast(short16)a, cast(short16)b);
    }
    else
    {
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i b_lo = _mm256_extractf128_si256!0(b);
        __m128i b_hi = _mm256_extractf128_si256!1(b);
        __m128i r_lo = _mm_packs_epi16(a_lo, b_lo);
        __m128i r_hi = _mm_packs_epi16(a_hi, b_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
}
unittest
{
    __m256i A = _mm256_setr_epi16(1000, -1000, 1000, 0, 256, -129, 254, 0, 
                                 -1000, -1000, 1000, 0, 256, -129, 254, 0);
    byte32 R = cast(byte32) _mm256_packs_epi16(A, A);
    byte[32] correct = [127, -128, 127, 0, 127, -128, 127, 0,
                        127, -128, 127, 0, 127, -128, 127, 0,
                       -128, -128, 127, 0, 127, -128, 127, 0,
                       -128, -128, 127, 0, 127, -128, 127, 0];
    assert(R.array == correct);
}

/// Convert packed signed 32-bit integers from `a` and `b `to packed 16-bit integers using signed saturation.
/// Warning: `a` and `b` are interleaved per-lane.
///           Result has: `a` lane 0, `b` lane 0, `a` lane 1, `b` lane 1.
__m256i _mm256_packs_epi32 (__m256i a, __m256i b) pure @safe
{
    // PERF D_SIMD
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_packssdw256(cast(int8)a, cast(int8)b);
    }
    else static if (LDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_packssdw256(cast(int8)a, cast(int8)b);
    }
    else
    {
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i b_lo = _mm256_extractf128_si256!0(b);
        __m128i b_hi = _mm256_extractf128_si256!1(b);
        __m128i r_lo = _mm_packs_epi32(a_lo, b_lo);
        __m128i r_hi = _mm_packs_epi32(a_hi, b_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
}
unittest
{
    __m256i A = _mm256_setr_epi32(100000, -100000, 1000, 0, 4, 5, -100000, 7);
    short16 R = cast(short16) _mm256_packs_epi32(A, A);
    short[16] correct = [32767, -32768, 1000, 0, 32767, -32768, 1000, 0, 4, 5, -32768, 7, 4, 5, -32768, 7];
    assert(R.array == correct);
}


/// Convert packed signed 16-bit integers from `a` and `b `to packed 8-bit integers using unsigned saturation.
/// Warning: `a` and `b` are interleaved per-lane. 
///           Result has: `a` lane 0, `b` lane 0, `a` lane 1, `b` lane 1.
__m256i _mm256_packus_epi16 (__m256i a, __m256i b) pure @trusted
{
    // PERF D_SIMD
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_packuswb256(cast(short16)a, cast(short16)b);
    }
    else static if (LDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_packuswb256(cast(short16)a, cast(short16)b);
    }
    else
    {
        // Always beneficial with LDC.
        // arm64: 4 inst with LDC  -O1
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i b_lo = _mm256_extractf128_si256!0(b);
        __m128i b_hi = _mm256_extractf128_si256!1(b);
        __m128i r_lo = _mm_packus_epi16(a_lo, b_lo);
        __m128i r_hi = _mm_packus_epi16(a_hi, b_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
}
unittest
{
    __m256i A = _mm256_setr_epi16(-10, 400, 0, 256, 255, 2, 1, 0, -10, 400,  0, 256, -32768,  2,  1, 0);
    __m256i B = _mm256_setr_epi16(  0,   1, 2,   3,   4, 5, 6, 7,   8,   9, 10,  11,     12, 13, 14, 15);
    byte32 R = cast(byte32) _mm256_packus_epi16(A, B);
   align(32) static immutable byte[32] correctResult = [0, -1, 0, -1, -1, 2, 1, 0, 0, 1,  2,  3,  4,  5,  6,  7,
                                                        0, -1, 0, -1, 0  , 2, 1, 0, 8, 9, 10, 11, 12, 13, 14, 15];
    assert(R.array == correctResult);
}

/// Convert packed signed 32-bit integers from `a` and `b `to packed 16-bit integers using unsigned saturation.
/// Warning: `a` and `b` are interleaved per-lane.
///           Result has: `a` lane 0, `b` lane 0, `a` lane 1, `b` lane 1.
__m256i _mm256_packus_epi32 (__m256i a, __m256i b) pure @safe
{
    // PERF D_SIMD
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_packusdw256(cast(int8)a, cast(int8)b);
    }
    else static if (LDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_packusdw256(cast(int8)a, cast(int8)b);
    }
    else
    {
        // 8 inst in arm64 since LDC 1.22 -O2,
        // sounds a bit underperforming maybe
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i b_lo = _mm256_extractf128_si256!0(b);
        __m128i b_hi = _mm256_extractf128_si256!1(b);
        __m128i r_lo = _mm_packus_epi32(a_lo, b_lo);
        __m128i r_hi = _mm_packus_epi32(a_hi, b_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
}
unittest
{
    __m256i A = _mm256_setr_epi32(100000, -100000, 1000, 0, 100000, -100000, 1000, 1);
    short16 R = cast(short16) _mm256_packus_epi32(A, A);
    short[16] correct = [cast(short)65535, 0, 1000, 0, cast(short)65535, 0, 1000, 0,
                         cast(short)65535, 0, 1000, 1, cast(short)65535, 0, 1000, 1];
    assert(R.array == correct);
}



// TODO __m256i _mm256_permute2x128_si256 (__m256i a, __m256i b, const int imm8) pure @safe

/// Shuffle 64-bit integers in `a` across lanes using the control in `imm8`.
__m256i _mm256_permute4x64_epi64(int imm8)(__m256i a) pure @trusted
{
    static if (GDC_with_AVX2)
        return cast(__m256i) __builtin_ia32_permdi256(a, imm8);
    else static if (LDC_with_optimizations)
    {
        return shufflevector!(long4, (imm8 >> 0) & 3,
                              (imm8 >> 2) & 3,
                              (imm8 >> 4) & 3,
                              (imm8 >> 6) & 3)(a, a);
    }
    else
    {
        __m256i b = a;
        static foreach (i; 0..4)
            a[i] = b[(imm8 & (0b00000011 << (i * 2))) >> (i * 2)];
        return a;
    }
}
unittest
{
    __m256i A = _mm256_setr_epi64x(1, 2, 3, 4);
    static immutable long[4] correct = [ 4, 3, 2, 1 ];
    assert(_mm256_permute4x64_epi64!(0b00011011)(A).array == correct);

    A = _mm256_setr_epi64x(1, 2, 3, 4);
    static immutable long[4] correct2 = [ 1, 4, 1, 1 ];
    assert(_mm256_permute4x64_epi64!(0b00001100)(A).array == correct2);
}


// TODO __m256d _mm256_permute4x64_pd (__m256d a, const int imm8) pure @safe
// TODO __m256i _mm256_permutevar8x32_epi32 (__m256i a, __m256i idx) pure @safe
// TODO __m256 _mm256_permutevar8x32_ps (__m256 a, __m256i idx) pure @safe

/// Compute the absolute differences of packed unsigned 8-bit integers in `a` and `b`, then horizontally sum each
/// consecutive 8 differences to produce two unsigned 16-bit integers, and pack these unsigned 16-bit integers in the
/// low 16 bits of 64-bit elements in result.
__m256i _mm256_sad_epu8 (__m256i a, __m256i b) pure @trusted
{
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_psadbw256(cast(ubyte32)a, cast(ubyte32)b);
    }
    else static if (LDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_psadbw256(cast(byte32)a, cast(byte32)b);
    }
    else
    {
        // split is beneficial for ARM64, LDC and GDC without AVX2
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i b_lo = _mm256_extractf128_si256!0(b);
        __m128i b_hi = _mm256_extractf128_si256!1(b);
        __m128i r_lo = _mm_sad_epu8(a_lo, b_lo);
        __m128i r_hi = _mm_sad_epu8(a_hi, b_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
}
unittest
{
    __m256i A = _mm256_setr_epi8(3, 4, 6, 8, 12, 14, 18, 20, 24, 30, 32, 38, 42, 44, 48, 54,
                              3, 4, 6, 8, 12, 14, 18, 20, 24, 30, 32, 38, 42, 44, 48, 54); // primes + 1
    __m256i B = _mm256_set1_epi8(1);
    int8 R = cast(int8) _mm256_sad_epu8(A, B);
    int[8] correct = [2 + 3 + 5 + 7 + 11 + 13 + 17 + 19,
                      0,
                      23 + 29 + 31 + 37 + 41 + 43 + 47 + 53,
                      0,
                      2 + 3 + 5 + 7 + 11 + 13 + 17 + 19,
                      0,
                      23 + 29 + 31 + 37 + 41 + 43 + 47 + 53,
                      0];
    assert(R.array == correct);
}

/// Shuffle 32-bit integers in `a` within 128-bit lanes using the control in `imm8`, and return the results.
__m256i _mm256_shuffle_epi32(int imm8)(__m256i a) pure @trusted
{
    static if (GDC_with_AVX2)
        return cast(__m256i)__builtin_ia32_pshufd256(cast(int8)a, imm8);
    else static if (LDC_with_AVX2)
    {
        return cast(__m256i)shufflevectorLDC!(int8,
            (imm8 >> 0) & 3,
            (imm8 >> 2) & 3,
            (imm8 >> 4) & 3,
            (imm8 >> 6) & 3,
            ((imm8 >> 0) & 3) + 4,
            ((imm8 >> 2) & 3) + 4,
            ((imm8 >> 4) & 3) + 4,
            ((imm8 >> 6) & 3) + 4)(cast(int8)a, cast(int8)a);
    }
    else
    {
        auto hi = _mm_shuffle_epi32!imm8(_mm256_extractf128_si256!0(a));
        auto lo = _mm_shuffle_epi32!imm8(_mm256_extractf128_si256!1(a));
        return _mm256_setr_m128i(hi, lo);
    }
}
unittest
{
    __m256i a = _mm256_set_epi32(32, 31, 30, 29, 28, 27, 26, 25);
    assert(_mm256_shuffle_epi32!255(a).array == [120259084316L, 120259084316, 137438953504, 137438953504]);
}

/// Shuffle 8-bit integers in `a` within 128-bit lanes according to shuffle control mask in the 
/// corresponding 8-bit element of `b`.
__m256i _mm256_shuffle_epi8(__m256i a, __m256i b) pure @trusted
{
    static if (GDC_with_AVX2)
        return cast(__m256i)__builtin_ia32_pshufb256(cast(ubyte32)a, cast(ubyte32)b);
    else static if (LDC_with_AVX2)
        return cast(__m256i)__builtin_ia32_pshufb256(cast(byte32)a, cast(byte32)b);
    else
    {
        auto hi = _mm_shuffle_epi8(_mm256_extractf128_si256!0(a), _mm256_extractf128_si256!0(b));
        auto lo = _mm_shuffle_epi8(_mm256_extractf128_si256!1(a), _mm256_extractf128_si256!1(b));
        return _mm256_setr_m128i(hi, lo);
    }
}
unittest
{
    __m256i a = _mm256_set_epi8(32, 31, 30, 29, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1);
    __m256i b = _mm256_set_epi8(0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1);

    __m256i expected = _mm256_setr_epi8(
        2, 2, 2, 2, 2, 2, 2, 2, 
        1, 1, 1, 1, 1, 1, 1, 1, 
        18, 18, 18, 18, 18, 18, 18, 18, 
        17, 17, 17, 17, 17, 17, 17, 17
    );

    assert(_mm256_shuffle_epi8(a, b).array == expected.array);
}

/// Shuffle 16-bit integers in the high 64 bits of 128-bit lanes of `a` using
/// the control in `imm8`. Store the results in the high 64 bits of 128-bit lanes
/// of result, with the low 64 bits of 128-bit lanes being copied from from `a`.
/// See also: `_MM_SHUFFLE`.
__m256i _mm256_shufflehi_epi16(int imm8)(__m256i a) pure @safe
{
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pshufhw256(cast(short16)a, imm8);
    }
    else static if (LDC_with_optimizations)
    {
        return cast(__m256i) shufflevectorLDC!(short16,
            0, 1, 2, 3,
            4 + ( (imm8 >> 0) & 3 ),
            4 + ( (imm8 >> 2) & 3 ),
            4 + ( (imm8 >> 4) & 3 ),
            4 + ( (imm8 >> 6) & 3 ),
            8, 9, 10, 11,
            12 + ( (imm8 >> 0) & 3 ),
            12 + ( (imm8 >> 2) & 3 ),
            12 + ( (imm8 >> 4) & 3 ),
            12 + ( (imm8 >> 6) & 3 ))
            (cast(short16)a, cast(short16)a);
    }
    else
    {
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i r_lo = _mm_shufflehi_epi16!imm8(a_lo);
        __m128i r_hi = _mm_shufflehi_epi16!imm8(a_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
}
unittest
{
    __m256i A = _mm256_setr_epi16(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15);
    enum int SHUFFLE = _MM_SHUFFLE(0, 1, 2, 3);
    short16 B = cast(short16) _mm256_shufflehi_epi16!SHUFFLE(A);
    short[16] expectedB = [ 0, 1, 2, 3, 7, 6, 5, 4, 8, 9, 10, 11, 15, 14, 13, 12 ];
    assert(B.array == expectedB);
}

/// Shuffle 16-bit integers in the low 64 bits of 128-bit lanes of `a` using
/// the control in `imm8`. Store the results in the low 64 bits of 128-bit lanes 
/// of result, with the high 64 bits of 128-bit lanes being copied from from `a`.
/// See also: `_MM_SHUFFLE`.
__m256i _mm256_shufflelo_epi16(int imm8)(__m256i a) pure @safe
{
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pshuflw256(cast(short16)a, imm8);
    }
    else static if (LDC_with_optimizations)
    { 
        return cast(__m256i) shufflevectorLDC!(short16,
            ( (imm8 >> 0) & 3 ),
            ( (imm8 >> 2) & 3 ),
            ( (imm8 >> 4) & 3 ),
            ( (imm8 >> 6) & 3 ), 
            4, 5, 6, 7,
            ( (imm8 >> 0) & 3 ) + 8,
            ( (imm8 >> 2) & 3 ) + 8,
            ( (imm8 >> 4) & 3 ) + 8,
            ( (imm8 >> 6) & 3 ) + 8,
            12, 13, 14, 15)
            (cast(short16)a, cast(short16)a);
    }
    else
    {
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i r_lo = _mm_shufflelo_epi16!imm8(a_lo);
        __m128i r_hi = _mm_shufflelo_epi16!imm8(a_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
}
unittest
{
    __m256i A = _mm256_setr_epi16(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15);
    enum int SHUFFLE = _MM_SHUFFLE(0, 1, 2, 3);
    short16 B = cast(short16) _mm256_shufflelo_epi16!SHUFFLE(A);
    short[16] expectedB = [ 3, 2, 1, 0, 4, 5, 6, 7, 11, 10, 9, 8, 12, 13, 14, 15 ];
    assert(B.array == expectedB);
}

/// Negate packed signed 16-bit integers in `a` when the corresponding signed 8-bit integer in `b` is negative.
/// Elements in result are zeroed out when the corresponding element in `b` is zero.
__m256i _mm256_sign_epi16 (__m256i a, __m256i b) pure @safe
{
    // PERF DMD
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_psignw256(cast(short16)a, cast(short16)b);
    }
    else static if (LDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_psignw256(cast(short16)a, cast(short16)b);
    }
    else // split
    {
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i b_lo = _mm256_extractf128_si256!0(b);
        __m128i b_hi = _mm256_extractf128_si256!1(b);
        __m128i r_lo = _mm_sign_epi16(a_lo, b_lo);
        __m128i r_hi = _mm_sign_epi16(a_hi, b_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
    // PERF: not optimal in AVX without AVX2
}
unittest
{
    __m128i A = _mm_setr_epi16(-2, -1, 0, 1,  2, short.min, short.min, short.min);
    __m128i B = _mm_setr_epi16(-1,  0,-1, 1, -2,       -50,         0,        50);
    __m256i AA = _mm256_set_m128i(A, A);
    __m256i BB = _mm256_set_m128i(B, B);
    short16 C = cast(short16) _mm256_sign_epi16(AA, BB);
    short[16] correct =        [ 2,  0, 0, 1, -2, short.min,         0, short.min, 2,  0, 0, 1, -2, short.min,         0, short.min];
    assert(C.array == correct);
}

/// Negate packed signed 32-bit integers in `a` when the corresponding signed 8-bit integer in `b` is negative.
/// Elements in result are zeroed out when the corresponding element in `b` is zero.
__m256i _mm256_sign_epi32 (__m256i a, __m256i b) pure @safe
{
    // PERF DMD
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_psignd256(cast(int8)a, cast(int8)b);
    }
    else static if (LDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_psignd256(cast(int8)a, cast(int8)b);
    }
    else // split
    {
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i b_lo = _mm256_extractf128_si256!0(b);
        __m128i b_hi = _mm256_extractf128_si256!1(b);
        __m128i r_lo = _mm_sign_epi32(a_lo, b_lo);
        __m128i r_hi = _mm_sign_epi32(a_hi, b_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
    // PERF: not optimal in AVX without AVX2
}
unittest
{
    __m256i A = _mm256_setr_epi32(-2, -1,  0, int.max, -2, -1,  0, int.max);
    __m256i B = _mm256_setr_epi32(-1,  0, -1,       1, -1,  0, -1,       1);
    int8 C = cast(int8) _mm256_sign_epi32(A, B);
    int[8] correct =             [ 2,  0, 0, int.max,   2,  0,  0, int.max];
    assert(C.array == correct);
}

/// Negate packed signed 8-bit integers in `a` when the corresponding signed 8-bit integer in `b` is negative.
/// Elements in result are zeroed out when the corresponding element in `b` is zero.
__m256i _mm256_sign_epi8 (__m256i a, __m256i b) pure @safe
{
    // PERF DMD
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_psignb256(cast(ubyte32)a, cast(ubyte32)b);
    }
    else static if (LDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_psignb256(cast(byte32)a, cast(byte32)b);
    }
    else // split
    {
        // LDC arm64, 10 inst since LDC 1.32.1 -O1
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i b_lo = _mm256_extractf128_si256!0(b);
        __m128i b_hi = _mm256_extractf128_si256!1(b);
        __m128i r_lo = _mm_sign_epi8(a_lo, b_lo);
        __m128i r_hi = _mm_sign_epi8(a_hi, b_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
    // PERF: not optimal in AVX without AVX2
}
unittest
{
    __m256i A = _mm256_setr_epi8( 1,  1, 1, 1,  1,        1,       -2,        1,  0,  1, 0, 0,  0,        0,       -2,        1, 
                                 -2, -1, 0, 1,  2, byte.min, byte.min, byte.min, -1,  0,-1, 1, -2,      -50,        0,       50);
    __m256i B = _mm256_setr_epi8(-1,  0,-1, 1, -2,      -50,        0,       50, -1,  0,-1, 1, -2,      -50,        0,       50,
                                 -1,  0,-1, 1, -2,      -50,        0,       50, -2, -1, 0, 1,  2, byte.min, byte.min, byte.min);
    byte32  C = cast(byte32) _mm256_sign_epi8(A, B);
    byte[32] correct =         [ -1, 0,-1, 1, -1,       -1,        0,        1,  0,  0, 0, 0,  0,        0,        0,        1,        
                                  2, 0, 0, 1, -2, byte.min,        0, byte.min,  1,  0, 0, 1, -2,       50,        0,      -50];
    assert(C.array == correct);
}

/// Shift packed 16-bit integers in `a` left by `count` while shifting in zeroes.
/// Bit-shift is a single value in the low-order 64-bit of `count`. 
/// If bit-shift > 15, result is defined to be all zeroes.
/// Note: prefer `_mm256_slli_epi16`, less of a trap.
__m256i _mm256_sll_epi16 (__m256i a, __m128i count) pure @trusted
{
    // PERF ARM64
    static if (GDC_or_LDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_psllw256(cast(short16)a, cast(short8)count);
    }
    else
    {
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i r_lo = _mm_sll_epi16(a_lo, count);
        __m128i r_hi = _mm_sll_epi16(a_hi, count);
        return _mm256_set_m128i(r_hi, r_lo);
    }
}
unittest
{
    __m128i shift0 = _mm_setzero_si128();
    __m128i shiftX = _mm_set1_epi64x(0x8000_0000_0000_0000); // too large shift
    __m128i shift2 = _mm_setr_epi32(2, 0, 4, 5);
    __m256i A = _mm256_setr_epi16(4, -8, 11, -32768, 4, -8, 11, -32768, 4, -8, 11, -32768, 4, -8, 11, -32768);
    short[16] correct0  = (cast(short16)A).array;
    short[16] correctX  = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]; 
    short[16] correct2  = [16, -32, 44, 0, 16, -32, 44, 0, 16, -32, 44, 0, 16, -32, 44, 0];
    short16 B0 = cast(short16) _mm256_sll_epi16(A, shift0);
    short16 BX = cast(short16) _mm256_sll_epi16(A, shiftX);
    short16 B2 = cast(short16) _mm256_sll_epi16(A, shift2);
    assert(B0.array == correct0);
    assert(BX.array == correctX);
    assert(B2.array == correct2);
}

/// Shift packed 32-bit integers in `a` left by `count` while shifting in zeroes.
/// Bit-shift is a single value in the low-order 64-bit of `count`. 
/// If bit-shift > 31, result is defined to be all zeroes.
/// Note: prefer `_mm256_slli_epi32`, less of a trap.
__m256i _mm256_sll_epi32 (__m256i a, __m128i count) pure @trusted
{
    // PERF ARM64
    static if (GDC_or_LDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pslld256(cast(int8)a, count);
    }
    else
    {
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i r_lo = _mm_sll_epi32(a_lo, count);
        __m128i r_hi = _mm_sll_epi32(a_hi, count);
        return _mm256_set_m128i(r_hi, r_lo);
    }
}
unittest
{
    __m128i shift0 = _mm_setzero_si128();
    __m128i shiftX = _mm_set1_epi64x(0x8000_0000_0000_0000); // too large shift
    __m128i shift2 = _mm_setr_epi32(2, 0, 4, 5);
    __m256i A = _mm256_setr_epi32(4, -9, 11, -2147483648, 2, -9, 11, -2147483648);
    int[8] correct0  = (cast(int8)A).array;
    int[8] correctX  = [0, 0, 0, 0, 0, 0, 0, 0]; 
    int[8] correct2  = [16, -36, 44, 0, 8, -36, 44, 0];
    int8 B0 = cast(int8) _mm256_sll_epi32(A, shift0);
    int8 BX = cast(int8) _mm256_sll_epi32(A, shiftX);
    int8 B2 = cast(int8) _mm256_sll_epi32(A, shift2);
    assert(B0.array == correct0);
    assert(BX.array == correctX);
    assert(B2.array == correct2);
}

/// Shift packed 64-bit integers in `a` left by `count` while shifting in zeroes.
/// Bit-shift is a single value in the low-order 64-bit of `count`. 
/// If bit-shift > 63, result is defined to be all zeroes.
/// Note: prefer `_mm256_sll_epi64`, less of a trap.
__m256i _mm256_sll_epi64 (__m256i a, __m128i count) pure @trusted
{
    // PERF ARM64
    static if (GDC_or_LDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_psllq256(cast(long4)a, cast(long2)count);
    }
    else
    {
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i r_lo = _mm_sll_epi64(a_lo, count);
        __m128i r_hi = _mm_sll_epi64(a_hi, count);
        return _mm256_set_m128i(r_hi, r_lo);
    }
}
unittest
{
    __m128i shift0 = _mm_setzero_si128();
    __m128i shiftX = _mm_set1_epi64x(0x8000_0000_0000_0000); // too large shift
    __m128i shift2 = _mm_setr_epi32(2, 0, 4, 5);
    __m256i A = _mm256_setr_epi64(4, -9, 5, -8);
    long[4] correct0  = [ 4,  -9, 5, -8];
    long[4] correctX  = [ 0,   0,  0, 0];
    long[4] correct2  = [16, -36, 20, -32];
    long4 B0 = cast(long4) _mm256_sll_epi64(A, shift0);
    long4 BX = cast(long4) _mm256_sll_epi64(A, shiftX);
    long4 B2 = cast(long4) _mm256_sll_epi64(A, shift2);
    assert(B0.array == correct0);
    assert(BX.array == correctX);
    assert(B2.array == correct2);
}

/// Shift packed 16-bit integers in `a` left by `imm8` while shifting in zeros.
__m256i _mm256_slli_epi16(__m256i a, int imm8) pure @safe
{
    static if (GDC_or_LDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_psllwi256(cast(short16)a, cast(ubyte)imm8);
    }
    else // split
    {
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i r_lo = _mm_slli_epi16(a_lo, imm8);
        __m128i r_hi = _mm_slli_epi16(a_hi, imm8);
        return _mm256_set_m128i(r_hi, r_lo);
    }
}
unittest
{
    __m256i A = _mm256_setr_epi16(0, 1, 2, 3, -4, -5, 6, 7, 0, 1, 2, 3, -4, -5, 6, 7);
    short16 B = cast(short16)( _mm256_slli_epi16(A, 1) );
    short16 B2 = cast(short16)( _mm256_slli_epi16(A, 1 + 256) );
    short[16] expectedB = [ 0, 2, 4, 6, -8, -10, 12, 14, 0, 2, 4, 6, -8, -10, 12, 14 ];
    assert(B.array == expectedB);
    assert(B2.array == expectedB);

    short16 C = cast(short16)( _mm256_slli_epi16(A, 16) );
    short[16] expectedC = [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ];
    assert(C.array == expectedC);
}

/// Shift packed 32-bit integers in `a` left by `imm8` while shifting in zeros.
__m256i _mm256_slli_epi32 (__m256i a, int imm8) pure @safe
{
    static if (GDC_or_LDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pslldi256(cast(int8)a, cast(ubyte)imm8);
    }
    else
    {
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i r_lo = _mm_slli_epi32(a_lo, imm8);
        __m128i r_hi = _mm_slli_epi32(a_hi, imm8);
        return _mm256_set_m128i(r_hi, r_lo);
    }
}
unittest
{
    __m256i A = _mm256_setr_epi32(0, 2, 3, -4, 0, 2, 3, -9);
    int8 B = cast(int8) _mm256_slli_epi32(A, 1);
    int8 B2 = cast(int8) _mm256_slli_epi32(A, 1 + 256);
    int[8] expectedB = [ 0, 4, 6, -8, 0, 4, 6, -18 ];
    assert(B.array == expectedB);
    assert(B2.array == expectedB);

    int8 C = cast(int8) _mm256_slli_epi32(A, 0);
    int[8] expectedC = [ 0, 2, 3, -4, 0, 2, 3, -9 ];
    assert(C.array == expectedC);

    int8 D = cast(int8) _mm256_slli_epi32(A, 65);
    int[8] expectedD = [ 0, 0, 0, 0, 0, 0, 0, 0 ];
    assert(D.array == expectedD);
}

/// Shift packed 64-bit integers in `a` left by `imm8` while shifting in zeros.
__m256i _mm256_slli_epi64 (__m256i a, int imm8) pure @safe
{
    static if (GDC_or_LDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_psllqi256(cast(long4)a, cast(ubyte)imm8);
    }
    else
    {
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i r_lo = _mm_slli_epi64(a_lo, imm8);
        __m128i r_hi = _mm_slli_epi64(a_hi, imm8);
        return _mm256_set_m128i(r_hi, r_lo);
    }
}
unittest
{
    __m256i A = _mm256_setr_epi64(23, -4, 1, long.max);
    long4 B = cast(long4) _mm256_slli_epi64(A, 1);
    long4 B2 = cast(long4) _mm256_slli_epi64(A, 1 + 256);

    long[4] expectedB = [ 46, -8, 2, -2];
    assert(B.array == expectedB);
    assert(B2.array == expectedB);

    long4 C = cast(long4) _mm256_slli_epi64(A, 0);
    long[4] expectedC = [ 23, -4, 1, long.max ];
    assert(C.array == expectedC);

    long4 D = cast(long4) _mm256_slli_epi64(A, 65);
    long[4] expectedD = [ 0, 0, 0, 0 ];
    assert(D.array == expectedD);
}

/// Shift 128-bit lanes in `a` left by `bytes` bytes while shifting in zeroes.
alias _mm256_slli_si256 = _mm256_bslli_epi128;

/// Shift packed 32-bit integers in `a` left by the amount specified by the corresponding element in `count` while shifting in zeroes.
__m128i _mm_sllv_epi32(__m128i a, __m128i count) pure @trusted
{
    static if (GDC_with_AVX2 || LDC_with_AVX2)
        return cast(__m128i)__builtin_ia32_psllv4si(cast(byte16)a, cast(byte16)count);
    else
    {
        // UB if b[n] >= 32
        __m128i R = _mm_setr_epi32(a.array[0] << count.array[0], 
                                   a.array[1] << count.array[1], 
                                   a.array[2] << count.array[2], 
                                   a.array[3] << count.array[3]);

        // Map large and negative shifts to 32
        __m128i mm32 = _mm_set1_epi32(32);
        __m128i shift = _mm_min_epu32(count, mm32);

        // Set to 0 where the shift is >= 32
        R = R & _mm_cmplt_epi32(shift, mm32);
        return R;
    }
}
unittest
{
    __m128i A     = _mm_setr_epi32(-1,  1, 4, -4);
    __m128i shift = _mm_setr_epi32( 2, -6, 1, 32);
    int4 R = cast(int4) _mm_sllv_epi32(A, shift);
    int[4] expected = [ -4, 0, 8, 0 ];
    assert(R.array == expected);
}

/// Shift packed 32-bit integers in `a` left by the amount specified by the corresponding element in `count` while shifting in zeroes.
__m256i _mm256_sllv_epi32 (__m256i a, __m256i count) pure @safe
{
    static if (GDC_with_AVX2 || LDC_with_AVX2)
        return cast(__m256i)__builtin_ia32_psllv8si(cast(int8)a, cast(int8)count);
    else
    {
        // split
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i c_lo = _mm256_extractf128_si256!0(count);
        __m128i c_hi = _mm256_extractf128_si256!1(count);
        __m128i r_lo = _mm_sllv_epi32(a_lo, c_lo);
        __m128i r_hi = _mm_sllv_epi32(a_hi, c_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
}
unittest
{
    __m256i A     = _mm256_setr_epi32(-1,  1, 4, -4, -1,  1,  4, -4);
    __m256i shift = _mm256_setr_epi32( 2, -6, 1, 32,  2, -6, 33, 32);
    int8 R = cast(int8) _mm256_sllv_epi32(A, shift);
    int[8] expected = [ -4, 0, 8, 0, -4, 0, 0, 0 ];
    assert(R.array == expected);
}


/// Shift packed 64-bit integers in `a` left by the amount specified by the corresponding element in `b` while shifting in zeros.
__m128i _mm_sllv_epi64(__m128i a, __m128i count) pure @trusted
{
    static if (GDC_with_AVX2 || LDC_with_AVX2)
    {
        return cast(__m128i)__builtin_ia32_psllv2di(cast(long2)a, cast(long2)count);
    }
    else
    {
        // PERF arm64
        // LDC: x86, it's not good, but at least it's branchless
        long2 la = cast(long2)a;
        long2 lb = cast(long2)count;
        long2 R;
        R.ptr[0] = cast(uint)(lb.array[0]) < 64 ? (la.array[0] << lb.array[0]) : 0;
        R.ptr[1] = cast(uint)(lb.array[1]) < 64 ? (la.array[1] << lb.array[1]) : 0;
        return cast(__m128i)R;
    }
}
unittest
{
    __m128i A  = _mm_setr_epi64( -4,  6);
    __m128i B1 = _mm_setr_epi64(  2,  0);
    __m128i B2 = _mm_setr_epi64(-12, 64);
    long2 R1 = cast(long2) _mm_sllv_epi64(A, B1);
    long2 R2 = cast(long2) _mm_sllv_epi64(A, B2);
    long[2] correct1 = [-16, 6];
    long[2] correct2 = [  0, 0];
    assert(R1.array == correct1);
    assert(R2.array == correct2);
}

/// Shift packed 64-bit integers in `a` left by the amount specified by the corresponding element in `count` while shifting in zeroes.
__m256i _mm256_sllv_epi64 (__m256i a, __m256i count) pure @safe
{
    static if (GDC_with_AVX2 || LDC_with_AVX2)
        return cast(__m256i)__builtin_ia32_psllv4di(cast(long4)a, cast(long4)count);
    else
    {
        // split
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i c_lo = _mm256_extractf128_si256!0(count);
        __m128i c_hi = _mm256_extractf128_si256!1(count);
        __m128i r_lo = _mm_sllv_epi64(a_lo, c_lo);
        __m128i r_hi = _mm_sllv_epi64(a_hi, c_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
}
unittest
{
    __m256i A  = _mm256_setr_epi64( -4,  6, -1, 6);
    __m256i B1 = _mm256_setr_epi64(  2,  0,  3, 1);
    __m256i B2 = _mm256_setr_epi64(-12, 64, 63, 64);
    long4 R1 = cast(long4) _mm256_sllv_epi64(A, B1);
    long4 R2 = cast(long4) _mm256_sllv_epi64(A, B2);
    long[4] correct1 = [-16, 6, -8, 12];
    long[4] correct2 = [  0, 0, long.min, 0];
    assert(R1.array == correct1);
    assert(R2.array == correct2);
}



/// Shift packed 16-bit integers in `a` right by `count` while shifting in sign bits.
/// Bit-shift is a single value in the low-order 64-bit of `count`. 
/// If bit-shift > 15, result is defined to be all sign bits.
/// Warning: prefer `_mm256_srai_epi16`, less of a trap.
__m256i _mm256_sra_epi16 (__m256i a, __m128i count) pure @trusted
{
    static if (GDC_or_LDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_psraw256(cast(short16)a, cast(short8)count);
    }
    else
    {
        // split
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i r_lo = _mm_sra_epi16(a_lo, count);
        __m128i r_hi = _mm_sra_epi16(a_hi, count);
        return _mm256_set_m128i(r_hi, r_lo);
    }
}
unittest
{
    __m128i shift0 = _mm_setzero_si128();
    __m128i shiftX = _mm_set1_epi64x(0x8000_0000_0000_0000); // too large shift
    __m128i shift2 = _mm_setr_epi32(2, 0, 4, 5);
    __m256i A = _mm256_setr_epi16(4, -9, 11, -32768, 4, -8, 11, -32768,
                                  4, -9, 11, -32768, 4, -8, 11, -32768);
    short[16] correct0  = (cast(short16)A).array;
    short[16] correctX  = [0, -1, 0, -1, 0, -1, 0, -1, 0, -1, 0, -1, 0, -1, 0, -1]; 
    short[16] correct2  = [1, -3,  2, -8192,  1, -2,  2, -8192, 1, -3,  2, -8192,  1, -2,  2, -8192];
    short16 B0 = cast(short16) _mm256_sra_epi16(A, shift0);
    short16 BX = cast(short16) _mm256_sra_epi16(A, shiftX);
    short16 B2 = cast(short16) _mm256_sra_epi16(A, shift2);
    assert(B0.array == correct0);
    assert(BX.array == correctX);
    assert(B2.array == correct2);
}

/// Shift packed 32-bit integers in `a` right by `count` while shifting in sign bits.
/// Bit-shift is a single value in the low-order 64-bit of `count`. 
/// If bit-shift > 31, result is defined to be all sign bits.
/// Warning: prefer `_mm256_sra_epi32`, less of a trap.
__m256i _mm256_sra_epi32 (__m256i a, __m128i count) pure @trusted
{
    static if (GDC_or_LDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_psrad256(cast(int8)a, cast(int4)count);
    }
    else
    {
        // split
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i r_lo = _mm_sra_epi32(a_lo, count);
        __m128i r_hi = _mm_sra_epi32(a_hi, count);
        return _mm256_set_m128i(r_hi, r_lo);
    }
}
unittest
{
    __m128i shift0 = _mm_setzero_si128();
    __m128i shiftX = _mm_set1_epi64x(0x8000_0000_0000_0000); // too large shift
    __m128i shift2 = _mm_setr_epi32(2, 0, 4, 5);
    __m256i A = _mm256_setr_epi32(4, -9, 11, -2147483648, 8, -9, 11, -2147483648);
    int[8] correct0  = (cast(int8)A).array;
    int[8] correctX  = [0, -1, 0, -1, 0, -1, 0, -1]; 
    int[8] correct2  = [1, -3, 2, -536870912, 2, -3, 2, -536870912];
    int8 B0 = cast(int8) _mm256_sra_epi32(A, shift0);
    int8 BX = cast(int8) _mm256_sra_epi32(A, shiftX);
    int8 B2 = cast(int8) _mm256_sra_epi32(A, shift2);
    assert(B0.array == correct0);
    assert(BX.array == correctX);
    assert(B2.array == correct2);
}

/// Shift packed 16-bit integers in `a` right by `imm8` while shifting in sign bits.
__m256i _mm256_srai_epi16 (__m256i a, int imm8) pure @safe
{
    static if (GDC_or_LDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_psrawi256(cast(short16)a, cast(ubyte)imm8);
    }
    else 
    {
        // split
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i r_lo = _mm_srai_epi16(a_lo, imm8);
        __m128i r_hi = _mm_srai_epi16(a_hi, imm8);
        return _mm256_set_m128i(r_hi, r_lo);
    }
}
unittest
{
    __m256i A  = _mm256_setr_epi16(0, 1, 2, 3, -4, -5, 6, 7, short.min, short.max, 2, 3, -4, -5, 6, 7);
    short16 B  = cast(short16)( _mm256_srai_epi16(A, 1) );
    short16 B2 = cast(short16)( _mm256_srai_epi16(A, 1 + 256) );
    short[16] expectedB = [ 0, 0, 1, 1, -2, -3, 3, 3, -16384, 16383, 1, 1, -2, -3, 3, 3 ];
    assert(B.array == expectedB);
    assert(B2.array == expectedB);

    short16 C = cast(short16)( _mm256_srai_epi16(A, 18) );
    short[16] expectedC = [ 0, 0, 0, 0, -1, -1, 0, 0,
                           -1, 0, 0, 0, -1, -1, 0, 0 ];
    assert(C.array == expectedC);
}

/// Shift packed 32-bit integers in `a` right by `imm8` while shifting in sign bits.
__m256i _mm256_srai_epi32 (__m256i a, int imm8) pure @safe
{
    static if (GDC_or_LDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_psradi256(cast(int8)a, cast(ubyte)imm8);
    }
    else // split
    {
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i r_lo = _mm_srai_epi32(a_lo, imm8);
        __m128i r_hi = _mm_srai_epi32(a_hi, imm8);
        return _mm256_set_m128i(r_hi, r_lo);
    }
}
unittest
{
    __m256i A = _mm256_setr_epi32(0, 2, 3, -4, 0, 2, 3, -4);
    int8 B = cast(int8) _mm256_srai_epi32(A, 1);
    int8 B2 = cast(int8) _mm256_srai_epi32(A, 1 + 256);
    int[8] expectedB = [ 0, 1, 1, -2, 0, 1, 1, -2];
    assert(B.array == expectedB);
    assert(B2.array == expectedB);

    int8 C = cast(int8) _mm256_srai_epi32(A, 32);
    int[8] expectedC = [ 0, 0, 0, -1, 0, 0, 0, -1];
    assert(C.array == expectedC);

    int8 D = cast(int8) _mm256_srai_epi32(A, 0);
    int[8] expectedD = [ 0, 2, 3, -4, 0, 2, 3, -4];
    assert(D.array == expectedD);
}

__m128i _mm_srav_epi32(__m128i a, __m128i count) pure @trusted
{
    static if (GDC_with_AVX2 || LDC_with_AVX2)
        return cast(__m128i)__builtin_ia32_psrav4si(cast(int4)a, cast(int4)count);
    else
    {
        __m128i R = _mm_setr_epi32(a.array[0] >> count.array[0], 
                                   a.array[1] >> count.array[1], 
                                   a.array[2] >> count.array[2], 
                                   a.array[3] >> count.array[3]);

        // Map large and negative shifts to all sign bits
        __m128i signbits = _mm_srai_epi32(a, 31);
        __m128i mm32 = _mm_set1_epi32(32);
        __m128i shift = _mm_min_epu32(count, mm32);

        // Set to 0 where the shift is >= 32
        __m128i lower = _mm_cmplt_epi32(shift, mm32);

        R = (R & lower) | (signbits & ~lower);
        return R;
    }
}
unittest
{
    __m128i A     = _mm_setr_epi32(-1,  1, -4, -4);
    __m128i shift = _mm_setr_epi32( 2, -6, 31, 32);
    int4 R = cast(int4) _mm_srav_epi32(A, shift);
    int[4] expected = [ -1, 0, -1, -1 ];
    assert(R.array == expected);
}

__m256i _mm256_srav_epi32 (__m256i a, __m256i count) pure @safe
{
    static if (GDC_or_LDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_psrav8si(cast(int8)a, cast(ubyte)imm8);
    }
    else // split
    {
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i c_lo = _mm256_extractf128_si256!0(count);
        __m128i c_hi = _mm256_extractf128_si256!1(count);
        __m128i r_lo = _mm_srav_epi32(a_lo, c_lo);
        __m128i r_hi = _mm_srav_epi32(a_hi, c_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
}
unittest
{
    __m128i A     = _mm_setr_epi32(-1,  1, -4, -4);
    __m128i shift = _mm_setr_epi32( 2, -6, 31, 32);
    int4 R = cast(int4) _mm_srav_epi32(A, shift);
    int[4] expected = [ -1, 0, -1, -1 ];
    assert(R.array == expected);
}

// TODO 

/// Shift packed 16-bit integers in `a` right by `count` while shifting in zeroes.
/// Bit-shift is a single value in the low-order 64-bit of `count`. 
/// If bit-shift > 15, result is defined to be all zeroes.
/// Note: prefer `_mm256_srli_epi16`, less of a trap.
__m256i _mm256_srl_epi16 (__m256i a, __m128i count) pure @trusted
{
    // PERF ARM64
    static if (GDC_or_LDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_psrlw256(cast(short16)a, cast(short8)count);
    }
    else
    {
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i r_lo = _mm_srl_epi16(a_lo, count);
        __m128i r_hi = _mm_srl_epi16(a_hi, count);
        return _mm256_set_m128i(r_hi, r_lo);
    }
}
unittest
{
    __m128i shift0 = _mm_setzero_si128();
    __m128i shiftX = _mm_set1_epi64x(0x8000_0000_0000_0000); // too large shift
    __m128i shift2 = _mm_setr_epi32(2, 0, 4, 5);
    __m256i A = _mm256_setr_epi16(4, -8, 11, -32768, 4, -8, 11, -32768, 4, -8, 11, -32768, 4, -8, 11, -32768);
    short[16] correct0  = (cast(short16)A).array;
    short[16] correctX  = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]; 
    short[16] correct2  = [1, 16382, 2, 8192, 1, 16382, 2, 8192, 1, 16382, 2, 8192, 1, 16382, 2, 8192];
    short16 B0 = cast(short16) _mm256_srl_epi16(A, shift0);
    short16 BX = cast(short16) _mm256_srl_epi16(A, shiftX);
    short16 B2 = cast(short16) _mm256_srl_epi16(A, shift2);
    assert(B0.array == correct0);
    assert(BX.array == correctX);
    assert(B2.array == correct2);
}

/// Shift packed 32-bit integers in `a` right by `count` while shifting in zeroes.
/// Bit-shift is a single value in the low-order 64-bit of `count`. 
/// If bit-shift > 31, result is defined to be all zeroes.
/// Note: prefer `_mm256_srli_epi32`, less of a trap.
__m256i _mm256_srl_epi32 (__m256i a, __m128i count) pure @trusted
{
    // PERF ARM64
    static if (GDC_or_LDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_psrld256(cast(int8)a, count);
    }
    else
    {
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i r_lo = _mm_srl_epi32(a_lo, count);
        __m128i r_hi = _mm_srl_epi32(a_hi, count);
        return _mm256_set_m128i(r_hi, r_lo);
    }
}
unittest
{
    __m128i shift0 = _mm_setzero_si128();
    __m128i shiftX = _mm_set1_epi64x(0x8000_0000_0000_0000); // too large shift
    __m128i shift2 = _mm_setr_epi32(2, 0, 4, 5);
    __m256i A = _mm256_setr_epi32(4, -8, 11, -0x80000000, 0, 1, -11, 0x7fffffff);
    int[8] correct0  = (cast(int8)A).array;
    int[8] correctX  = [0, 0, 0, 0, 0, 0, 0, 0]; 
    int[8] correct2  = [1, 1073741822, 2, 536870912, 0, 0, 1073741821, 0x1fffffff];
    int8 B0 = cast(int8) _mm256_srl_epi32(A, shift0);
    int8 BX = cast(int8) _mm256_srl_epi32(A, shiftX);
    int8 B2 = cast(int8) _mm256_srl_epi32(A, shift2);
    assert(B0.array == correct0);
    assert(BX.array == correctX);
    assert(B2.array == correct2);
}

/// Shift packed 64-bit integers in `a` right by `count` while shifting in zeroes.
/// Bit-shift is a single value in the low-order 64-bit of `count`. 
/// If bit-shift > 63, result is defined to be all zeroes.
/// Note: prefer `_mm256_srli_epi64`, less of a trap.
__m256i _mm256_srl_epi64 (__m256i a, __m128i count) pure @trusted
{
    // PERF ARM64
    /*
    static if (LDC_with_ARM64)
    { 
        long bs = (cast(long2)count).array[0];
        if (bs > 63)
            return long4(0);
        else 
        {
            a <<= long4(bs);
            return a;
        }
    }
    else*/  static if (GDC_or_LDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_psrlq256(cast(long4)a, cast(long2)count);
    }
    else
    {
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i r_lo = _mm_srl_epi64(a_lo, count);
        __m128i r_hi = _mm_srl_epi64(a_hi, count);
        return _mm256_set_m128i(r_hi, r_lo);
    }
}
unittest
{
    __m128i shift0 = _mm_setzero_si128();
    __m128i shiftX = _mm_set1_epi64x(0x8000_0000_0000_0000); // too large shift
    __m128i shift2 = _mm_setr_epi32(2, 0, 4, 5);
    __m256i A = _mm256_setr_epi64(4, -9, 8, -9);
    long[4] correct0  = [ 4,  -9, 8, -9];
    long[4] correctX  = [ 0,   0,  0, 0];
    long[4] correct2  = [ 1,  4611686018427387901,  2, 4611686018427387901];
    long4 B0 = cast(long4) _mm256_srl_epi64(A, shift0);
    long4 BX = cast(long4) _mm256_srl_epi64(A, shiftX);
    long4 B2 = cast(long4) _mm256_srl_epi64(A, shift2);
    assert(B0.array == correct0);
    assert(BX.array == correctX);
    assert(B2.array == correct2);
}

/// Shift packed 16-bit integers in `a` right by `imm8` while shifting in zeros.
__m256i _mm256_srli_epi16 (__m256i a, int imm8) pure @trusted
{
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_psrlwi256(cast(short16)a, cast(ubyte)imm8);
    }
    else static if (LDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_psrlwi256(cast(short16)a, cast(ubyte)imm8);
    }
    else
    {
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i r_lo = _mm_srli_epi16(a_lo, imm8);
        __m128i r_hi = _mm_srli_epi16(a_hi, imm8);
        return _mm256_set_m128i(r_hi, r_lo);
    }
}
unittest
{
    __m256i A = _mm256_setr_epi16(0, 1, 2, 3, -4, -5, 6, 7, 0, 1, 2, 3, -4, -5, 6, 7);
    short16 B = cast(short16) _mm256_srli_epi16(A, 1);
    short16 B2 = cast(short16) _mm256_srli_epi16(A, 1 + 256);
    short[16] expectedB = [ 0, 0, 1, 1, 0x7FFE, 0x7FFD, 3, 3, 0, 0, 1, 1, 0x7FFE, 0x7FFD, 3, 3 ];
    assert(B.array == expectedB);
    assert(B2.array == expectedB);

    short16 C = cast(short16) _mm256_srli_epi16(A, 16);
    short[16] expectedC = [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ];
    assert(C.array == expectedC);

    short16 D = cast(short16) _mm256_srli_epi16(A, 0);
    short[16] expectedD = [ 0, 1, 2, 3, -4, -5, 6, 7, 0, 1, 2, 3, -4, -5, 6, 7 ];
    assert(D.array == expectedD);
}

/// Shift packed 32-bit integers in `a` right by `imm8` while shifting in zeros.
__m256i _mm256_srli_epi32 (__m256i a, int imm8) pure @trusted
{
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_psrldi256(cast(int8)a, cast(ubyte)imm8);
    }
    else static if (LDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_psrldi256(cast(int8)a, cast(ubyte)imm8);
    }
    else 
    {
        // split
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i r_lo = _mm_srli_epi32(a_lo, imm8);
        __m128i r_hi = _mm_srli_epi32(a_hi, imm8);
        return _mm256_set_m128i(r_hi, r_lo);
    }
}
unittest
{
    __m256i A = _mm256_setr_epi32(0, 2, 3, -4, 0, 2, 3, -4);
    int8 B = cast(int8) _mm256_srli_epi32(A, 1);
    int8 B2 = cast(int8) _mm256_srli_epi32(A, 1 + 256);
    int[8] expectedB = [ 0, 1, 1, 0x7FFFFFFE, 0, 1, 1, 0x7FFFFFFE];
    assert(B.array == expectedB);
    assert(B2.array == expectedB);

    int8 C = cast(int8) _mm256_srli_epi32(A, 255);
    int[8] expectedC = [ 0, 0, 0, 0, 0, 0, 0, 0 ];
    assert(C.array == expectedC);
}

/// Shift packed 64-bit integers in `a` right by `imm8` while shifting in zeros.
__m256i _mm256_srli_epi64 (__m256i a, int imm8) pure @safe
{
    static if (GDC_or_LDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_psrlqi256(cast(int8)a, cast(ubyte)imm8);
    }
    else 
    {
        // split
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i r_lo = _mm_srli_epi64(a_lo, imm8);
        __m128i r_hi = _mm_srli_epi64(a_hi, imm8);
        return _mm256_set_m128i(r_hi, r_lo);
    }
}
unittest
{
    __m256i A = _mm256_setr_epi64(8, -4, 16, -8);
    long4 B = cast(long4) _mm256_srli_epi64(A, 1);
    long4 B2 = cast(long4) _mm256_srli_epi64(A, 1 + 512);
    long[4] expectedB = [ 4, 0x7FFFFFFFFFFFFFFE, 8, 0x7FFFFFFFFFFFFFFC];
    assert(B.array == expectedB);
    assert(B2.array == expectedB);

    long4 C = cast(long4) _mm256_srli_epi64(A, 64);
    long[4] expectedC = [ 0, 0, 0, 0 ];
    assert(C.array == expectedC);
}

/// Shift 128-bit lanes in `a` right by `bytes` bytes while shifting in zeroes.
alias _mm256_srli_si256 = _mm256_bsrli_epi128;

/// Shift packed 32-bit integers in `a` right by the amount specified by the corresponding element in `count` while shifting in zeroes.
__m128i _mm_srlv_epi32(__m128i a, __m128i count) pure @trusted
{
    static if (GDC_with_AVX2 || LDC_with_AVX2)
        return cast(__m128i)__builtin_ia32_psrlv4si(cast(byte16)a, cast(byte16)count);
    else
    {
        __m128i R = _mm_setr_epi32(a.array[0] >>> count.array[0], 
                                   a.array[1] >>> count.array[1], 
                                   a.array[2] >>> count.array[2], 
                                   a.array[3] >>> count.array[3]);

        // Map large and negative shifts to 32
        __m128i mm32 = _mm_set1_epi32(32);
        __m128i shift = _mm_min_epu32(count, mm32);

        // Set to 0 where the shift is >= 32
        R = R & _mm_cmplt_epi32(shift, mm32);
        return R;
    }
}
unittest
{
    __m128i A     = _mm_setr_epi32(-1,  1, 4, -4);
    __m128i shift = _mm_setr_epi32( 2, -6, 1, 32);
    int4 R = cast(int4) _mm_srlv_epi32(A, shift);
    int[4] expected = [ 1073741823, 0, 2, 0 ];
    assert(R.array == expected);
}

/// Shift packed 32-bit integers in `a` right by the amount specified by the corresponding element in `count` while shifting in zeroes.
__m256i _mm256_srlv_epi32 (__m256i a, __m256i count) pure @trusted
{
    static if (GDC_with_AVX2 || LDC_with_AVX2)
        return cast(__m256i)__builtin_ia32_psrlv8si(cast(int8)a, cast(int8)count);
    else
    {
        // split
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i c_lo = _mm256_extractf128_si256!0(count);
        __m128i c_hi = _mm256_extractf128_si256!1(count);
        __m128i r_lo = _mm_srlv_epi32(a_lo, c_lo);
        __m128i r_hi = _mm_srlv_epi32(a_hi, c_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
}
unittest
{
    __m256i A     = _mm256_setr_epi32(-1,  1, 4, -4, -1,  1, 4, -4);
    __m256i shift = _mm256_setr_epi32( 2, -6, 1, 32, 33,  2, -6, 1);
    int8 R = cast(int8) _mm256_srlv_epi32(A, shift);
    int[8] expected = [ 1073741823, 0, 2, 0, 0, 0, 0, 2147483646 ];
    assert(R.array == expected);
}

/// Shift packed 64-bit integers in `a` right by the amount specified by the corresponding element in `count` while shifting in zeroes.
__m128i _mm_srlv_epi64(__m128i a, __m128i count) pure @trusted
{
    static if (GDC_or_LDC_with_AVX2)
    {
        return cast(__m128i)__builtin_ia32_psrlv2di(cast(long2)a, cast(long2)count);
    }
    else
    {
        // Note: arm64 rather bad for LDC < 1.34
        //       after that, perfect.
        // LDC: x86, it's not good, but at least it's branchless
        long2 la = cast(long2)a;
        long2 lb = cast(long2)count;
        long2 R;
        R.ptr[0] = cast(ulong)(lb.array[0]) < 64 ? (la.array[0] >>> lb.array[0]) : 0;
        R.ptr[1] = cast(ulong)(lb.array[1]) < 64 ? (la.array[1] >>> lb.array[1]) : 0;
        return cast(__m128i)R;
    }
}
unittest
{
    __m256i A  = _mm256_setr_epi64( -4,  6,  -4,  6);
    __m256i B1 = _mm256_setr_epi64(  2,  0,   2,  0);
    __m256i B2 = _mm256_setr_epi64(-12, 64, -12, 64);
    long4 R1 = cast(long4) _mm256_srlv_epi64(A, B1);
    long4 R2 = cast(long4) _mm256_srlv_epi64(A, B2);
    long[4] correct1 = [ 4611686018427387903, 6,  4611686018427387903, 6];
    long[4] correct2 = [                   0, 0,                    0, 0];
    assert(R1.array == correct1);
    assert(R2.array == correct2);
}

/// Shift packed 64-bit integers in `a` right by the amount specified by the corresponding element in `count` while shifting in zeroes.
__m256i _mm256_srlv_epi64 (__m256i a, __m256i count) pure @trusted
{
    // PERF: rather lame in non-AVX2 x86
    static if (GDC_with_AVX2 || LDC_with_AVX2)
        return cast(__m256i)__builtin_ia32_psrlv4di(cast(long4)a, cast(long4)count);
    else
    {
        // split
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i c_lo = _mm256_extractf128_si256!0(count);
        __m128i c_hi = _mm256_extractf128_si256!1(count);
        __m128i r_lo = _mm_srlv_epi64(a_lo, c_lo);
        __m128i r_hi = _mm_srlv_epi64(a_hi, c_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
}
unittest
{
    __m256i A  = _mm256_setr_epi64( -4,  6,  -4,  6);
    __m256i B1 = _mm256_setr_epi64(  2,  0,   2,  0);
    __m256i B2 = _mm256_setr_epi64(-12, 64, -12, 64);
    long4 R1 = cast(long4) _mm256_srlv_epi64(A, B1);
    long4 R2 = cast(long4) _mm256_srlv_epi64(A, B2);
    long[4] correct1 = [ 4611686018427387903, 6,  4611686018427387903, 6];
    long[4] correct2 = [                   0, 0,                    0, 0];
    assert(R1.array == correct1);
    assert(R2.array == correct2);
}

/// Load 256-bits of integer data from memory using a non-temporal memory hint.
/// `mem_addr` must be aligned on a 32-byte boundary or a general-protection exception may be generated.
__m256i _mm256_stream_load_si256 (const(__m256i)* mem_addr) pure @trusted
{
    // PERF DMD D_SIMD
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_movntdqa256(cast(__m256i*)mem_addr); // const_cast
    }
    else static if (LDC_with_InlineIREx && LDC_with_optimizations)
    {
        enum prefix = `!0 = !{ i32 1 }`;
        enum ir = `
            %r = load <4 x i64>, <4 x i64>* %0, !nontemporal !0
            ret <4 x i64> %r`;
        return cast(__m256i) LDCInlineIREx!(prefix, ir, "", long4, const(long4)*)(mem_addr);
    }
    else
    {
        return *mem_addr; // regular move instead
    }
}
unittest
{
    align(32) static immutable int[8] correct = [1, 2, 3, 4, 5, 6, 7, 8];
    __m256i A = _mm256_stream_load_si256(cast(__m256i*)correct.ptr);
    _mm_mfence();
    assert((cast(int8)A).array == correct);
}

/// Subtract packed 16-bit integers in `b` from packed 16-bit integers in `a`.
__m256i _mm256_sub_epi16 (__m256i a, __m256i b) pure @safe
{
    pragma(inline, true);
    return cast(__m256i)(cast(short16)a - cast(short16)b);
}
unittest
{
    __m256i A = _mm256_setr_epi16( -7, -1, 0, 9, -100, 100, 234, 432, -32768, 32767, 0, -1, -20000, 0,  6, -2);
    short16 R = cast(short16) _mm256_sub_epi16(A, A);
    short[16] correct         = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
    assert(R.array == correct);
}

/// Subtract packed 32-bit integers in `b` from packed 32-bit integers in `a`.
__m256i _mm256_sub_epi32(__m256i a, __m256i b) pure @safe
{
    pragma(inline, true);
    return cast(__m256i)(cast(int8)a - cast(int8)b);
}
unittest
{
    __m256i A = _mm256_setr_epi32( -7, -1, 0, 9, -100, 100, 234, 432);
    int8 R = cast(int8) _mm256_sub_epi32(A, A);
    int[8] correct = [ 0, 0, 0, 0, 0, 0, 0, 0];
    assert(R.array == correct);
}

/// Subtract packed 64-bit integers in `b` from packed 64-bit integers in `a`.
__m256i _mm256_sub_epi64 (__m256i a, __m256i b) pure @safe
{
    pragma(inline, true);
    return a - b;
}
unittest
{
    __m256i A = _mm256_setr_epi64(-1, 0x8000_0000_0000_0000, 42, -12);
    long4 R = cast(__m256i) _mm256_sub_epi64(A, A);
    long[4] correct = [ 0, 0, 0, 0 ];
    assert(R.array == correct);
}

/// Subtract packed 8-bit integers in `b` from packed 8-bit integers in `a`.
__m256i _mm256_sub_epi8 (__m256i a, __m256i b) pure @safe
{
    pragma(inline, true);
    return cast(__m256i)(cast(byte32)a - cast(byte32)b);
}
unittest
{
    __m256i A = _mm256_setr_epi8(4, 8, 13, -7, -1, 0, 9, 77, 4, 8, 13, -7, -1, 0, 9, 78,
                                 4, 9, 13, -7, -1, 0, 9, 77, 4, 8, 13, -7, -2, 0, 10, 78);
    byte32 R = cast(byte32) _mm256_sub_epi8(A, A);
    byte[32] correct; // zero initialized
    assert(R.array == correct);
}

/// Subtract packed signed 16-bit integers in `b` from packed 16-bit integers in `a` using 
/// saturation.
__m256i _mm256_subs_epi16 (__m256i a, __m256i b) pure @trusted
{
    // PERF DMD
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_psubsw256(cast(short16)a, cast(short16)b);
    }
    else static if(LDC_with_saturated_intrinsics)
    {
        return cast(__m256i) inteli_llvm_subs!short16(cast(short16)a, cast(short16)b);
    }
    else
    {
        short16 r;
        short16 sa = cast(short16)a;
        short16 sb = cast(short16)b;
        foreach(i; 0..16)
            r.ptr[i] = saturateSignedIntToSignedShort(sa.array[i] - sb.array[i]);
        return cast(__m256i)r;
    }
}
unittest
{
    short16 res = cast(short16) _mm256_subs_epi16(_mm256_setr_epi16( 7,  6,  5, -32768, 3, 3, 32766,   0,  7,  6,  5, -32750, 3, 3, 32767,   0),
                                                  _mm256_setr_epi16( 7,  6,  5, -30000, 3, 1,    -2, -10,  7,  6,  5,    100, 3, 1,     1, -10));
    static immutable short[16] correctResult                    =  [ 0,  0,  0,  -2768, 0, 2, 32767,  10,  0,  0,  0, -32768, 0, 2, 32766,  10];
    assert(res.array == correctResult);
}


/// Subtract packed signed 8-bit integers in `b` from packed 8-bit integers in `a` using
/// saturation.
__m256i _mm256_subs_epi8 (__m256i a, __m256i b) pure @trusted
{
    // PERF DMD
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_psubsb256(cast(ubyte32)a, cast(ubyte32)b);
    }
    else static if(LDC_with_saturated_intrinsics)
    {
        return cast(__m256i) inteli_llvm_subs!byte32(cast(byte32)a, cast(byte32)b);
    }
    else
    {
        byte32 r;
        byte32 sa = cast(byte32)a;
        byte32 sb = cast(byte32)b;
        foreach(i; 0..32)
            r.ptr[i] = saturateSignedWordToSignedByte(sa.array[i] - sb.array[i]);
        return cast(__m256i)r;
    }
}
unittest
{
    byte32 R = cast(byte32) _mm256_subs_epi8(_mm256_setr_epi8(15, 14, 13, 12, 11, 127, 9, 8, 7, 6, 5, -128, 3, 2, 1, 0, 15, 14, 13, 12, 11, 126, 9, 8, 7, 6, 5, -127, 3, 2, 1, 0),
                                             _mm256_setr_epi8(15, 14, 13, 12, 11,  10, 9, 8, 7, 6, 5,    4, 3, 2, 1, 0, 15, 14, 13, 12, 11, -10, 9, 8, 7, 6, 5,    4, 3, 2, 1, 0));
    static immutable byte[32] correct                      = [ 0,  0,  0,  0,  0, 117, 0, 0, 0, 0, 0, -128, 0, 0, 0, 0,  0,  0,  0,  0,  0, 127, 0, 0, 0, 0, 0, -128, 0, 0, 0, 0]; 
    assert(R.array == correct);
}

/// Subtract packed unsigned 16-bit integers in `b` from packed unsigned 16-bit integers in `a` 
/// using saturation.
__m256i _mm256_subs_epu16 (__m256i a, __m256i b) pure @trusted
{
    // PERF DMD
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_psubusw256(cast(short16)a, cast(short16)b);
    }
    else static if(LDC_with_saturated_intrinsics)
    {
        return cast(__m256i) inteli_llvm_subus!short16(cast(short16)a, cast(short16)b);
    }
    else
    {
        short16 r;
        short16 sa = cast(short16)a;
        short16 sb = cast(short16)b;
        foreach(i; 0..16)
            r.ptr[i] = saturateSignedIntToUnsignedShort(cast(ushort)(sa.array[i]) - cast(ushort)(sb.array[i]));
        return cast(__m256i)r;
    }
}
unittest
{
    short16 R = cast(short16) _mm256_subs_epu16(_mm256_setr_epi16(3, 2, cast(short)65535, 0, 3, 2, cast(short)65535, 0, 3, 2, cast(short)65535, 0, 3,  2, cast(short)65534, 0),
                                                _mm256_setr_epi16(3, 4,                1, 0, 3, 2,                1, 0, 3, 2,                1, 0, 3, 20, cast(short)65535, 0));
    static immutable short[16] correct =                         [0, 0, cast(short)65534, 0, 0, 0, cast(short)65534, 0, 0, 0, cast(short)65534, 0, 0,  0,                0, 0];
    assert(R.array == correct);
}

/// Subtract packed unsigned 8-bit integers in `b` from packed unsigned 8-bit integers in `a` using
/// saturation.
__m256i _mm256_subs_epu8 (__m256i a, __m256i b) pure @trusted
{
    // PERF DMD
    // PERF GDC without AVX2
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_psubusb256(cast(ubyte32)a, cast(ubyte32)b);
    }
    else static if(LDC_with_saturated_intrinsics)
    {
        return cast(__m256i) inteli_llvm_subus!byte32(cast(byte32)a, cast(byte32)b);
    }
    else
    {
        byte32 r;
        byte32 sa = cast(byte32)a;
        byte32 sb = cast(byte32)b;
        foreach(i; 0..32)
            r.ptr[i] = saturateSignedWordToUnsignedByte(cast(ubyte)(sa.array[i]) - cast(ubyte)(sb.array[i]));
        return cast(__m256i)r;
    }
}
unittest
{
    __m256i A          = _mm256_setr_epi8(0, 0, 5, 4, 5, 0, 0, 0, 0, 0, 0, 0, cast(byte)255, 0, 0, 0, 0, 0, 0, 0, 0, cast(byte)136, 0, 0, 0, cast(byte)136, 0, 0, 0, 0, 0, 0);
    __m256i B          = _mm256_setr_epi8(0, 0, 4, 5, 5, 0, 0, 0, 0, 0, 0, 0,             1, 0, 0, 0, 0, 0, 0, 0, 0, cast(byte)137, 0, 0, 0,            40, 0, 0, 0, 0, 0, 0);
    byte32 R = cast(byte32) _mm256_subs_epu8(A, B);
    static immutable byte[32] correct =  [0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, cast(byte)254, 0, 0, 0, 0, 0, 0, 0, 0,   cast(byte)0, 0, 0, 0, cast(byte) 96, 0, 0, 0, 0, 0, 0];
    assert(R.array == correct);
}

/// Unpack and interleave 16-bit integers from the high half of each 128-bit lane in `a` and `b`.
__m256i _mm256_unpackhi_epi16 (__m256i a, __m256i b) pure @safe
{
    static if (GDC_with_AVX2)
    {
        return cast(long4) __builtin_ia32_punpckhwd256(cast(short16)a, cast(short16)b);
    }
    else static if (LDC_with_optimizations)
    {
        enum ir = `%r = shufflevector <16 x i16> %0, <16 x i16> %1, <16 x i32> <i32 4, i32 20, i32 5, i32 21, i32 6, i32 22, i32 7, i32 23, i32 12,i32 28, i32 13,i32 29, i32 14,i32 30, i32 15,i32 31>
            ret <16 x i16> %r`;
        return cast(__m256i)LDCInlineIR!(ir, short16, short16, short16)(cast(short16)a, cast(short16)b);
    }
    else
    {
        // Better for arm64, GDC without AVX2
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i b_lo = _mm256_extractf128_si256!0(b);
        __m128i b_hi = _mm256_extractf128_si256!1(b);
        __m128i r_lo = _mm_unpackhi_epi16(a_lo, b_lo);
        __m128i r_hi = _mm_unpackhi_epi16(a_hi, b_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
}
unittest
{
    __m256i A = _mm256_setr_epi16( 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15);
    __m256i B = _mm256_setr_epi16(16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31);
    short16 C = cast(short16) _mm256_unpackhi_epi16(A, B);
    short[16] correct = [4,  20, 5,  21, 6, 22, 7, 23, 
                         12, 28, 13, 29, 14, 30, 15, 31];
    assert(C.array == correct);
}

/// Unpack and interleave 32-bit integers from the high half of each 128-bit lane in `a` and `b`.
__m256i _mm256_unpackhi_epi32 (__m256i a, __m256i b) pure @trusted
{
    static if (GDC_with_AVX2)
        enum bool split = false;
    else version(GNU)
        enum bool split = true;
    else
        enum bool split = false;

    static if (GDC_with_AVX2)
    {
        return cast(long4) __builtin_ia32_punpckhdq256(cast(int8)a, cast(int8)b);
    }
    else static if (LDC_with_optimizations)
    {
        // LDC AVX2: Suprisingly, this start using vunpckhps in LDC 1.31 -O2
        enum ir = `%r = shufflevector <8 x i32> %0, <8 x i32> %1, <8 x i32> <i32 2, i32 10, i32 3, i32 11, i32 6, i32 14, i32 7, i32 15>
            ret <8 x i32> %r`;
        return cast(__m256i)LDCInlineIR!(ir, int8, int8, int8)(cast(int8)a, cast(int8)b);
    }
    else static if (split)
    {
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i b_lo = _mm256_extractf128_si256!0(b);
        __m128i b_hi = _mm256_extractf128_si256!1(b);
        __m128i r_lo = _mm_unpackhi_epi32(a_lo, b_lo);
        __m128i r_hi = _mm_unpackhi_epi32(a_hi, b_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
    else
    {
        int8 R;
        int8 ai = cast(int8)a;
        int8 bi = cast(int8)b;
        R.ptr[0] = ai.array[2];
        R.ptr[1] = bi.array[2];
        R.ptr[2] = ai.array[3];
        R.ptr[3] = bi.array[3];
        R.ptr[4] = ai.array[6];
        R.ptr[5] = bi.array[6];
        R.ptr[6] = ai.array[7];
        R.ptr[7] = bi.array[7];
        return cast(__m256i) R;
    }
}
unittest
{
    __m256i A = _mm256_setr_epi32(0, 1,  2,  3,  4,  5,  6,  7);
    __m256i B = _mm256_setr_epi32(8, 9, 10, 11, 12, 13, 14, 15);
    int8 C = cast(int8) _mm256_unpackhi_epi32(A, B);
    int[8] correct = [2, 10, 3, 11, 6, 14, 7, 15];
    assert(C.array == correct);
}

/// Unpack and interleave 8-bit integers from the high half of each 128-bit lane in `a` and `b`,
__m256i _mm256_unpackhi_epi8 (__m256i a, __m256i b) pure @trusted
{
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_punpckhbw256(cast(ubyte32)a, cast(ubyte32)b);
    }
    else static if (LDC_with_optimizations)
    {
        enum ir = `%r = shufflevector <32 x i8> %0, <32 x i8> %1, <32 x i32> <i32 8, i32 40,  i32 9, i32 41, i32 10, i32 42, i32 11, i32 43, i32 12, i32 44, i32 13, i32 45, i32 14, i32 46, i32 15, i32 47, i32 24, i32 56, i32 25, i32 57, i32 26, i32 58, i32 27, i32 59, i32 28, i32 60, i32 29, i32 61, i32 30, i32 62, i32 31, i32 63>
            ret <32 x i8> %r`;
        return cast(__m256i)LDCInlineIR!(ir, byte32, byte32, byte32)(cast(byte32)a, cast(byte32)b);
    }
    else
    {
        // Splitting always beneficial
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i b_lo = _mm256_extractf128_si256!0(b);
        __m128i b_hi = _mm256_extractf128_si256!1(b);
        __m128i r_lo = _mm_unpackhi_epi8(a_lo, b_lo);
        __m128i r_hi = _mm_unpackhi_epi8(a_hi, b_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
}
unittest
{
    __m256i A = _mm256_setr_epi8(  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15,
                                  16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31);
    __m256i B = _mm256_setr_epi8( 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47,
                                  48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63);
    byte32 C = cast(byte32) _mm256_unpackhi_epi8(A, B);
    byte[32] correct =          [  8, 40,  9, 41, 10, 42, 11, 43, 12, 44, 13, 45, 14, 46, 15, 47,
                                  24, 56, 25, 57, 26, 58, 27, 59, 28, 60, 29, 61, 30, 62, 31, 63 ];
    assert(C.array == correct);
}

/// Unpack and interleave 64-bit integers from the high half of each 128-bit lane in `a` and `b`.
__m256i _mm256_unpackhi_epi64 (__m256i a, __m256i b) pure @trusted
{
    version(GNU)
        enum split = true; // Benefits GDC in non-AVX2
    else
        enum split = false;

    static if (GDC_with_AVX2)
    {
        return __builtin_ia32_punpckhqdq256(a, b);
    }
    else static if (LDC_with_optimizations)
    {
        enum ir = `%r = shufflevector <4 x i64> %0, <4 x i64> %1, <4 x i32> <i32 1, i32 5, i32 3, i32 7>
            ret <4 x i64> %r`;
        return cast(__m256i)LDCInlineIR!(ir, long4, long4, long4)(a, b);
    }
    else static if (split)
    {
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i b_lo = _mm256_extractf128_si256!0(b);
        __m128i b_hi = _mm256_extractf128_si256!1(b);
        __m128i r_lo = _mm_unpackhi_epi64(a_lo, b_lo);
        __m128i r_hi = _mm_unpackhi_epi64(a_hi, b_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
    else
    {        
        long4 R;
        R.ptr[0] = a.array[1];
        R.ptr[1] = b.array[1];
        R.ptr[2] = a.array[3];
        R.ptr[3] = b.array[3];
        return R;
    }
}
unittest
{
    __m256i A = _mm256_setr_epi64(0x22222222_22222222, 0x33333333_33333333, 2, 3);
    __m256i B = _mm256_setr_epi64(0x44444444_44444444, 0x55555555_55555555, 4, 5);
    long4 C = _mm256_unpackhi_epi64(A, B);
    long[4] correct = [0x33333333_33333333, 0x55555555_55555555, 3, 5];
    assert(C.array == correct);
}

/// Unpack and interleave 16-bit integers from the low half of each 128-bit lane in `a` and `b`.
__m256i _mm256_unpacklo_epi16 (__m256i a, __m256i b) pure @safe
{
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_punpcklwd256(cast(short16)a, cast(short16)b);
    }
    else static if (LDC_with_optimizations)
    {
        enum ir = `%r = shufflevector <16 x i16> %0, <16 x i16> %1, <16 x i32> <i32 0, i32 16, i32 1, i32 17, i32 2, i32 18, i32 3, i32 19, i32 8, i32 24, i32 9, i32 25, i32 10, i32 26, i32 11, i32 27>
            ret <16 x i16> %r`;
        return cast(__m256i)LDCInlineIR!(ir, short16, short16, short16)(cast(short16)a, cast(short16)b);
    }
    else
    {
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i b_lo = _mm256_extractf128_si256!0(b);
        __m128i b_hi = _mm256_extractf128_si256!1(b);
        __m128i r_lo = _mm_unpacklo_epi16(a_lo, b_lo);
        __m128i r_hi = _mm_unpacklo_epi16(a_hi, b_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
}
unittest
{
    __m256i A = _mm256_setr_epi16( 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15);
    __m256i B = _mm256_setr_epi16(16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31);
    short16 C = cast(short16) _mm256_unpacklo_epi16(A, B);
    short[16] correct = [0,  16, 1,  17, 2, 18, 3, 19, 
                         8,  24, 9,  25, 10, 26, 11, 27];
    assert(C.array == correct);
}

/// Unpack and interleave 32-bit integers from the low half of each 128-bit lane in `a` and `b`.
__m256i _mm256_unpacklo_epi32 (__m256i a, __m256i b) pure @trusted
{
    static if (GDC_with_AVX2)
        enum bool split = false;
    else version(GNU)
        enum bool split = true;
    else
        enum bool split = false;

    static if (GDC_with_AVX2)
    {
        return cast(long4) __builtin_ia32_punpckldq256(cast(int8)a, cast(int8)b);
    }
    else static if (LDC_with_optimizations)
    {
        // LDC AVX2: Suprisingly, this start using vunpcklps in LDC 1.31 -O1
        enum ir = `%r = shufflevector <8 x i32> %0, <8 x i32> %1, <8 x i32> <i32 0, i32 8, i32 1, i32 9, i32 4, i32 12, i32 5, i32 13>
            ret <8 x i32> %r`;
        return cast(__m256i)LDCInlineIR!(ir, int8, int8, int8)(cast(int8)a, cast(int8)b);
    }
    else static if (split)
    {
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i b_lo = _mm256_extractf128_si256!0(b);
        __m128i b_hi = _mm256_extractf128_si256!1(b);
        __m128i r_lo = _mm_unpacklo_epi32(a_lo, b_lo);
        __m128i r_hi = _mm_unpacklo_epi32(a_hi, b_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
    else
    {
        int8 R;
        int8 ai = cast(int8)a;
        int8 bi = cast(int8)b;
        R.ptr[0] = ai.array[0];
        R.ptr[1] = bi.array[0];
        R.ptr[2] = ai.array[1];
        R.ptr[3] = bi.array[1];
        R.ptr[4] = ai.array[4];
        R.ptr[5] = bi.array[4];
        R.ptr[6] = ai.array[5];
        R.ptr[7] = bi.array[5];
        return cast(__m256i) R;
    }
}
unittest
{
    __m256i A = _mm256_setr_epi32(0, 1,  2,  3,  4,  5,  6,  7);
    __m256i B = _mm256_setr_epi32(8, 9, 10, 11, 12, 13, 14, 15);
    int8 C = cast(int8) _mm256_unpacklo_epi32(A, B);
    int[8] correct = [0, 8, 1, 9, 4, 12, 5, 13];
    assert(C.array == correct);
}

/// Unpack and interleave 64-bit integers from the low half of each 128-bit lane in `a` and `b`.
__m256i _mm256_unpacklo_epi64 (__m256i a, __m256i b) pure @trusted
{
    version(GNU)
        enum split = true; // Benefits GDC in non-AVX2
    else
        enum split = false;

    static if (GDC_with_AVX2)
    {
        return __builtin_ia32_punpcklqdq256(a, b);
    }
    else static if (LDC_with_optimizations)
    {
        enum ir = `%r = shufflevector <4 x i64> %0, <4 x i64> %1, <4 x i32> <i32 0, i32 4, i32 2, i32 6>
            ret <4 x i64> %r`;
        return cast(__m256i)LDCInlineIR!(ir, long4, long4, long4)(a, b);
    }
    else static if (split)
    {
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i b_lo = _mm256_extractf128_si256!0(b);
        __m128i b_hi = _mm256_extractf128_si256!1(b);
        __m128i r_lo = _mm_unpacklo_epi64(a_lo, b_lo);
        __m128i r_hi = _mm_unpacklo_epi64(a_hi, b_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
    else
    {        
        long4 R;
        R.ptr[0] = a.array[0];
        R.ptr[1] = b.array[0];
        R.ptr[2] = a.array[2];
        R.ptr[3] = b.array[2];
        return R;
    }
}
unittest
{
    __m256i A = _mm256_setr_epi64(0x22222222_22222222, 0x33333333_33333333, 2, 3);
    __m256i B = _mm256_setr_epi64(0x44444444_44444444, 0x55555555_55555555, 4, 5);
    long4 C = _mm256_unpacklo_epi64(A, B);
    long[4] correct = [0x22222222_22222222, 0x44444444_44444444, 2, 4];
    assert(C.array == correct);
}

/// Unpack and interleave 8-bit integers from the low half of each 128-bit lane in `a` and `b`. 
__m256i _mm256_unpacklo_epi8 (__m256i a, __m256i b) pure @trusted
{
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_punpcklbw256(cast(ubyte32)a, cast(ubyte32)b);
    }
    else static if (LDC_with_optimizations)
    {
        enum ir = `%r = shufflevector <32 x i8> %0, <32 x i8> %1, <32 x i32> <i32 0, i32 32, i32 1, i32 33, i32 2, i32 34, i32 3, i32 35, i32 4, i32 36, i32 5, i32 37, i32 6, i32 38, i32 7, i32 39, i32 16, i32 48, i32 17, i32 49, i32 18, i32 50, i32 19, i32 51, i32 20, i32 52, i32 21, i32 53, i32 22, i32 54, i32 23, i32 55>
            ret <32 x i8> %r`;
        return cast(__m256i)LDCInlineIR!(ir, byte32, byte32, byte32)(cast(byte32)a, cast(byte32)b);
    }
    else
    {
        // Splitting always beneficial
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i b_lo = _mm256_extractf128_si256!0(b);
        __m128i b_hi = _mm256_extractf128_si256!1(b);
        __m128i r_lo = _mm_unpacklo_epi8(a_lo, b_lo);
        __m128i r_hi = _mm_unpacklo_epi8(a_hi, b_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
}
unittest
{
    __m256i A = _mm256_setr_epi8(  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15,
                                  16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31);
    __m256i B = _mm256_setr_epi8( 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47,
                                  48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63);
    byte32 C = cast(byte32) _mm256_unpacklo_epi8(A, B);
    byte[32] correct =          [  0, 32,  1, 33,  2, 34,  3, 35,  4, 36,  5, 37,  6, 38,  7, 39,
                                  16, 48, 17, 49, 18, 50, 19, 51, 20, 52, 21, 53, 22, 54, 23, 55 ];
    assert(C.array == correct);
}

/// Compute the bitwise XOR of 256 bits (representing integer data) in `a` and `b`.
__m256i _mm256_xor_si256 (__m256i a, __m256i b) pure @safe
{
    return a ^ b;
}
unittest
{
    __m256i A = _mm256_setr_epi64(975394,    619809709,    -1,    54);
    __m256i B = _mm256_setr_epi64(-920275025,       -6, 85873, 96644);
    long4 R = cast(long4) _mm256_xor_si256(A, B);
    long[4] correct = [975394 ^ (-920275025L), 619809709L ^ -6, (-1) ^ 85873, 54 ^ 96644];
    assert(R.array == correct);
}


/+

pragma(LDC_intrinsic, "llvm.x86.avx2.gather.d.d")
int4 __builtin_ia32_gatherd_d(int4, const void*, int4, int4, byte);

pragma(LDC_intrinsic, "llvm.x86.avx2.gather.d.d.256")
int8 __builtin_ia32_gatherd_d256(int8, const void*, int8, int8, byte);

pragma(LDC_intrinsic, "llvm.x86.avx2.gather.d.pd")
double2 __builtin_ia32_gatherd_pd(double2, const void*, int4, double2, byte);

pragma(LDC_intrinsic, "llvm.x86.avx2.gather.d.pd.256")
double4 __builtin_ia32_gatherd_pd256(double4, const void*, int4, double4, byte);

pragma(LDC_intrinsic, "llvm.x86.avx2.gather.d.ps")
float4 __builtin_ia32_gatherd_ps(float4, const void*, int4, float4, byte);

pragma(LDC_intrinsic, "llvm.x86.avx2.gather.d.ps.256")
float8 __builtin_ia32_gatherd_ps256(float8, const void*, int8, float8, byte);

pragma(LDC_intrinsic, "llvm.x86.avx2.gather.d.q")
long2 __builtin_ia32_gatherd_q(long2, const void*, int4, long2, byte);

pragma(LDC_intrinsic, "llvm.x86.avx2.gather.d.q.256")
long4 __builtin_ia32_gatherd_q256(long4, const void*, int4, long4, byte);

pragma(LDC_intrinsic, "llvm.x86.avx2.gather.q.d")
int4 __builtin_ia32_gatherq_d(int4, const void*, long2, int4, byte);

pragma(LDC_intrinsic, "llvm.x86.avx2.gather.q.d.256")
int4 __builtin_ia32_gatherq_d256(int4, const void*, long4, int4, byte);

pragma(LDC_intrinsic, "llvm.x86.avx2.gather.q.pd")
double2 __builtin_ia32_gatherq_pd(double2, const void*, long2, double2, byte);

pragma(LDC_intrinsic, "llvm.x86.avx2.gather.q.pd.256")
double4 __builtin_ia32_gatherq_pd256(double4, const void*, long4, double4, byte);

pragma(LDC_intrinsic, "llvm.x86.avx2.gather.q.ps")
float4 __builtin_ia32_gatherq_ps(float4, const void*, long2, float4, byte);

pragma(LDC_intrinsic, "llvm.x86.avx2.gather.q.ps.256")
float4 __builtin_ia32_gatherq_ps256(float4, const void*, long4, float4, byte);

pragma(LDC_intrinsic, "llvm.x86.avx2.gather.q.q")
long2 __builtin_ia32_gatherq_q(long2, const void*, long2, long2, byte);

pragma(LDC_intrinsic, "llvm.x86.avx2.gather.q.q.256")
long4 __builtin_ia32_gatherq_q256(long4, const void*, long4, long4, byte);

pragma(LDC_intrinsic, "llvm.x86.avx2.maskstore.d")
void __builtin_ia32_maskstored(void*, int4, int4);

pragma(LDC_intrinsic, "llvm.x86.avx2.maskstore.d.256")
void __builtin_ia32_maskstored256(void*, int8, int8);

pragma(LDC_intrinsic, "llvm.x86.avx2.maskstore.q")
void __builtin_ia32_maskstoreq(void*, long2, long2);

pragma(LDC_intrinsic, "llvm.x86.avx2.maskstore.q.256")
void __builtin_ia32_maskstoreq256(void*, long4, long4);

pragma(LDC_intrinsic, "llvm.x86.avx2.mpsadbw")
short16 __builtin_ia32_mpsadbw256(byte32, byte32, byte) pure @safe;


pragma(LDC_intrinsic, "llvm.x86.avx2.pblendvb")
byte32 __builtin_ia32_pblendvb256(byte32, byte32, byte32) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.permd")
int8 __builtin_ia32_permvarsi256(int8, int8) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.permps")
float8 __builtin_ia32_permvarsf256(float8, int8) pure @safe;



pragma(LDC_intrinsic, "llvm.x86.avx2.pmadd.ub.sw")
short16 __builtin_ia32_pmaddubsw256(byte32, byte32) pure @safe;


pragma(LDC_intrinsic, "llvm.x86.avx2.pmovmskb")
int __builtin_ia32_pmovmskb256(byte32) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.pmul.hr.sw")
short16 __builtin_ia32_pmulhrsw256(short16, short16) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.pmulh.w")
short16 __builtin_ia32_pmulhw256(short16, short16) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.pmulhu.w")
short16 __builtin_ia32_pmulhuw256(short16, short16) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.psad.bw")
long4 __builtin_ia32_psadbw256(byte32, byte32) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.pshuf.b")
byte32 __builtin_ia32_pshufb256(byte32, byte32) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.psll.q")
long4 __builtin_ia32_psllq256(long4, long2) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.psll.w")
short16 __builtin_ia32_psllw256(short16, short8) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.pslli.d")
int8 __builtin_ia32_pslldi256(int8, int) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.pslli.q")
long4 __builtin_ia32_psllqi256(long4, int) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.pslli.w")
short16 __builtin_ia32_psllwi256(short16, int) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.psllv.d")
int4 __builtin_ia32_psllv4si(int4, int4) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.psllv.d.256")
int8 __builtin_ia32_psllv8si(int8, int8) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.psllv.q")
long2 __builtin_ia32_psllv2di(long2, long2) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.psllv.q.256")
long4 __builtin_ia32_psllv4di(long4, long4) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.psra.d")
int8 __builtin_ia32_psrad256(int8, int4) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.psra.w")
short16 __builtin_ia32_psraw256(short16, short8) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.psrai.d")
int8 __builtin_ia32_psradi256(int8, int) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.psrai.w")
short16 __builtin_ia32_psrawi256(short16, int) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.psrav.d")
int4 __builtin_ia32_psrav4si(int4, int4) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.psrav.d.256")
int8 __builtin_ia32_psrav8si(int8, int8) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.psrl.d")
int8 __builtin_ia32_psrld256(int8, int4) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.psrl.q")
long4 __builtin_ia32_psrlq256(long4, long2) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.psrl.w")
short16 __builtin_ia32_psrlw256(short16, short8) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.psrli.d")
int8 __builtin_ia32_psrldi256(int8, int) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.psrli.q")
long4 __builtin_ia32_psrlqi256(long4, int) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.psrli.w")
short16 __builtin_ia32_psrlwi256(short16, int) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.psrlv.d")
int4 __builtin_ia32_psrlv4si(int4, int4) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.psrlv.d.256")
int8 __builtin_ia32_psrlv8si(int8, int8) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.psrlv.q")
long2 __builtin_ia32_psrlv2di(long2, long2) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.psrlv.q.256")
long4 __builtin_ia32_psrlv4di(long4, long4) pure @safe;

+/
