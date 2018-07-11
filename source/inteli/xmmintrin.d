/**
* Copyright: Copyright Auburn Sounds 2016-2018.
* License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
* Authors:   Guillaume Piolat
*/
module inteli.xmmintrin;

public import inteli.types;

import inteli.internals;

// SSE1
// Note: intrinsics noted MMXREG are actually using MMX registers,
// and were not translated. These intrinsics are for instruction
// introduced with SSE1, that also work on MMX registers.

nothrow @nogc:

__m128 _mm_add_ps(__m128 a, __m128 b) pure @safe
{
    return a + b;
}

unittest
{
    __m128 a = [1, 2, 3, 4];
    a = _mm_add_ps(a, a);
    assert(a.array[0] == 2);
    assert(a.array[1] == 4);
    assert(a.array[2] == 6);
    assert(a.array[3] == 8);
}

__m128 _mm_add_ss(__m128 a, __m128 b) pure @safe
{
    // Because the LDC intrinsic disappeared
    return insertelement!(float4, 0)(a, a.array[0] + b.array[0]);
}
unittest 
{
    __m128 a = [1, 2, 3, 4];
    a = _mm_add_ss(a, a);
    assert(a.array == [2.0f, 2, 3, 4]);
}

__m128i _mm_and_ps (__m128i a, __m128i b) pure @safe
{
    return a & b;
}

__m128i _mm_andnot_ps (__m128i a, __m128i b) pure @safe
{
    return (~a) & b;
}

// MMXREG: _mm_avg_pu16
// MMXREG: _mm_avg_pu8

version(LDC)
{
    pragma(LDC_intrinsic, "llvm.x86.sse.cmp.ps")
        __m128 __builtin_ia32_cmpps(__m128, __m128, byte) pure @safe;
}
else
{
    // unimplemented
    /*__m128 __builtin_ia32_cmpps(__m128, __m128, byte) pure @safe
    {
        assert(false, "unimplemented");
    }*/
}

