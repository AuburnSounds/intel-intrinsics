/**
* Copyright: Copyright Auburn Sounds 2016.
* License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
* Authors:   Guillaume Piolat
*/
module inteli.emmintrin;

version(LDC):

public import inteli.types;
import core.simd;
import ldc.simd;
import ldc.gccbuiltins_x86;

public import inteli.xmmintrin;

nothrow @nogc:


// SSE2
pragma(LDC_intrinsic, "llvm.x86.sse2.add.sd")
    double2 __builtin_ia32_addsd(double2, double2) pure @safe;
alias _mm_add_sd = __builtin_ia32_addsd;

alias _mm_clflush = __builtin_ia32_clflush;

pragma(LDC_intrinsic, "llvm.x86.sse2.cmp.pd")
    double2 __builtin_ia32_cmppd(double2, double2, byte) pure @safe;
alias _mm_cmpeq_pd = __builtin_ia32_cmppd;
alias _mm_cmpeq_sd = __builtin_ia32_cmpsd;
alias _mm_comieq_sd = __builtin_ia32_comisdeq;
alias _mm_comige_sd = __builtin_ia32_comisdge;
alias _mm_comigt_sd = __builtin_ia32_comisdgt;
alias _mm_comile_sd = __builtin_ia32_comisdle;
alias _mm_comilt_sd = __builtin_ia32_comisdlt;
alias _mm_comineq_sd = __builtin_ia32_comisdneq;

pragma(LDC_intrinsic, "llvm.x86.sse2.cvtdq2pd")
    double2 __builtin_ia32_cvtdq2pd(int4) pure @safe;
alias _mm_cvtepi32_pd = __builtin_ia32_cvtdq2pd;

alias _mm_cvtepi32_ps = __builtin_ia32_cvtdq2ps;
alias _mm_cvtpd_epi32 = __builtin_ia32_cvtpd2dq;
alias _mm_cvtpd_ps = __builtin_ia32_cvtpd2ps;
alias _mm_cvtps_epi32 = __builtin_ia32_cvtps2dq;

pragma(LDC_intrinsic, "llvm.x86.sse2.cvtps2pd")
    double2 __builtin_ia32_cvtps2pd(float4) pure @safe;
alias _mm_cvtps_pd = __builtin_ia32_cvtps2pd;

alias _mm_cvtsd_si32 = __builtin_ia32_cvtsd2si;
alias _mm_cvtsd_si64 = __builtin_ia32_cvtsd2si64;
alias _mm_cvtsd_ss = __builtin_ia32_cvtsd2ss;
alias _mm_cvtsi32_sd = __builtin_ia32_cvtsi2sd;
alias _mm_cvtsi64_sd = __builtin_ia32_cvtsi642sd;
alias _mm_cvtss_sd = __builtin_ia32_cvtss2sd;
alias _mm_cvttpd_epi32 = __builtin_ia32_cvttpd2dq;
alias _mm_cvttps_epi32 = __builtin_ia32_cvttps2dq;
alias _mm_cvttsd_si32 = __builtin_ia32_cvttsd2si;
alias _mm_cvttsd_si64 = __builtin_ia32_cvttsd2si64;

pragma(LDC_intrinsic, "llvm.x86.sse2.div.sd")
    double2 __builtin_ia32_divsd(double2, double2) pure @safe;
alias _mm_div_sd = __builtin_ia32_divsd;

alias _mm_lfence = __builtin_ia32_lfence;
alias _mm_maskmoveu_si128 = __builtin_ia32_maskmovdqu;
alias _mm_max_pd = __builtin_ia32_maxpd;
alias _mm_max_sd = __builtin_ia32_maxsd;
alias _mm_mfence = __builtin_ia32_mfence;
alias _mm_min_pd = __builtin_ia32_minpd;
alias _mm_min_sd = __builtin_ia32_minsd;
alias _mm_movemask_pd = __builtin_ia32_movmskpd;

pragma(LDC_intrinsic, "llvm.x86.sse2.mul.sd")
    double2 __builtin_ia32_mulsd(double2, double2) pure @safe;
