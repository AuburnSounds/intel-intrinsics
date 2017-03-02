/**
* Copyright: Copyright Auburn Sounds 2016.
* License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
* Authors:   Guillaume Piolat
*/
module inteli.xmmintrin;

version(LDC):

public import inteli.types;
import ldc.gccbuiltins_x86;
import ldc.simd;
import ldc.intrinsics;

// SSE1
// Note: intrinsics noted MMXREG are actually using MMX registers, 
// and were not translated. These intrinsics are for instruction
// introduced with SSE1, that also work on MMX registers.

nothrow @nogc:

__m128 _mm_add_ps(__m128 a, __m128 b) pure @safe
{
    return a + b;
}
pragma(LDC_intrinsic, "llvm.x86.sse.add.ss")
    __m128 _mm_add_ss(__m128, __m128) pure @safe;

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

pragma(LDC_intrinsic, "llvm.x86.sse.cmp.ps")
    __m128 __builtin_ia32_cmpps(__m128, __m128, byte) pure @safe;

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

alias _mm_comieq_ss = __builtin_ia32_comieq;
alias _mm_comige_ss = __builtin_ia32_comige;
alias _mm_comigt_ss = __builtin_ia32_comigt;
alias _mm_comile_ss = __builtin_ia32_comile;
alias _mm_comilt_ss = __builtin_ia32_comilt;
alias _mm_comineq_ss = __builtin_ia32_comineq;

// MMXREG: __m128 _mm_cvt_pi2ps (__m128 a, __m64 b)
// MMXREG: __m64 _mm_cvt_ps2pi (__m128 a)

alias _mm_cvt_si2ss = __builtin_ia32_cvtsi2ss;
alias _mm_cvt_ss2si = __builtin_ia32_cvtss2si;

// MMXREG: __m128 _mm_cvtpi16_ps (__m64 a)
// MMXREG: __m128 _mm_cvtpi32_ps (__m128 a, __m64 b)
// MMXREG: __m128 _mm_cvtpi32x2_ps (__m64 a, __m64 b)
// MMXREG: __m128 _mm_cvtpi8_ps (__m64 a)
// MMXREG: __m64 _mm_cvtps_pi16 (__m128 a)
// MMXREG: __m64 _mm_cvtps_pi32 (__m128 a)
// MMXREG: __m64 _mm_cvtps_pi8 (__m128 a)
// MMXREG: __m128 _mm_cvtpu16_ps (__m64 a)
// MMXREG: __m128 _mm_cvtpu8_ps (__m64 a)

alias _mm_cvtsi32_ss = __builtin_ia32_cvtsi2ss;
alias _mm_cvtsi64_ss = __builtin_ia32_cvtsi642ss;

float _mm_cvtss_f32(__m128 a) pure @safe
{
    return extractelement!(__m128, 0)(a);
}

alias _mm_cvtss_si32 = __builtin_ia32_cvtss2si;
alias _mm_cvtss_si64 = __builtin_ia32_cvtss2si64;
// MMXREG: __m64 _mm_cvtt_ps2pi (__m128 a)
alias _mm_cvtt_ss2si = __builtin_ia32_cvttss2si;
// MMXREG: _mm_cvttps_pi32
alias _mm_cvttss_si32 = _mm_cvtt_ss2si; // it's actually the same op
alias _mm_cvttss_si64 = __builtin_ia32_cvttss2si64;

float4 _mm_div_ps(float4 a, float4 b) pure @safe
{
    return a / b;
}
pragma(LDC_intrinsic, "llvm.x86.sse.div.ss")
    float4 _mm_div_ss(float4, float4) pure @safe;

// MMXREG: int _mm_extract_pi16 (__m64 a, int imm8)
// TODO: unsigned int _MM_GET_EXCEPTION_MASK ()
// TODO: unsigned int _MM_GET_EXCEPTION_STATE ()
// TODO: unsigned int _MM_GET_FLUSH_ZERO_MODE ()
// TODO: unsigned int _MM_GET_ROUNDING_MODE ()
// TODO: stmxcsr
// TODO: unsigned int _mm_getcsr (void)

// MMXREG: __m64 _mm_insert_pi16 (__m64 a, int i, int imm8)

float4 _mm_load_ps(const(float)*p)
{
    return *cast(__m128*)p;
}

float4 _mm_load_ps1(const(float)*p)
{
    float4 f = [ *p, *p, *p, *p ];
    return f;
}

float4 _mm_load_ss (const(float)* mem_addr) pure @safe
{
    float4 f = [ *mem_addr, 0.0f, 0.0f, 0.0f ];
    return f;
}

alias _mm_load1_ps = _mm_load_ps1;