version(LDC)
{
    __m128 _mm_cmpeq_ps (__m128 a, __m128 b) pure @safe
    {
        return __builtin_ia32_cmpps(a, b, 0);
    }

    __m128 _mm_cmpeq_ss (__m128 a, __m128 b) pure @safe
    {
        return __builtin_ia32_cmpss(a, b, 0);
    }

    __m128 _mm_cmpge_ps (__m128 a, __m128 b) pure @safe
    {
        return __builtin_ia32_cmpps(b, a, 2); // CMPLEPS reversed
    }

    __m128 _mm_cmpge_ss (__m128 a, __m128 b) pure @safe
    {
        return __builtin_ia32_cmpss(b, a, 2); // CMPLESS reversed
    }

    __m128 _mm_cmpgt_ps (__m128 a, __m128 b) pure @safe
    {
        return __builtin_ia32_cmpps(b, a, 1); // CMPLTPS reversed
    }

    __m128 _mm_cmpgt_ss (__m128 a, __m128 b) pure @safe
    {
        return __builtin_ia32_cmpss(b, a, 1); // CMPLTSS reversed
    }

    __m128 _mm_cmple_ps (__m128 a, __m128 b) pure @safe
    {
        return __builtin_ia32_cmpps(a, b, 2); // CMPLEPS
    }

    __m128 _mm_cmple_ss (__m128 a, __m128 b) pure @safe
    {
        return __builtin_ia32_cmpss(a, b, 2); // CMPLESS
    }

    __m128 _mm_cmplt_ps (__m128 a, __m128 b) pure @safe
    {
        return __builtin_ia32_cmpps(a, b, 1); // CMPLTPS
    }

    __m128 _mm_cmplt_ss (__m128 a, __m128 b) pure @safe
    {
        return __builtin_ia32_cmpss(a, b, 1); // CMPLTSS
    }

    __m128 _mm_cmpneq_ps (__m128 a, __m128 b) pure @safe
    {
        return __builtin_ia32_cmpps(a, b, 4); // CMPNEQPS
    }

    __m128 _mm_cmpneq_ss (__m128 a, __m128 b) pure @safe
    {
        return __builtin_ia32_cmpss(a, b, 4); // CMPNEQSS
    }

    __m128 _mm_cmpnge_ps (__m128 a, __m128 b) pure @safe
    {
        return __builtin_ia32_cmpps(b, a, 6); // CMPNLEPS reversed
    }

    __m128 _mm_cmpnge_ss (__m128 a, __m128 b) pure @safe
    {
        return __builtin_ia32_cmpss(b, a, 6); // CMPNLESS reversed
    }

    __m128 _mm_cmpngt_ps (__m128 a, __m128 b) pure @safe
    {
        return __builtin_ia32_cmpps(b, a, 5); // CMPNLTPS reversed
    }

    __m128 _mm_cmpngt_ss (__m128 a, __m128 b) pure @safe
    {
        return __builtin_ia32_cmpss(b, a, 5); // CMPNLTPS reversed
    }

    __m128 _mm_cmpnle_ps (__m128 a, __m128 b) pure @safe
    {
        return __builtin_ia32_cmpps(a, b, 6); // CMPNLEPS
    }

    __m128 _mm_cmpnle_ss (__m128 a, __m128 b) pure @safe
    {
        return __builtin_ia32_cmpss(a, b, 6); // CMPNLESS
    }

    __m128 _mm_cmpnlt_ps (__m128 a, __m128 b) pure @safe
    {
        return __builtin_ia32_cmpps(a, b, 5); // CMPNLTPS
    }

    __m128 _mm_cmpnlt_ss (__m128 a, __m128 b) pure @safe
    {
        return __builtin_ia32_cmpss(a, b, 5); // CMPNLTSS
    }

    __m128 _mm_cmpord_ps (__m128 a, __m128 b) pure @safe
    {
        return __builtin_ia32_cmpps(a, b, 7); // CMPORDPS
    }

    __m128 _mm_cmpord_ss (__m128 a, __m128 b) pure @safe
    {
        return __builtin_ia32_cmpss(a, b, 7); // CMPORDSS
    }

    __m128 _mm_cmpunord_ps (__m128 a, __m128 b) pure @safe
    {
        return __builtin_ia32_cmpps(a, b, 3); // CMPUNORDPS
    }

    __m128 _mm_cmpunord_ss (__m128 a, __m128 b) pure @safe
    {
        return __builtin_ia32_cmpss(a, b, 3); // CMPUNORDSS
    }
}

version(LDC)
{
    alias _mm_comieq_ss = __builtin_ia32_comieq;
}
else
{
    /*__m128i _mm_comieq_ss(__m128, __m128) pure @safe
    {
        assert(false, "unimplemented");
    }
    */
}


version(LDC)
{
    alias _mm_comige_ss = __builtin_ia32_comige;
}
else
{
    /*
    __m128i _mm_comige_ss(__m128, __m128) pure @safe
    {
        assert(false, "unimplemented");
    }
    */
}


version(LDC)
{
    alias _mm_comigt_ss = __builtin_ia32_comigt;
}
else
{
    /*
    __m128i _mm_comigt_ss(__m128, __m128) pure @safe
    {
        assert(false, "unimplemented");
    }
    */
}


version(LDC)
{
    alias _mm_comile_ss = __builtin_ia32_comile;
}
else
{
    /*
    __m128i _mm_comile_ss(__m128, __m128) pure @safe
    {
        assert(false, "unimplemented");
    }
    */
}


version(LDC)
{
    alias _mm_comilt_ss = __builtin_ia32_comilt;
}
else
{
    /*
    __m128i _mm_comilt_ss(__m128, __m128) pure @safe
    {
        assert(false, "unimplemented");
    }
    */
}

version(LDC)
{
    alias _mm_comineq_ss = __builtin_ia32_comineq;
}
else
{
    /*
    __m128i _mm_comineq_ss(__m128, __m128) pure @safe
    {
        assert(false, "unimplemented");
    }
    */
}

// MMXREG: __m128 _mm_cvt_pi2ps (__m128 a, __m64 b)
// MMXREG: __m64 _mm_cvt_ps2pi (__m128 a)
/*
pragma(LDC_intrinsic, "llvm.x86.sse2.cvtsi2sd")
    double2 __builtin_ia32_cvtsi2sd(double2, int) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.cvtsi642sd")
    double2 __builtin_ia32_cvtsi642sd(double2, long) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.cvtss2sd")
    double2 __builtin_ia32_cvtss2sd(double2, float4) pure @safe;*/