alias _mm_mul_sd = __builtin_ia32_mulsd;

alias _mm_packs_epi32 = __builtin_ia32_packssdw128;
alias _mm_packs_epi16 = __builtin_ia32_packsswb128;
alias _mm_packus_epi16 = __builtin_ia32_packuswb128;
alias _mm_adds_epi8 = __builtin_ia32_paddsb128;
alias _mm_adds_epi16 = __builtin_ia32_paddsw128;
alias _mm_adds_epu8 = __builtin_ia32_paddusb128;
alias _mm_adds_epu16 = __builtin_ia32_paddusw128;
alias _mm_pause = __builtin_ia32_pause;
alias _mm_avg_epu8 = __builtin_ia32_pavgb128;
alias _mm_avg_epu16 = __builtin_ia32_pavgw128;
alias _mm_madd_epi16 = __builtin_ia32_pmaddwd128;

pragma(LDC_intrinsic, "llvm.x86.sse2.pmaxs.w")
    short8 __builtin_ia32_pmaxsw128(short8, short8) pure @safe;
alias _mm_max_epi16 = __builtin_ia32_pmaxsw128;

pragma(LDC_intrinsic, "llvm.x86.sse2.pmaxu.b")
    byte16 __builtin_ia32_pmaxub128(byte16, byte16) pure @safe;
alias _mm_max_epu8 = __builtin_ia32_pmaxub128;

pragma(LDC_intrinsic, "llvm.x86.sse2.pmins.w")
    short8 __builtin_ia32_pminsw128(short8, short8) pure @safe;
alias _mm_min_epi16 = __builtin_ia32_pminsw128;

pragma(LDC_intrinsic, "llvm.x86.sse2.pminu.b")
    byte16 __builtin_ia32_pminub128(byte16, byte16) pure @safe;
alias _mm_min_epu8 = __builtin_ia32_pminub128;

alias _mm_movemask_epi8 = __builtin_ia32_pmovmskb128;
alias _mm_mulhi_epi16 = __builtin_ia32_pmulhw128;
alias _mm_mulhi_epu16 = __builtin_ia32_pmulhuw128;
alias _mm_mul_epu32 = __builtin_ia32_pmuludq128;
alias _mm_sad_epu8 = __builtin_ia32_psadbw128;

__m128i _mm_setzero_si128() pure @safe
{
    return [0, 0, 0, 0];
}

pragma(LDC_intrinsic, "llvm.x86.sse2.pshuf.d")
    int4 __builtin_ia32_pshufd(int4, byte) pure @safe;
alias _mm_shuffle_epi32 = __builtin_ia32_pshufd;

pragma(LDC_intrinsic, "llvm.x86.sse2.pshufh.w")
    short8 __builtin_ia32_pshufhw(short8, byte) pure @safe;
alias _mm_shufflehi_epi16 = __builtin_ia32_pshufhw;

pragma(LDC_intrinsic, "llvm.x86.sse2.pshufl.w")
    short8 __builtin_ia32_pshuflw(short8, byte) pure @safe;
alias _mm_shufflelo_epi16 = __builtin_ia32_pshuflw;


alias _mm_sll_epi32 = __builtin_ia32_pslld128;
alias _mm_sll_epi64 = __builtin_ia32_psllq128;
alias _mm_sll_epi16 = __builtin_ia32_psllw128;
alias _mm_slli_epi32 = __builtin_ia32_pslldi128;
alias _mm_slli_epi64 = __builtin_ia32_psllqi128;
alias _mm_slli_epi16 = __builtin_ia32_psllwi128;

__m128i _mm_slli_si128(ubyte imm8)(__m128i op)
{
    static if (imm8 & 0xF0)
        return _mm_setzero_si128();
    else
        return shufflevector!(byte16,
        16 - imm8, 17 - imm8, 18 - imm8, 19 - imm8, 20 - imm8, 21 - imm8, 22 - imm8, 23 - imm8,
        24 - imm8, 25 - imm8, 26 - imm8, 27 - imm8, 28 - imm8, 29 - imm8, 30 - imm8, 31 - imm8)
        (_mm_setzero_si128(), op);
}

