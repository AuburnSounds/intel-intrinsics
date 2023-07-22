/**
* MMX intrinsics.
* https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#techs=MMX
* 
* Copyright: Copyright Guillaume Piolat 2019-2020.
* License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module inteli.mmx;

public import inteli.types;
import inteli.internals;

import inteli.xmmintrin;
import inteli.emmintrin;

nothrow @nogc:

// Important: you don't need to call _mm_empty when using "MMX" capabilities of intel-intrinsics,
// since it just generates the right IR and cleaning-up FPU registers is up to the codegen.
// intel-intrinsics is just semantics.
// Even GDC does not seem to use mm0-mm7 registers, instead preferring xmm0-xmm7.


/// Add packed 16-bit integers in `a` and `b`.
__m64 _mm_add_pi16 (__m64 a, __m64 b)
{
    return cast(__m64)(cast(short4)a + cast(short4)b);
}
unittest
{
    short4 R = cast(short4) _mm_add_pi16(_mm_set1_pi16(4), _mm_set1_pi16(3));
    short[4] correct = [7, 7, 7, 7];
    assert(R.array == correct);
}

/// Add packed 32-bit integers in `a` and `b`.
__m64 _mm_add_pi32 (__m64 a, __m64 b)
{
    return cast(__m64)(cast(int2)a + cast(int2)b);
}
unittest
{
    int2 R = cast(int2) _mm_add_pi32(_mm_set1_pi32(4), _mm_set1_pi32(3));
    int[2] correct = [7, 7];
    assert(R.array == correct);
}

/// Add packed 8-bit integers in `a` and `b`.
__m64 _mm_add_pi8 (__m64 a, __m64 b)
{
    return cast(__m64)(cast(byte8)a + cast(byte8)b);
}
unittest
{
    byte8 R = cast(byte8) _mm_add_pi8(_mm_set1_pi8(127), _mm_set1_pi8(-128));
    byte[8] correct = [-1, -1, -1, -1, -1, -1, -1, -1];
    assert(R.array == correct);
}

/// Add packed 16-bit integers in `a` and `b` using signed saturation.
// PERF: PADDSW not generated
__m64 _mm_adds_pi16(__m64 a, __m64 b) pure @trusted
{
    return to_m64(_mm_adds_epi16(to_m128i(a), to_m128i(b)));
}
unittest
{
    short4 res = cast(short4) _mm_adds_pi16(_mm_set_pi16(3, 2, 1, 0),
                                            _mm_set_pi16(3, 2, 1, 0));
    static immutable short[4] correctResult = [0, 2, 4, 6];
    assert(res.array == correctResult);
}

/// Add packed 8-bit integers in `a` and `b` using signed saturation.
// PERF: PADDSB not generated
__m64 _mm_adds_pi8(__m64 a, __m64 b) pure @trusted
{
    return to_m64(_mm_adds_epi8(to_m128i(a), to_m128i(b)));
}
unittest
{
    byte8 res = cast(byte8) _mm_adds_pi8(_mm_set_pi8(7, 6, 5, 4, 3, 2, 1, 0),
                                         _mm_set_pi8(7, 6, 5, 4, 3, 2, 1, 0));
    static immutable byte[8] correctResult = [0, 2, 4, 6, 8, 10, 12, 14];
    assert(res.array == correctResult);
}

/// Add packed 16-bit integers in `a` and `b` using unsigned saturation.
// PERF: PADDUSW not generated
__m64 _mm_adds_pu16(__m64 a, __m64 b) pure @trusted
{
    return to_m64(_mm_adds_epu16(to_m128i(a), to_m128i(b)));
}
unittest
{
    short4 res = cast(short4) _mm_adds_pu16(_mm_set_pi16(3, 2, cast(short)65535, 0),
                                            _mm_set_pi16(3, 2, 1, 0));
    static immutable short[4] correctResult = [0, cast(short)65535, 4, 6];
    assert(res.array == correctResult);
}

/// Add packed 8-bit integers in `a` and `b` using unsigned saturation.
// PERF: PADDUSB not generated
__m64 _mm_adds_pu8(__m64 a, __m64 b) pure @trusted
{
    return to_m64(_mm_adds_epu8(to_m128i(a), to_m128i(b)));
}
unittest
{
    byte8 res = cast(byte8) _mm_adds_pu8(_mm_set_pi8(7, 6, 5, 4, 3, 2, cast(byte)255, 0),
                                         _mm_set_pi8(7, 6, 5, 4, 3, 2, 1, 0));
    static immutable byte[8] correctResult = [0, cast(byte)255, 4, 6, 8, 10, 12, 14];
    assert(res.array == correctResult);
}

/// Compute the bitwise AND of 64 bits (representing integer data) in `a` and `b`.
__m64 _mm_and_si64 (__m64 a, __m64 b) pure @safe
{
    return a & b;
}
unittest
{
    __m64 A = [7];
    __m64 B = [14];
    __m64 R = _mm_and_si64(A, B);
    assert(R.array[0] == 6);
}

/// Compute the bitwise NOT of 64 bits (representing integer data) in `a` and then AND with `b`.
__m64 _mm_andnot_si64 (__m64 a, __m64 b)
{
    return (~a) & b;
}
unittest
{
    __m64 A = [7];
    __m64 B = [14];
    __m64 R = _mm_andnot_si64(A, B);
    assert(R.array[0] == 8);
}

/// Compare packed 16-bit integers in `a` and `b` for equality.
__m64 _mm_cmpeq_pi16 (__m64 a, __m64 b) pure @safe
{
    static if (SIMD_COMPARISON_MASKS_8B)
    {
        return cast(__m64)(cast(short4)a == cast(short4)b);
    }
    else static if (GDC_with_MMX)
    {
        return cast(__m64) __builtin_ia32_pcmpeqw(cast(short4)a, cast(short4)b);        
    }
    else
    {
        return cast(__m64) equalMask!short4(cast(short4)a, cast(short4)b);
    }
}
unittest
{
    short4   A = [-3, -2, -1,  0];
    short4   B = [ 4,  3,  2,  1];
    short[4] E = [ 0,  0,  0,  0];
    short4   R = cast(short4)(_mm_cmpeq_pi16(cast(__m64)A, cast(__m64)B));
    assert(R.array == E);
}

/// Compare packed 32-bit integers in `a` and `b` for equality.
__m64 _mm_cmpeq_pi32 (__m64 a, __m64 b) pure @safe
{
    static if (SIMD_COMPARISON_MASKS_8B)
    {
        return cast(__m64)(cast(int2)a == cast(int2)b);
    }
    else static if (GDC_with_MMX)
    {        
        return cast(__m64) __builtin_ia32_pcmpeqd(cast(int2)a, cast(int2)b);
    }
    else
    {
        return cast(__m64) equalMask!int2(cast(int2)a, cast(int2)b);
    }
}
unittest
{
    int2   A = [-3, -2];
    int2   B = [ 4, -2];
    int[2] E = [ 0, -1];
    int2   R = cast(int2)(_mm_cmpeq_pi32(cast(__m64)A, cast(__m64)B));
    assert(R.array == E);
}

/// Compare packed 8-bit integers in `a` and `b` for equality,
__m64 _mm_cmpeq_pi8 (__m64 a, __m64 b) pure @safe
{
    static if (SIMD_COMPARISON_MASKS_8B)
    {
        return cast(__m64)(cast(byte8)a == cast(byte8)b);
    }
    else static if (GDC_with_MMX)
    {        
        return cast(__m64) __builtin_ia32_pcmpeqb(cast(ubyte8)a, cast(ubyte8)b);
    }
    else
    {
        return cast(__m64) equalMask!byte8(cast(byte8)a, cast(byte8)b);
    }
}
unittest
{
    __m64 A = _mm_setr_pi8(1, 2, 3, 1, 2, 1, 1, 2);
    __m64 B = _mm_setr_pi8(2, 2, 1, 2, 3, 1, 2, 3);
    byte8 C = cast(byte8) _mm_cmpeq_pi8(A, B);
    byte[8] correct =     [0,-1, 0, 0, 0,-1, 0, 0];
    assert(C.array == correct);
}

/// Compare packed 16-bit integers in `a` and `b` for greater-than.
__m64 _mm_cmpgt_pi16 (__m64 a, __m64 b) pure @safe
{
    static if (SIMD_COMPARISON_MASKS_8B)
    {
        return cast(__m64)(cast(short4)a > cast(short4)b);
    }
    else static if (GDC_with_MMX)
    { 
        return cast(__m64) __builtin_ia32_pcmpgtw (cast(short4)a, cast(short4)b);
    }
    else
    {
        return cast(__m64) greaterMask!short4(cast(short4)a, cast(short4)b);
    }
}
unittest
{
    short4   A = [-3, -2, -1,  0];
    short4   B = [ 4,  3,  2,  1];
    short[4] E = [ 0,  0,  0,  0];
    short4   R = cast(short4)(_mm_cmpgt_pi16(cast(__m64)A, cast(__m64)B));
    assert(R.array == E);
}

/// Compare packed 32-bit integers in `a` and `b` for greater-than.
__m64 _mm_cmpgt_pi32 (__m64 a, __m64 b) pure @safe
{
    static if (SIMD_COMPARISON_MASKS_8B)
    {
        return cast(__m64)(cast(int2)a > cast(int2)b);
    }
    else static if (GDC_with_MMX)
    {
        return cast(__m64) __builtin_ia32_pcmpgtw (cast(short4)a, cast(short4)b);
    }
    else
    {
        return cast(__m64) greaterMask!int2(cast(int2)a, cast(int2)b);
    }
}
unittest
{
    int2   A = [-3,  2];
    int2   B = [ 4, -2];
    int[2] E = [ 0, -1];
    int2   R = cast(int2)(_mm_cmpgt_pi32(cast(__m64)A, cast(__m64)B));
    assert(R.array == E);
}

/// Compare packed signed 8-bit integers in `a` and `b` for greater-than.
__m64 _mm_cmpgt_pi8 (__m64 a, __m64 b) pure @safe
{
    static if (SIMD_COMPARISON_MASKS_8B)
    {
        return cast(__m64)(cast(byte8)a > cast(byte8)b);
    }
    else static if (GDC_with_MMX)
    {
        return cast(__m64) __builtin_ia32_pcmpgtb (cast(ubyte8)a, cast(ubyte8)b);
    }
    else
    {
        return cast(__m64) greaterMask!byte8(cast(byte8)a, cast(byte8)b);
    }
}
unittest
{
    __m64 A = _mm_setr_pi8(1, 2, 3, 1, 2, 1, 1, 2);
    __m64 B = _mm_setr_pi8(2, 2, 1, 2, 3, 1, 2, 3);
    byte8 C = cast(byte8) _mm_cmpgt_pi8(A, B);
    byte[8] correct =     [0, 0,-1, 0, 0, 0, 0, 0];
    assert(C.array == correct);
}

/// Copy 64-bit integer `a` to `dst`.
long _mm_cvtm64_si64 (__m64 a) pure @safe
{
    long1 la = cast(long1)a;
    return a.array[0];
}
unittest
{
    __m64 A = _mm_setr_pi32(2, 1);
    long1 lA = cast(long1)A;
    assert(A.array[0] == 0x100000002);
}

/// Copy 32-bit integer `a` to the lower elements of `dst`, and zero the upper element of `dst`.
__m64 _mm_cvtsi32_si64 (int a) pure @trusted
{
    __m64 r = void;
    r.ptr[0] = a;
    return r;
}
unittest
{
    __m64 R = _mm_cvtsi32_si64(-1);
    assert(R.array[0] == -1);
}

/// Copy 64-bit integer `a` to `dst`.
__m64 _mm_cvtsi64_m64 (long a) pure @trusted
{
    __m64 r = void;
    r.ptr[0] = a;
    return r;
}
unittest
{
    __m64 R = _mm_cvtsi64_m64(0x123456789A);
    assert(R.array[0] == 0x123456789A);
}

/// Get the lower 32-bit integer in `a`.
int _mm_cvtsi64_si32 (__m64 a) pure @safe
{
    int2 r = cast(int2)a;
    return r.array[0];
}
unittest
{
    __m64 A = _mm_setr_pi32(-6, 5);
    int R = _mm_cvtsi64_si32(A);
    assert(R == -6);
}

/// Empty the MMX state, which marks the x87 FPU registers as available for 
/// use by x87 instructions. 
/// This instruction is supposed to be used at the end of all MMX technology procedures.
/// But this is useless when using `intel-intrinsics`, with all D compilers.
void _mm_empty() pure @safe
{
    // do nothing, see comment on top of file
}


deprecated alias _m_empty = _mm_empty; /// Deprecated intrinsics.
deprecated alias _m_from_int =  _mm_cvtsi32_si64; ///ditto
deprecated alias _m_from_int64 = _mm_cvtsi64_m64; ///ditto

/// Multiply packed 16-bit integers in `a` and `b`, producing intermediate 32-bit integers. 
/// Horizontally add adjacent pairs of intermediate 32-bit integers
__m64 _mm_madd_pi16 (__m64 a, __m64 b) pure @safe
{
    return to_m64(_mm_madd_epi16(to_m128i(a), to_m128i(b)));
}
unittest
{
    short4 A = [-32768, -32768, 32767, 32767];
    short4 B = [-32768, -32768, 32767, 32767];
    int2 R = cast(int2) _mm_madd_pi16(cast(__m64)A, cast(__m64)B);
    int[2] correct = [-2147483648, 2*32767*32767];
    assert(R.array == correct);
}

/// Multiply the packed 16-bit integers in `a` and `b`, producing intermediate 32-bit integers, 
/// and store the high 16 bits of the intermediate integers.
__m64 _mm_mulhi_pi16 (__m64 a, __m64 b) pure @safe
{
    return to_m64(_mm_mulhi_epi16(to_m128i(a), to_m128i(b)));
}
unittest
{
    __m64 A = _mm_setr_pi16(4, 8, -16, 7);
    __m64 B = _mm_set1_pi16(16384);
    short4 R = cast(short4)_mm_mulhi_pi16(A, B);
    short[4] correct = [1, 2, -4, 1];
    assert(R.array == correct);
}

/// Multiply the packed 16-bit integers in `a` and `b`, producing intermediate 32-bit integers, 
/// and store the low 16 bits of the intermediate integers.
__m64 _mm_mullo_pi16 (__m64 a, __m64 b) pure @safe
{
    return to_m64(_mm_mullo_epi16(to_m128i(a), to_m128i(b)));
}
unittest
{
    __m64 A = _mm_setr_pi16(4, 1, 16, 7);
    __m64 B = _mm_set1_pi16(16384);
    short4 R = cast(short4)_mm_mullo_pi16(A, B);
    short[4] correct = [0, 16384, 0, -16384];
    assert(R.array == correct);
}

/// Compute the bitwise OR of 64 bits in `a` and `b`.
__m64 _mm_or_si64 (__m64 a, __m64 b) pure @safe
{
    return a | b;
}
unittest
{
    __m64 A = _mm_setr_pi16(255, 1, -1, 0);
    __m64 B = _mm_set1_pi16(15);
    short4 R = cast(short4)_mm_or_si64(A, B);
    short[4] correct =     [255, 15, -1, 15];
    assert(R.array == correct);
}

/// Convert packed 16-bit integers from `a` and `b` to packed 8-bit integers using signed saturation.
__m64 _mm_packs_pi16 (__m64 a, __m64 b) pure @trusted
{
    int4 p = cast(int4) _mm_packs_epi16(to_m128i(a), to_m128i(b));
    int2 r;
    r.ptr[0] = p.array[0];
    r.ptr[1] = p.array[2];
    return cast(__m64)r;
}
unittest
{
    __m64 A = _mm_setr_pi16(256, -129, 254, 0);
    byte8 R = cast(byte8) _mm_packs_pi16(A, A);
    byte[8] correct = [127, -128, 127, 0, 127, -128, 127, 0];
    assert(R.array == correct);
}

/// Convert packed 32-bit integers from `a` and `b` to packed 16-bit integers using signed saturation.
__m64 _mm_packs_pi32 (__m64 a, __m64 b) pure @trusted
{
    int4 p = cast(int4) _mm_packs_epi32(to_m128i(a), to_m128i(b));
    int2 r;
    r.ptr[0] = p.array[0];
    r.ptr[1] = p.array[2];
    return cast(__m64)r;
}
unittest
{
    __m64 A = _mm_setr_pi32(100000, -100000);
    short4 R = cast(short4) _mm_packs_pi32(A, A);
    short[4] correct = [32767, -32768, 32767, -32768];
    assert(R.array == correct);
}

/// Convert packed 16-bit integers from `a` and `b` to packed 8-bit integers using unsigned saturation.
__m64 _mm_packs_pu16 (__m64 a, __m64 b) pure @trusted
{
    int4 p = cast(int4) _mm_packus_epi16(to_m128i(a), to_m128i(b));
    int2 r;
    r.ptr[0] = p.array[0];
    r.ptr[1] = p.array[2];
    return cast(__m64)r;
}
unittest
{
    __m64 A = _mm_setr_pi16(256, -129, 254, 0);
    byte8 R = cast(byte8) _mm_packs_pu16(A, A);
    ubyte[8] correct = [255, 0, 254, 0, 255, 0, 254, 0];
    assert(R.array == cast(byte[8])correct);
}

deprecated alias
    _m_packssdw = _mm_packs_pi32,     /// Deprecated intrinsics.
    _m_packsswb = _mm_packs_pi16,     ///ditto
    _m_packuswb = _mm_packs_pu16,     ///ditto
    _m_paddb = _mm_add_pi8,           ///ditto
    _m_paddd = _mm_add_pi32,          ///ditto
    _m_paddsb = _mm_adds_pi8,         ///ditto
    _m_paddsw = _mm_adds_pi16,        ///ditto
    _m_paddusb = _mm_adds_pu8,        ///ditto
    _m_paddusw = _mm_adds_pu16,       ///ditto
    _m_paddw = _mm_add_pi16,          ///ditto
    _m_pand = _mm_and_si64,           ///ditto
    _m_pandn = _mm_andnot_si64,       ///ditto
    _m_pcmpeqb = _mm_cmpeq_pi8,       ///ditto
    _m_pcmpeqd = _mm_cmpeq_pi32,      ///ditto
    _m_pcmpeqw = _mm_cmpeq_pi16,      ///ditto
    _m_pcmpgtb = _mm_cmpgt_pi8,       ///ditto
    _m_pcmpgtd = _mm_cmpgt_pi32,      ///ditto
    _m_pcmpgtw = _mm_cmpgt_pi16,      ///ditto
    _m_pmaddwd = _mm_madd_pi16,       ///ditto
    _m_pmulhw = _mm_mulhi_pi16,       ///ditto
    _m_pmullw = _mm_mullo_pi16,       ///ditto
    _m_por = _mm_or_si64,             ///ditto
    _m_pslld = _mm_sll_pi32,          ///ditto
    _m_pslldi = _mm_slli_pi32,        ///ditto
    _m_psllq = _mm_sll_si64,          ///ditto
    _m_psllqi = _mm_slli_si64,        ///ditto
    _m_psllw = _mm_sll_pi16,          ///ditto
    _m_psllwi = _mm_slli_pi16,        ///ditto
    _m_psrad = _mm_sra_pi32,          ///ditto
    _m_psradi = _mm_srai_pi32,        ///ditto
    _m_psraw = _mm_sra_pi16,          ///ditto
    _m_psrawi = _mm_srai_pi16,        ///ditto
    _m_psrld = _mm_srl_pi32,          ///ditto
    _m_psrldi = _mm_srli_pi32,        ///ditto
    _m_psrlq = _mm_srl_si64,          ///ditto
    _m_psrlqi = _mm_srli_si64,        ///ditto
    _m_psrlw = _mm_srl_pi16,          ///ditto
    _m_psrlwi = _mm_srli_pi16,        ///ditto
    _m_psubb = _mm_sub_pi8,           ///ditto
    _m_psubd = _mm_sub_pi32,          ///ditto
    _m_psubsb = _mm_subs_pi8,         ///ditto
    _m_psubsw = _mm_subs_pi16,        ///ditto
    _m_psubusb = _mm_subs_pu8,        ///ditto
    _m_psubusw = _mm_subs_pu16,       ///ditto
    _m_psubw = _mm_sub_pi16,          ///ditto
    _m_punpckhbw = _mm_unpackhi_pi8,  ///ditto
    _m_punpckhdq = _mm_unpackhi_pi32, ///ditto
    _m_punpckhwd = _mm_unpackhi_pi16, ///ditto
    _m_punpcklbw = _mm_unpacklo_pi8,  ///ditto
    _m_punpckldq = _mm_unpacklo_pi32, ///ditto
    _m_punpcklwd = _mm_unpacklo_pi16, ///ditto
    _m_pxor = _mm_xor_si64;           ///ditto
                
/// Set packed 16-bit integers with the supplied values.
__m64 _mm_set_pi16 (short e3, short e2, short e1, short e0) pure @trusted
{
    short[4] arr = [e0, e1, e2, e3];
    return *cast(__m64*)(arr.ptr);
}
unittest
{
    short4 R = cast(short4) _mm_set_pi16(3, 2, 1, 0);
    short[4] correct = [0, 1, 2, 3];
    assert(R.array == correct);
}

/// Set packed 32-bit integers with the supplied values.
__m64 _mm_set_pi32 (int e1, int e0) pure @trusted
{
    int[2] arr = [e0, e1];
    return *cast(__m64*)(arr.ptr);
}
unittest
{
    int2 R = cast(int2) _mm_set_pi32(1, 0);
    int[2] correct = [0, 1];
    assert(R.array == correct);
}

/// Set packed 8-bit integers with the supplied values.
__m64 _mm_set_pi8 (byte e7, byte e6, byte e5, byte e4, byte e3, byte e2, byte e1, byte e0) pure @trusted
{
    byte[8] arr = [e0, e1, e2, e3, e4, e5, e6, e7];
    return *cast(__m64*)(arr.ptr);
}
unittest
{
    byte8 R = cast(byte8) _mm_set_pi8(7, 6, 5, 4, 3, 2, 1, 0);
    byte[8] correct = [0, 1, 2, 3, 4, 5, 6, 7];
    assert(R.array == correct);
}

/// Broadcast 16-bit integer `a` to all elements.
__m64 _mm_set1_pi16 (short a) pure @trusted
{
    return cast(__m64)(short4(a));
}
unittest
{
    short4 R = cast(short4) _mm_set1_pi16(44);
    short[4] correct = [44, 44, 44, 44];
    assert(R.array == correct);
}

/// Broadcast 32-bit integer `a` to all elements.
__m64 _mm_set1_pi32 (int a) pure @trusted
{
    return cast(__m64)(int2(a));
}
unittest
{
    int2 R = cast(int2) _mm_set1_pi32(43);
    int[2] correct = [43, 43];
    assert(R.array == correct);
}

/// Broadcast 8-bit integer `a` to all elements.
__m64 _mm_set1_pi8 (byte a) pure @trusted
{
    return cast(__m64)(byte8(a));
}
unittest
{
    byte8 R = cast(byte8) _mm_set1_pi8(42);
    byte[8] correct = [42, 42, 42, 42, 42, 42, 42, 42];
    assert(R.array == correct);
}

/// Set packed 16-bit integers with the supplied values in reverse order.
__m64 _mm_setr_pi16 (short e3, short e2, short e1, short e0) pure @trusted
{
    short[4] arr = [e3, e2, e1, e0];
    return *cast(__m64*)(arr.ptr);
}
unittest
{
    short4 R = cast(short4) _mm_setr_pi16(0, 1, 2, 3);
    short[4] correct = [0, 1, 2, 3];
    assert(R.array == correct);
}

/// Set packed 32-bit integers with the supplied values in reverse order.
__m64 _mm_setr_pi32 (int e1, int e0) pure @trusted
{
    int[2] arr = [e1, e0];
    return *cast(__m64*)(arr.ptr);
}
unittest
{
    int2 R = cast(int2) _mm_setr_pi32(0, 1);
    int[2] correct = [0, 1];
    assert(R.array == correct);
}

/// Set packed 8-bit integers with the supplied values in reverse order.
__m64 _mm_setr_pi8 (byte e7, byte e6, byte e5, byte e4, byte e3, byte e2, byte e1, byte e0) pure @trusted
{
    byte[8] arr = [e7, e6, e5, e4, e3, e2, e1, e0];
    return *cast(__m64*)(arr.ptr);
}
unittest
{
    byte8 R = cast(byte8) _mm_setr_pi8(0, 1, 2, 3, 4, 5, 6, 7);
    byte[8] correct = [0, 1, 2, 3, 4, 5, 6, 7];
    assert(R.array == correct);
}

/// Return vector of type `__m64` with all elements set to zero.
__m64 _mm_setzero_si64 () pure @trusted
{
    __m64 r; // PERF =void;
    r.ptr[0] = 0;
    return r;
}
unittest
{
    __m64 R = _mm_setzero_si64();
    assert(R.array[0] == 0);
}

/// Shift packed 16-bit integers in `a` left by `bits` while shifting in zeros.
deprecated("Use _mm_slli_pi16 instead.") __m64 _mm_sll_pi16 (__m64 a, __m64 bits) pure @safe
{
    return to_m64(_mm_sll_epi16(to_m128i(a), to_m128i(bits)));
}

/// Shift packed 32-bit integers in `a` left by `bits` while shifting in zeros.
deprecated("Use _mm_slli_pi32 instead.") __m64 _mm_sll_pi32 (__m64 a, __m64 bits) pure @safe
{
    return to_m64(_mm_sll_epi32(to_m128i(a), to_m128i(bits)));
}

/// Shift 64-bit integer `a` left by `bits` while shifting in zeros.
deprecated("Use _mm_slli_si64 instead.") __m64 _mm_sll_si64 (__m64 a, __m64 bits) pure @safe
{
    return to_m64(_mm_sll_epi64(to_m128i(a), to_m128i(bits)));
}

/// Shift packed 16-bit integers in `a` left by `imm8` while shifting in zeros.
__m64 _mm_slli_pi16 (__m64 a, int imm8) pure @safe
{
    return to_m64(_mm_slli_epi16(to_m128i(a), imm8));
}
unittest
{
    __m64 A = _mm_setr_pi16(-4, -5, 6, 7);
    short4 B = cast(short4)( _mm_slli_pi16(A, 1) );
    short[4] correct = [ -8, -10, 12, 14 ];
    assert(B.array == correct);
}

/// Shift packed 32-bit integers in `a` left by `imm8` while shifting in zeros.
__m64 _mm_slli_pi32 (__m64 a, int imm8) pure @safe
{
    return to_m64(_mm_slli_epi32(to_m128i(a), imm8));
}
unittest
{
    __m64 A = _mm_setr_pi32(-4, 5);
    int2 B = cast(int2)( _mm_slli_pi32(A, 1) );
    int[2] correct = [ -8, 10 ];
    assert(B.array == correct);
}

/// Shift 64-bit integer `a` left by `imm8` while shifting in zeros.
__m64 _mm_slli_si64 (__m64 a, int imm8) pure @safe
{
    return to_m64(_mm_slli_epi64(to_m128i(a), imm8));
}
unittest
{
    __m64 A = _mm_cvtsi64_m64(-1);
    long1 R = cast(long1)( _mm_slli_si64(A, 1) );
    long[1] correct = [ -2 ];
    assert(R.array == correct);
}

/// Shift packed 16-bit integers in `a` right by `bits` while shifting in sign bits.
deprecated("Use _mm_srai_pi16 instead.") __m64 _mm_sra_pi16 (__m64 a, __m64 bits) pure @safe
{
    return to_m64(_mm_sra_epi16(to_m128i(a), to_m128i(bits)));
}

/// Shift packed 32-bit integers in `a` right by `bits` while shifting in sign bits.
deprecated("Use _mm_srai_pi32 instead.") __m64 _mm_sra_pi32 (__m64 a, __m64 bits) pure @safe
{
    return to_m64(_mm_sra_epi32(to_m128i(a), to_m128i(bits)));
}

/// Shift packed 16-bit integers in `a` right by `imm8` while shifting in sign bits.
__m64 _mm_srai_pi16 (__m64 a, int imm8) pure @safe
{
    return to_m64(_mm_srai_epi16(to_m128i(a), imm8));
}
unittest
{
    __m64 A = _mm_setr_pi16(-4, -5, 6, 7);
    short4 B = cast(short4)( _mm_srai_pi16(A, 1) );
    short[4] correct = [ -2, -3, 3, 3 ];
    assert(B.array == correct);
}

/// Shift packed 32-bit integers in `a` right by `imm8` while shifting in sign bits.
__m64 _mm_srai_pi32 (__m64 a, int imm8) pure @safe
{
    return to_m64(_mm_srai_epi32(to_m128i(a), imm8));
}
unittest
{
    __m64 A = _mm_setr_pi32(-4, 5);
    int2 B = cast(int2)( _mm_srai_pi32(A, 1) );
    int[2] correct = [ -2, 2 ];
    assert(B.array == correct);
}

/// Shift packed 16-bit integers in `a` right by `bits` while shifting in zeros.
deprecated("Use _mm_srli_pi16 instead.") __m64 _mm_srl_pi16 (__m64 a, __m64 bits) pure @safe
{
    return to_m64(_mm_srl_epi16(to_m128i(a), to_m128i(bits)));
}

/// Shift packed 32-bit integers in `a` right by `bits` while shifting in zeros.
deprecated("Use _mm_srli_pi32 instead.") __m64 _mm_srl_pi32 (__m64 a, __m64 bits) pure @safe
{
    return to_m64(_mm_srl_epi32(to_m128i(a), to_m128i(bits)));
}

/// Shift 64-bit integer `a` right by `bits` while shifting in zeros.
deprecated("Use _mm_srli_si64 instead.") __m64 _mm_srl_si64 (__m64 a, __m64 bits) pure @safe
{
    return to_m64(_mm_srl_epi64(to_m128i(a), to_m128i(bits)));
}

/// Shift packed 16-bit integers in `a` right by `imm8` while shifting in zeros.
__m64 _mm_srli_pi16 (__m64 a, int imm8) pure @safe
{
    return to_m64(_mm_srli_epi16(to_m128i(a), imm8));
}
unittest
{
    __m64 A = _mm_setr_pi16(-4, -5, 6, 7);
    short4 B = cast(short4)( _mm_srli_pi16(A, 1) );
    short[4] correct = [ 0x7ffe, 0x7ffd, 3, 3 ];
    assert(B.array == correct);
}

/// Shift packed 32-bit integers in `a` right by `imm8` while shifting in zeros.
__m64 _mm_srli_pi32 (__m64 a, int imm8) pure @safe
{
    return to_m64(_mm_srli_epi32(to_m128i(a), imm8));
}
unittest
{
    __m64 A = _mm_setr_pi32(-4, 5);
    int2 B = cast(int2)( _mm_srli_pi32(A, 1) );
    int[2] correct = [ 0x7ffffffe, 2 ];
    assert(B.array == correct);
}

/// Shift 64-bit integer `a` right by `imm8` while shifting in zeros.
__m64 _mm_srli_si64 (__m64 a, int imm8) pure @safe
{
    return to_m64(_mm_srli_epi64(to_m128i(a), imm8));
}
unittest
{
    __m64 A = _mm_cvtsi64_m64(-1);
    long1 R = cast(long1)( _mm_srli_si64(A, 1) );
    long[1] correct = [ 0x7fff_ffff_ffff_ffff ];
    assert(R.array == correct);
}

/// Subtract packed 16-bit integers in `b` from packed 16-bit integers in `a`.
__m64 _mm_sub_pi16 (__m64 a, __m64 b) pure @safe
{
    return cast(__m64)(cast(short4)a - cast(short4)b);
}
unittest
{
    short4 R = cast(short4) _mm_sub_pi16(_mm_setr_pi16(cast(short)65534,  1, 5, -32768),
                                         _mm_setr_pi16(cast(short)65535, 16, 4, 4));
    static immutable short[4] correct =                            [ -1,-15, 1, 32764];
    assert(R.array == correct);
}

/// Subtract packed 32-bit integers in `b` from packed 32-bit integers in `a`.
__m64 _mm_sub_pi32 (__m64 a, __m64 b) pure @safe
{
    return cast(__m64)(cast(int2)a - cast(int2)b);
}
unittest
{
    int2 R = cast(int2) _mm_sub_pi32(_mm_setr_pi32( 10,   4),
                                     _mm_setr_pi32( 15, -70));
    static immutable int[2] correct =             [ -5,  74];
    assert(R.array == correct);
}

/// Subtract packed 8-bit integers in `b` from packed 8-bit integers in `a`.
__m64 _mm_sub_pi8 (__m64 a, __m64 b) pure @safe
{
    return cast(__m64)(cast(byte8)a - cast(byte8)b);
}
unittest
{
    byte8 R = cast(byte8) _mm_sub_pi8(_mm_setr_pi8(cast(byte)254, 127, 13, 12, 11, 10, 9, -128),
                                      _mm_setr_pi8(cast(byte)255, 120, 14, 42, 11, 10, 9, 8));
    static immutable byte[8] correct =                 [      -1,   7, -1,-30,  0,  0, 0, 120 ];
    assert(R.array == correct);
}

/// Subtract packed 16-bit integers in `b` from packed 16-bit integers in `a` using saturation.
__m64 _mm_subs_pi16 (__m64 a, __m64 b) pure @safe
{
    return to_m64(_mm_subs_epi16(to_m128i(a), to_m128i(b)));
}
unittest
{
    short4 R = cast(short4) _mm_subs_pi16(_mm_setr_pi16(cast(short)65534,  1, 5, -32768),
                                          _mm_setr_pi16(cast(short)65535, 16, 4, 4));
    static immutable short[4] correct =                             [ -1,-15, 1, -32768];
    assert(R.array == correct);
}

/// Subtract packed 8-bit integers in `b` from packed 8-bit integers in `a` using saturation.
__m64 _mm_subs_pi8 (__m64 a, __m64 b) pure @safe
{
    return to_m64(_mm_subs_epi8(to_m128i(a), to_m128i(b)));
}
unittest
{
    byte8 R = cast(byte8) _mm_subs_pi8(_mm_setr_pi8(cast(byte)254, 127, 13, 12, 11, 10, 9, -128),
                                       _mm_setr_pi8(cast(byte)255, 120, 14, 42, 11, 10, 9, 8));
    static immutable byte[8] correct =                 [       -1,   7, -1,-30,  0,  0, 0, -128 ];
    assert(R.array == correct);
}

/// Subtract packed unsigned 16-bit integers in `b` from packed unsigned 16-bit integers in `a` 
/// using saturation.
__m64 _mm_subs_pu16 (__m64 a, __m64 b) pure @safe
{
    return to_m64(_mm_subs_epu16(to_m128i(a), to_m128i(b)));
}
unittest
{
    short4 R = cast(short4) _mm_subs_pu16(_mm_setr_pi16(cast(short)65534,  1, 5, 4),
                                          _mm_setr_pi16(cast(short)65535, 16, 4, 4));
    static immutable short[4] correct =                              [ 0,  0, 1, 0];
    assert(R.array == correct);
}

/// Subtract packed unsigned 8-bit integers in `b` from packed unsigned 8-bit integers in `a` 
/// using saturation.
__m64 _mm_subs_pu8 (__m64 a, __m64 b) pure @safe
{
    return to_m64(_mm_subs_epu8(to_m128i(a), to_m128i(b)));
}
unittest
{
    byte8 R = cast(byte8) _mm_subs_pu8(_mm_setr_pi8(cast(byte)254, 127, 13, 12, 11, 10, 9, 8),
                                       _mm_setr_pi8(cast(byte)255, 120, 14, 42, 11, 10, 9, 8));
    static immutable byte[8] correct =                 [        0,   7,  0,  0,  0,  0, 0, 0, ];
    assert(R.array == correct);
}

deprecated alias _m_to_int = _mm_cvtsi64_si32;  /// Deprecated intrinsics.
deprecated alias _m_to_int64 = _mm_cvtm64_si64; ///ditto

/// Unpack and interleave 16-bit integers from the high half of `a` and `b`.
__m64 _mm_unpackhi_pi16 (__m64 a, __m64 b) pure @trusted
{   
    static if (LDC_with_optimizations)
    {
        enum ir = `%r = shufflevector <4 x i16> %0, <4 x i16> %1, <4 x i32> <i32 2, i32 6, i32 3, i32 7>
                   ret <4 x i16> %r`;
        return cast(__m64) LDCInlineIR!(ir, short4, short4, short4)(cast(short4)a, cast(short4)b);
    }
    else
    {
        short4 ia = cast(short4)a;
        short4 ib = cast(short4)b;
        short4 r;
        r.ptr[0] = ia.array[2];
        r.ptr[1] = ib.array[2];
        r.ptr[2] = ia.array[3];
        r.ptr[3] = ib.array[3];
        return cast(__m64)r;
    }
}
unittest
{
    __m64 A = _mm_setr_pi16(4, 8, -16, 7);
    __m64 B = _mm_setr_pi16(5, 9,  -3, 10);
    short4 R = cast(short4) _mm_unpackhi_pi16(A, B);
    short[4] correct = [-16, -3, 7, 10];
    assert(R.array == correct);
}

/// Unpack and interleave 32-bit integers from the high half of `a` and `b`.
__m64 _mm_unpackhi_pi32 (__m64 a, __m64 b) pure @trusted
{
    // Generate punpckldq as far back as LDC 1.0.0 -O1
    // (Yes, LLVM does generate punpckldq to reuse SSE2 instructions)
    int2 ia = cast(int2)a;
    int2 ib = cast(int2)b;
    int2 r;
    r.ptr[0] = ia.array[1];
    r.ptr[1] = ib.array[1];
    return cast(__m64)r;
}
unittest
{
    __m64 A = _mm_setr_pi32(4, 8);
    __m64 B = _mm_setr_pi32(5, 9);
    int2 R = cast(int2) _mm_unpackhi_pi32(A, B);
    int[2] correct = [8, 9];
    assert(R.array == correct);
}

/// Unpack and interleave 8-bit integers from the high half of `a` and `b`.
__m64 _mm_unpackhi_pi8 (__m64 a, __m64 b)
{
    static if (LDC_with_optimizations)
    {
        enum ir = `%r = shufflevector <8 x i8> %0, <8 x i8> %1, <8 x i32> <i32 4, i32 12, i32 5, i32 13, i32 6, i32 14, i32 7, i32 15>
                   ret <8 x i8> %r`;
        return cast(__m64) LDCInlineIR!(ir, byte8, byte8, byte8)(cast(byte8)a, cast(byte8)b);
    }
    else
    {
        byte8 ia = cast(byte8)a;
        byte8 ib = cast(byte8)b;
        byte8 r;
        r.ptr[0] = ia.array[4];
        r.ptr[1] = ib.array[4];
        r.ptr[2] = ia.array[5];
        r.ptr[3] = ib.array[5];
        r.ptr[4] = ia.array[6];
        r.ptr[5] = ib.array[6];
        r.ptr[6] = ia.array[7];
        r.ptr[7] = ib.array[7];
        return cast(__m64)r;
    }
}
unittest
{
    __m64 A = _mm_setr_pi8( 1,  2,  3,  4,  5,  6,  7,  8);
    __m64 B = _mm_setr_pi8(-1, -2, -3, -4, -5, -6, -7, -8);
    byte8 R = cast(byte8) _mm_unpackhi_pi8(A, B);
    byte[8] correct = [5, -5, 6, -6, 7, -7, 8, -8];
    assert(R.array == correct);
}

/// Unpack and interleave 16-bit integers from the low half of `a` and `b`.
__m64 _mm_unpacklo_pi16 (__m64 a, __m64 b)
{
    // Generates punpcklwd since LDC 1.0.0 -01
    short4 ia = cast(short4)a;
    short4 ib = cast(short4)b;
    short4 r;
    r.ptr[0] = ia.array[0];
    r.ptr[1] = ib.array[0];
    r.ptr[2] = ia.array[1];
    r.ptr[3] = ib.array[1];
    return cast(__m64)r;
}
unittest
{
    __m64 A = _mm_setr_pi16(4, 8, -16, 7);
    __m64 B = _mm_setr_pi16(5, 9,  -3, 10);
    short4 R = cast(short4) _mm_unpacklo_pi16(A, B);
    short[4] correct = [4, 5, 8, 9];
    assert(R.array == correct);
}

/// Unpack and interleave 32-bit integers from the low half of `a` and `b`.
__m64 _mm_unpacklo_pi32 (__m64 a, __m64 b) pure @trusted
{
    // x86: Generate punpckldq as far back as LDC 1.0.0 -O1
    // ARM: Generate zip as far back as LDC 1.8.0 -O1
    int2 ia = cast(int2)a;
    int2 ib = cast(int2)b;
    int2 r;
    r.ptr[0] = ia.array[0];
    r.ptr[1] = ib.array[0];
    return cast(__m64)r;
}
unittest
{
    __m64 A = _mm_setr_pi32(4, 8);
    __m64 B = _mm_setr_pi32(5, 9);
    int2 R = cast(int2) _mm_unpacklo_pi32(A, B);
    int[2] correct = [4, 5];
    assert(R.array == correct);
}

/// Unpack and interleave 8-bit integers from the low half of `a` and `b`.
__m64 _mm_unpacklo_pi8 (__m64 a, __m64 b)
{
    static if (LDC_with_optimizations)
    {
        enum ir = `%r = shufflevector <8 x i8> %0, <8 x i8> %1, <8 x i32> <i32 0, i32 8, i32 1, i32 9, i32 2, i32 10, i32 3, i32 11>
            ret <8 x i8> %r`;
        return cast(__m64) LDCInlineIR!(ir, byte8, byte8, byte8)(cast(byte8)a, cast(byte8)b);
    }
    else
    {
        byte8 ia = cast(byte8)a;
        byte8 ib = cast(byte8)b;
        byte8 r;
        r.ptr[0] = ia.array[0];
        r.ptr[1] = ib.array[0];
        r.ptr[2] = ia.array[1];
        r.ptr[3] = ib.array[1];
        r.ptr[4] = ia.array[2];
        r.ptr[5] = ib.array[2];
        r.ptr[6] = ia.array[3];
        r.ptr[7] = ib.array[3];
        return cast(__m64)r;
    }
}
unittest
{
    __m64 A = _mm_setr_pi8( 1,  2,  3,  4,  5,  6,  7,  8);
    __m64 B = _mm_setr_pi8(-1, -2, -3, -4, -5, -6, -7, -8);
    byte8 R = cast(byte8) _mm_unpacklo_pi8(A, B);
    byte[8] correct = [1, -1, 2, -2, 3, -3, 4, -4];
    assert(R.array == correct);
}

/// Compute the bitwise XOR of 64 bits (representing integer data) in `a` and `b`.
__m64 _mm_xor_si64 (__m64 a, __m64 b)
{
    return a ^ b;
}
unittest
{
    __m64 A = _mm_setr_pi16(255, 1, -1, 0);
    __m64 B = _mm_set1_pi16(15);
    short4 R = cast(short4)_mm_xor_si64(A, B);
    short[4] correct =     [240, 14, -16, 15];
    assert(R.array == correct);
}