version(LDC)
{
    pragma(LDC_intrinsic, "llvm.x86.sse2.cvtsi2sd")
        double2 _mm_cvt_si2ss(double2, int) pure @safe;
}
else
{
    /*
    __m128d _mm_cvt_si2ss(__m128d, int) pure @safe
    {
        assert(false, "unimplemented");
    }
    */
}

version(LDC)
{
    alias _mm_cvt_ss2si = __builtin_ia32_cvtss2si;
}
else
{
    /*
    int _mm_cvt_ss2si(__m128 v) pure @safe
    {
        assert(false, "unimplemented");
    }
    */
}

// MMXREG: __m128 _mm_cvtpi16_ps (__m64 a)
// MMXREG: __m128 _mm_cvtpi32_ps (__m128 a, __m64 b)
// MMXREG: __m128 _mm_cvtpi32x2_ps (__m64 a, __m64 b)
// MMXREG: __m128 _mm_cvtpi8_ps (__m64 a)
// MMXREG: __m64 _mm_cvtps_pi16 (__m128 a)
// MMXREG: __m64 _mm_cvtps_pi32 (__m128 a)
// MMXREG: __m64 _mm_cvtps_pi8 (__m128 a)
// MMXREG: __m128 _mm_cvtpu16_ps (__m64 a)
// MMXREG: __m128 _mm_cvtpu8_ps (__m64 a)

version(LDC)
{
    // this LLVM intrinsics seems to still be there
    pragma(LDC_intrinsic, "llvm.x86.sse.cvtsi2ss")
        float4 _mm_cvtsi32_ss(float4, int) pure @safe;
}
else
{
    __m128 _mm_cvtsi32_ss(__m128 v, int x) pure @safe
    {
        return insertelement!(float4, 0)(v, cast(float)x);
    }
}
unittest
{
    __m128 a = _mm_cvtsi32_ss(_mm_set1_ps(0.0f), 42);
    assert(a.array == [42.0f, 0, 0, 0]);
}

// Note: on macOS, using "llvm.x86.sse.cvtsi642ss" was buggy
__m128 _mm_cvtsi64_ss(__m128 v, long x) pure @safe
{
    return insertelement!(float4, 0)(v, cast(float)x);
}
unittest
{
    __m128 a = _mm_cvtsi64_ss(_mm_set1_ps(0.0f), 42);
    assert(a.array == [42.0f, 0, 0, 0]);
}

float _mm_cvtss_f32(__m128 a) pure @safe
{
    return extractelement!(__m128, 0)(a);
}

version(LDC)
{
    alias _mm_cvtss_si32 = __builtin_ia32_cvtss2si;
}

version(LDC)
{
    alias _mm_cvtss_si64 = __builtin_ia32_cvtss2si64;
}

// MMXREG: __m64 _mm_cvtt_ps2pi (__m128 a)

version(LDC)
{
    alias _mm_cvtt_ss2si = __builtin_ia32_cvttss2si;
    alias _mm_cvttss_si32 = _mm_cvtt_ss2si; // it's actually the same op
}

// MMXREG: _mm_cvttps_pi32

version(LDC)
{
    
}

version(LDC)
{
    alias _mm_cvttss_si64 = __builtin_ia32_cvttss2si64;
}

__m128 _mm_div_ps(__m128 a, __m128 b) pure @safe
{
    return a / b;
}

__m128 _mm_div_ss(__m128 a, __m128 b) pure @safe
{
    // Note: the LLVM intrinsic "llvm.x86.sse.div.ss" disappeared
    return insertelement!(__m128, 0)(a, a.array[0] / b.array[0]);
}
unittest
{
    __m128 a = [1.5f, -2.0f, 3.0f, 1.0f];
    a = _mm_div_ss(a, a);
    float[4] correct = [1.0f, -2.0, 3.0f, 1.0f];
    assert(a.array == correct);
}