alias _mm_sra_epi32 = __builtin_ia32_psrad128;
alias _mm_sra_epi16 = __builtin_ia32_psraw128;
alias _mm_srai_epi32 = __builtin_ia32_psradi128;
alias _mm_srai_epi16= __builtin_ia32_psrawi128;
alias _mm_srl_epi32 = __builtin_ia32_psrld128;
alias _mm_srl_epi64 = __builtin_ia32_psrlq128;
alias _mm_srl_epi16 = __builtin_ia32_psrlw128;
alias _mm_srli_epi32 = __builtin_ia32_psrldi128;

__m128i _mm_srli_si128(ubyte imm8)(__m128i op)
{
    static if (imm8 & 0xF0)
        return _mm_setzero_si128();
    else
        return shufflevector!(byte16,
        imm8+0, imm8+1, imm8+2, imm8+3, imm8+4, imm8+5, imm8+6, imm8+7,
        imm8+8, imm8+9, imm8+10, imm8+11, imm8+12, imm8+13, imm8+14, imm8+15)(op, _mm_setzero_si128());
}

alias _mm_bsrli_si128 = _mm_srli_si128;

alias _mm_srlq_epi32 = __builtin_ia32_psrlqi128;
alias _mm_srlw_epi32 = __builtin_ia32_psrlwi128;

alias _mm_subs_epi8 = __builtin_ia32_psubsb128;
alias _mm_subs_epi16 = __builtin_ia32_psubsw128;
alias _mm_subs_epu8 = __builtin_ia32_psubusb128;
alias _mm_subs_epu16 = __builtin_ia32_psubusw128;
alias _mm_sqrt_pd = __builtin_ia32_sqrtpd;
alias _mm_sqrt_sd = __builtin_ia32_sqrtsd;

pragma(LDC_intrinsic, "llvm.x86.sse2.storel.dq")
    void __builtin_ia32_storelv4si(void*, int4);
alias _mm_storel_epi64 = __builtin_ia32_storelv4si;

pragma(LDC_intrinsic, "llvm.x86.sse2.storeu.dq")
    void __builtin_ia32_storedqu(void*, byte16);
alias _mm_store_si128 = __builtin_ia32_storedqu;

pragma(LDC_intrinsic, "llvm.x86.sse2.storeu.pd")
    void __builtin_ia32_storeupd(void*, double2);
alias _mm_storeu_pd = __builtin_ia32_storeupd;

pragma(LDC_intrinsic, "llvm.x86.sse2.sub.sd")
    double2 __builtin_ia32_subsd(double2, double2) pure @safe;
alias _mm_sub_sd = __builtin_ia32_subsd;

alias _mm_ucomieq_sd = __builtin_ia32_ucomisdeq;
alias _mm_ucomige_sd = __builtin_ia32_ucomisdge;
alias _mm_ucomigt_sd = __builtin_ia32_ucomisdgt;
alias _mm_ucomile_sd = __builtin_ia32_ucomisdle;
alias _mm_ucomilt_sd = __builtin_ia32_ucomisdlt;
alias _mm_ucomineq_sd = __builtin_ia32_ucomisdneq;

unittest
{
    // distance between two points in 4D
    float distance(float[4] a, float[4] b) nothrow @nogc
    {
        __m128 va = _mm_loadu_ps(a.ptr);
        __m128 vb = _mm_loadu_ps(b.ptr);
        __m128 diffSquared = _mm_sub_ps(va, vb);
        diffSquared = _mm_mul_ps(diffSquared, diffSquared);
        __m128 sum = _mm_add_ps(diffSquared, _mm_srli_si128!8(diffSquared));
        sum = _mm_add_ps(sum, _mm_srli_si128!4(sum));
        return _mm_cvtss_f32(_mm_sqrt_ss(sum));
    }
    assert(distance([0, 2, 0, 0], [0, 0, 0, 0]) == 2);
}