__m128 _mm_loadh_pi (__m128 a, const(__m64)* mem_addr) pure @safe
{
    return insertelement!(long2, 1)(a, *mem_addr);
}

__m128 _mm_loadl_pi (__m128 a, const(__m64)* mem_addr) pure @safe
{
    return insertelement!(long2, 0)(a, *mem_addr);
}

__m128 _mm_loadr_ps (const(float)* mem_addr) pure
{
    __m128* aligned = cast(__m128*)mem_addr;
    __m128 a = *aligned;
    return shufflevector!(__m128, 3, 2, 1, 0)(a, a);
}

float4 _mm_loadu_ps(const(float)*p) pure
{
    return loadUnaligned!(__m128)(p);
}

// MMXREG: _mm_maskmove_si64
// MMXREG: _m_maskmovq

// MMXREG: _mm_max_pi16
alias _mm_max_ps = __builtin_ia32_maxps;
// MMXREG: _mm_max_pu8
alias _mm_max_ss = __builtin_ia32_maxss;

// MMXREG: _mm_min_pi16
alias _mm_min_ps = __builtin_ia32_minps;
// MMXREG: _mm_min_pi8
alias _mm_min_ss = __builtin_ia32_minss;

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
alias _mm_movemask_ps = __builtin_ia32_movmskps;

__m128 _mm_mul_ps(__m128 a, __m128 b) pure @safe
{
    return a * b;
}
pragma(LDC_intrinsic, "llvm.x86.sse.mul.ss")
    float4 _mm_mul_ss(float4, float4) pure @safe;

// MMXREG: _mm_mulhi_pu16

__m128 _mm_or_ps (__m128 a, __m128 b) pure @safe
{
    return a | b;
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

void _mm_prefetch(void* p, int locality) pure @safe
{
    llvm_prefetch(p, 0, locality, 1);
}

// MMXREG: __m64 _m_psadbw (__m64 a, __m64 b)
// MMXREG: __m64 _m_pshufw (__m64 a, int imm8)


alias _mm_rcp_ps = __builtin_ia32_rcpps;
alias _mm_rcp_ss = __builtin_ia32_rcpss;
alias _mm_rsqrt_ps = __builtin_ia32_rsqrtps;
alias _mm_rsqrt_ss = __builtin_ia32_rsqrtss;

// TODO: void _MM_SET_EXCEPTION_MASK (unsigned int a)
// TODO: void _MM_SET_EXCEPTION_STATE (unsigned int a)
// TODO: void _MM_SET_FLUSH_ZERO_MODE (unsigned int a)

__m128 _mm_set_ps (float e3, float e2, float e1, float e0) pure @safe
{
    return [e0, e1, e2, e3];
}

alias _mm_set_ps1 = _mm_set1_ps;

// TODO: _MM_SET_ROUNDING_MODE

__m128 _mm_set_ss (float a) pure @safe
{
    return [a, 0.0f, 0.0f, 0.0f];
}

__m128 _mm_set1_ps (float a) pure @safe
{
    return [a, a, a, a];
}

// TODO: _mm_setcsr

__m128 _mm_setr_ps (float e3, float e2, float e1, float e0) pure @safe
{
    return [e3, e2, e1, e0];
}

__m128 _mm_setzero_ps() pure @safe
{
    return [0, 0, 0, 0];
}

alias _mm_sfence = __builtin_ia32_sfence;

// MMXREG: mm_shuffle_pi16

// Note: the immediate shuffle value is given at compile-time instead of runtime.
__m128 _mm_shuffle_ps(ubyte imm)(__m128 a, __m128 b) pure @safe
{
    return shufflevector!(__m128, imm & 3, (imm>>2) & 3, 4 + ((imm>>4) & 3), 4 + ((imm>>6) & 3) )(a, b);
}

alias _mm_sqrt_ps = __builtin_ia32_sqrtps;
alias _mm_sqrt_ss = __builtin_ia32_sqrtss;

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
    storeUnaligned!__m128(a, mem_addr);
}

// TODO: _mm_stream_pi, does not seem possible
// TODO: _mm_stream_ps, does not seem possible


__m128 _mm_sub_ps(__m128 a, __m128 b) pure @safe
{
    return a - b;
}
pragma(LDC_intrinsic, "llvm.x86.sse.sub.ss")
    float4 _mm_sub_ss(float4, float4) pure @safe;

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

alias _mm_ucomieq_ss = __builtin_ia32_ucomieq;
alias _mm_ucomige_ss = __builtin_ia32_ucomige;
alias _mm_ucomigt_ss = __builtin_ia32_ucomigt;
alias _mm_ucomile_ss = __builtin_ia32_ucomile;
alias _mm_ucomilt_ss = __builtin_ia32_ucomilt;
alias _mm_ucomineq_ss = __builtin_ia32_ucomineq;

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