// MMXREG: int _mm_extract_pi16 (__m64 a, int imm8)
// TODO: unsigned int _MM_GET_EXCEPTION_MASK ()
// TODO: unsigned int _MM_GET_EXCEPTION_STATE ()
// TODO: unsigned int _MM_GET_FLUSH_ZERO_MODE ()
// TODO: unsigned int _MM_GET_ROUNDING_MODE ()
// TODO: stmxcsr
// TODO: unsigned int _mm_getcsr (void)

// MMXREG: __m64 _mm_insert_pi16 (__m64 a, int i, int imm8)

__m128 _mm_load_ps(const(float)*p)
{
    return *cast(__m128*)p;
}

__m128 _mm_load_ps1(const(float)*p) pure @trusted
{
    float[4] f = [ *p, *p, *p, *p ];
    return loadUnaligned!(float4)(f.ptr);
}

__m128 _mm_load_ss (const(float)* mem_addr) pure @trusted
{
    float[4] f = [ *mem_addr, 0.0f, 0.0f, 0.0f ];
    return loadUnaligned!(float4)(f.ptr);
}

alias _mm_load1_ps = _mm_load_ps1;

__m128 _mm_loadh_pi (__m128 a, const(__m64)* mem_addr) pure @safe
{
    return cast(__m128) insertelement!(long2, 1)(cast(long2)a, *mem_addr);
}

__m128 _mm_loadl_pi (__m128 a, const(__m64)* mem_addr) pure @safe
{
    return cast(__m128) insertelement!(long2, 0)(cast(long2)a, *mem_addr);
}

__m128 _mm_loadr_ps (const(float)* mem_addr) pure @trusted
{
    __m128* aligned = cast(__m128*)mem_addr;
    __m128 a = *aligned;
    return shufflevector!(__m128, 3, 2, 1, 0)(a, a);
}

__m128 _mm_loadu_ps(float*p) pure @safe
{
    return loadUnaligned!(__m128)(p);
}

// MMXREG: _mm_maskmove_si64
// MMXREG: _m_maskmovq

// MMXREG: _mm_max_pi16
version(LDC)
{
    alias _mm_max_ps = __builtin_ia32_maxps;
}

// MMXREG: _mm_max_pu8
version(LDC)
{
    alias _mm_max_ss = __builtin_ia32_maxss;
}

// MMXREG: _mm_min_pi16
version(LDC)
{
    alias _mm_min_ps = __builtin_ia32_minps;
}

// MMXREG: _mm_min_pi8

version(LDC)
{
    alias _mm_min_ss = __builtin_ia32_minss;
}

__m128 _mm_move_ss (__m128 a, __m128 b) pure @safe
{
    return shufflevector!(__m128, 4, 1, 2, 3)(a, b);
}

__m128 _mm_movehl_ps (__m128 a, __m128 b) pure @safe
{
    return shufflevector!(float4, 2, 3, 6, 7)(a, b);
}

__m128 _mm_movelh_ps (__m128 a, __m128 b) pure @safe
{
    return shufflevector!(float4, 0, 1, 4, 5)(a, b);
}

// TODO: int _mm_movemask_pi8
version(LDC)
{
    alias _mm_movemask_ps = __builtin_ia32_movmskps;
}

__m128 _mm_mul_ps(__m128 a, __m128 b) pure @safe
{
    return a * b;
}

__m128 _mm_mul_ss(__m128 a, __m128 b) pure @safe
{
    // Note: the LLVM intrinsic "llvm.x86.sse.mul.ss" disappeared
    return insertelement!(__m128, 0)(a, a.array[0] * b.array[0]);
}
unittest
{
    __m128 a = [1.5f, -2.0f, 3.0f, 1.0f];
    a = _mm_mul_ss(a, a);
    float[4] correct = [2.25f, -2.0, 3.0f, 1.0f];
    assert(a.array == correct);
}

// MMXREG: _mm_mulhi_pu16

__m128 _mm_or_ps (__m128 a, __m128 b) pure @safe
{
    return cast(__m128)(cast(__m128i)a | cast(__m128i)b);
}

