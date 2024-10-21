/**
* AVX512VNNI intrinsics.
* https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#techs=AVX512
*
* Copyright: cet 2024.
* License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module inteli.avx512intrin.vnni;

public import inteli.types;
import inteli.internals;

// Pull in all previous instruction set intrinsics.
public import inteli.avx2intrin;

nothrow:
@nogc:

// TODO: _mm256_dpbusd_epi32
// TODO: _mm256_dp_busds_epi32
// TODO: _mm_dpwssd_epi32
// TODO: _mm256_dpwssd_epi32
// TODO: _mm_dpwssds_epi32
// TODO: _mm256_dpwssds_epi32

/// Multiply and sum adjacent pairs of 4 unsigned 8-bit integers in `a` and `b` zero extended to 16-bits, add with `src`, and return the results.
__m128i _mm_dpbusd_epi32(
    const __m128i src, 
    const __m128i a, 
    const __m128i b
) pure
{
    // PERF GDC
    static if (!LDC_with_AVX512VNNI && LDC_with_AVX512VL)
        return cast(__m128i)__builtin_ia32_vpdpbusd128(
            cast(int4)src, 
            cast(byte16)a, 
            cast(byte16)b
        );
    else
    {
        import inteli.avx512intrin.core : _mm256_cvtepi32lo_epi16;

        // 3 cycles 1 throughput
        __m256i _a = _mm256_cvtepi8_epi16(a);
        __m256i _b = _mm256_cvtepi8_epi16(b);

        // 11 cycles .8 throughput
        _a = _mm256_mullo_epi16(_a, _b);
        _a = _mm256_hadd_epi16(_a, _a);
        _a = _mm256_hadd_epi16(_a, _a);

        // 5 cycles .5 throughput
        return _mm_add_epi32(_mm256_cvtepi32lo_epi16(_a), src);
    }
}

unittest
{
    __m128i a = _mm_setr_epi8(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16);
    assert(_mm_dpbusd_epi32(a, a, a).array == [67306015, 134678195, 202050503, 269422939]);
}

/// Multiply and sum adjacent pairs of 4 unsigned 8-bit integers in `a` and `b` zero extended to 16-bits, add with `src` with saturation, and return the results.
__m128i _mm_dpbusds_epi32(
    const __m128i src, 
    const __m128i a, 
    const __m128i b
) pure
{
    // PERF GDC
    static if (LDC_with_AVX512VNNI && LDC_with_AVX512VL)
        return cast(__m128i)__builtin_ia32_vpdpbusds128(
            cast(int4)src, 
            cast(byte16)a, 
            cast(byte16)b
        );
    else
    {
        import inteli.avx512intrin.core : _mm256_cvtepi32lo_epi16;

        __m256i _a = _mm256_cvtepi8_epi16(a);
        __m256i _b = _mm256_cvtepi8_epi16(b);

        _a = _mm256_mullo_epi16(_a, _b);
        _a = _mm256_hadd_epi16(_a, _a);
        _a = _mm256_hadd_epi16(_a, _a);

        return _mm_adds_epi32(_mm256_cvtepi32lo_epi16(_a), src);
    }
}