// MMXREG: __m64 _m_pavgb (__m64 a, __m64 b)
// MMXREG: __m64 _m_pavgw (__m64 a, __m64 b)
// MMXREG: int _m_pextrw (__m64 a, int imm8)
// MMXREG: __m64 _m_pinsrw (__m64 a, int i, int imm8)
// MMXREG: __m64 _m_pmaxsw (__m64 a, __m64 b)
// MMXREG: __m64 _m_pmaxub (__m64 a, __m64 b)
// MMXREG: __m64 _m_pminsw (__m64 a, __m64 b)
// MMXREG: __m64 _m_pminub (__m64 a, __m64 b)
// MMXREG: int _m_pmovmskb (__m64 a)

// MMXREG: __m64 _m_pmulhuw (__m64 a, __m64 b)

enum _MM_HINT_NTA = 0;
enum _MM_HINT_T0 = 1;
enum _MM_HINT_T1 = 2;
enum _MM_HINT_T2 = 3;

// Note: locality must be compile-time
void _mm_prefetch(int locality)(void* p) pure @safe
{
    llvm_prefetch(p, 0, locality, 1);
}

// MMXREG: __m64 _m_psadbw (__m64 a, __m64 b)
// MMXREG: __m64 _m_pshufw (__m64 a, int imm8)

version(LDC)
{
    alias _mm_rcp_ps = __builtin_ia32_rcpps;
}

version(LDC)
{
    alias _mm_rcp_ss = __builtin_ia32_rcpss;
}

version(LDC)
{
    alias _mm_rsqrt_ps = __builtin_ia32_rsqrtps;
}

version(LDC)
{
    alias _mm_rsqrt_ss = __builtin_ia32_rsqrtss;
}

// TODO: _mm_sad_pu8
// TODO: void _MM_SET_EXCEPTION_MASK (unsigned int a)
// TODO: void _MM_SET_EXCEPTION_STATE (unsigned int a)
// TODO: void _MM_SET_FLUSH_ZERO_MODE (unsigned int a)

__m128 _mm_set_ps (float e3, float e2, float e1, float e0) pure @trusted
{
    float[4] result = [e0, e1, e2, e3];
    return loadUnaligned!(float4)(result.ptr);
}

alias _mm_set_ps1 = _mm_set1_ps;

// TODO: _MM_SET_ROUNDING_MODE

__m128 _mm_set_ss (float a) pure @trusted
{
    float[4] result = [a, 0.0f, 0.0f, 0.0f];
    return loadUnaligned!(float4)(result.ptr);
}

__m128 _mm_set1_ps (float a) pure @trusted
{
    float[4] result = [a, a, a, a];
    return loadUnaligned!(float4)(result.ptr);
}

// TODO: _mm_setcsr

__m128 _mm_setr_ps (float e3, float e2, float e1, float e0) pure @trusted
{
    float[4] result = [e3, e2, e1, e0];
    return loadUnaligned!(float4)(result.ptr);
}

__m128 _mm_setzero_ps() pure @trusted
{
    float[4] result = [0.0f, 0.0f, 0.0f, 0.0f];
    return loadUnaligned!(float4)(result.ptr);
}

version(LDC)
{
    alias _mm_sfence = __builtin_ia32_sfence;
}

// MMXREG: mm_shuffle_pi16

// Note: the immediate shuffle value is given at compile-time instead of runtime.
__m128 _mm_shuffle_ps(ubyte imm)(__m128 a, __m128 b) pure @safe
{
    return shufflevector!(__m128, imm & 3, (imm>>2) & 3, 4 + ((imm>>4) & 3), 4 + ((imm>>6) & 3) )(a, b);
}

version(LDC)
{
    alias _mm_sqrt_ps = __builtin_ia32_sqrtps;
}
else
{
     __m128 _mm_sqrt_ps(__m128 vec) pure @safe
    {
        import std.math: sqrt;
        vec.array[0] = sqrt(vec.array[0]);
        vec.array[1] = sqrt(vec.array[1]);
        vec.array[2] = sqrt(vec.array[2]);
        vec.array[3] = sqrt(vec.array[3]);
        return vec;
    }
}

version(LDC)
{
    alias _mm_sqrt_ss = __builtin_ia32_sqrtss;
}
else
{
    __m128 _mm_sqrt_ss(__m128 vec) pure @safe
    {
        import std.math: sqrt;
        vec.array[0] = sqrt(vec.array[0]);
        return vec;
    }
}

unittest
{
    __m128 A = _mm_sqrt_ps(_mm_set1_ps(4.0f));
    assert(A.array[0] == 2.0f);
}

void _mm_store_ps (float* mem_addr, __m128 a) pure // not safe since nothing guarantees alignment
{
    __m128* aligned = cast(__m128*)mem_addr;
    *aligned = a;
}

alias _mm_store_ps1 = _mm_store1_ps;

void _mm_store_ss (float* mem_addr, __m128 a) pure @safe
{
    *mem_addr = extractelement!(__m128, 0)(a);
}

void _mm_store1_ps (float* mem_addr, __m128 a) pure // not safe since nothing guarantees alignment
{
    __m128* aligned = cast(__m128*)mem_addr;
    *aligned = shufflevector!(__m128, 0, 0, 0, 0)(a, a);
}

void _mm_storeh_pi(__m64* p, __m128 a) pure @safe
{
    *p = extractelement!(long2, 1)(a);
}

void _mm_storel_pi(__m64* p, __m128 a) pure @safe
{
    *p = extractelement!(long2, 0)(a);
}

void _mm_storer_ps(float* mem_addr, __m128 a) pure // not safe since nothing guarantees alignment
{
    __m128* aligned = cast(__m128*)mem_addr;
    *aligned = shufflevector!(__m128, 3, 2, 1, 0)(a, a);
}

void _mm_storeu_ps(float* mem_addr, __m128 a) pure @safe
{
    storeUnaligned!(float4)(a, mem_addr);
}

// TODO: _mm_stream_pi, does not seem possible
// TODO: _mm_stream_ps, does not seem possible


__m128 _mm_sub_ps(__m128 a, __m128 b) pure @safe
{
    return a - b;
}

__m128 _mm_sub_ss(__m128 a, __m128 b) pure @safe
{
    // Note: the LLVM intrinsic "llvm.x86.sse2.sub.sd" disappeared
    return insertelement!(__m128, 0)(a, a.array[0] - b.array[0]);
}
unittest
{
    __m128 a = [1.5f, -2.0f, 3.0f, 1.0f];
    a = _mm_sub_ss(a, a);
    float[4] correct = [0.0f, -2.0, 3.0f, 1.0f];
    assert(a.array == correct);
}


void _MM_TRANSPOSE4_PS (ref __m128 row0, ref __m128 row1, ref __m128 row2, ref __m128 row3) pure @safe
{
    __m128 tmp3, tmp2, tmp1, tmp0;
    tmp0 = _mm_unpacklo_ps(row0, row1);
    tmp2 = _mm_unpacklo_ps(row2, row3);
    tmp1 = _mm_unpackhi_ps(row0, row1);
    tmp3 = _mm_unpackhi_ps(row2, row3);
    row0 = _mm_movelh_ps(tmp0, tmp2);
    row1 = _mm_movehl_ps(tmp2, tmp0);
    row2 = _mm_movelh_ps(tmp1, tmp3);
    row3 = _mm_movehl_ps(tmp3, tmp1);
}

version(LDC)
{
    alias _mm_ucomieq_ss = __builtin_ia32_ucomieq;
}

version(LDC)
{
    alias _mm_ucomige_ss = __builtin_ia32_ucomige;
}

version(LDC)
{
    alias _mm_ucomigt_ss = __builtin_ia32_ucomigt;
}

version(LDC)
{
    alias _mm_ucomile_ss = __builtin_ia32_ucomile;
}

version(LDC)
{
    alias _mm_ucomilt_ss = __builtin_ia32_ucomilt;
}

version(LDC)
{
    alias _mm_ucomineq_ss = __builtin_ia32_ucomineq;
}


__m128 _mm_undefined_ps() pure @safe
{
    __m128 undef = void;
    return undef;
}

__m128 _mm_unpackhi_ps (__m128 a, __m128 b) pure @safe
{
    return shufflevector!(float4, 2, 6, 3, 7)(a, b);
}

__m128 _mm_unpacklo_ps (__m128 a, __m128 b) pure @safe
{
    return shufflevector!(float4, 0, 4, 1, 5)(a, b);
}

__m128i _mm_xor_ps (__m128i a, __m128i b) pure @safe
{
    return a ^ b;
}