/**
* AVX512-VNNI intrinsics.
* https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#techs=AVX512
*
* Copyright: cet 2024.
* License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module inteli.vnniintrin;

public import inteli.types;
import inteli.internals;

// Pull in all previous instruction set intrinsics.
public import inteli.avx2intrin;

// TODO: _mm256_dpbusd_epi32
// TODO: _mm_dpbusds_epi32
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
    static if (LDC_with_AVX512VNNI && LDC_with_AVX512VL)
        return cast(__m128i)__builtin_ia32_vpdpbusd128(
            cast(int4)src, 
            cast(byte16)a, 
            cast(byte16)b
        );
    else
    {
        const __m256i mask = _mm256_setr_epi8(
            0, 1,
            -1, -1,
            2, 3,
            -1, -1,
            -1, -1,
            -1, -1,
            -1, -1,
            -1, -1,
            -1, -1,
            -1, -1,
            -1, -1,
            -1, -1,
            0, 1,
            -1, -1,
            2, 3,
            -1, -1
        );

        __m256i _a = _mm256_cvtepi8_epi16(a);
        __m256i _b = _mm256_cvtepi8_epi16(b);

        // Do the multiplication and addition of the bytes.
        _a = _mm256_mullo_epi16(_a, _b);
        _a = _mm256_hadd_epi16(_a, _a);
        _a = _mm256_hadd_epi16(_a, _a);

        // TODO: This could be used to implement cvtepi16_epi32
        // Pack the word products to dwords.
        _a = _mm256_shuffle_epi8(_a, mask);
        _a = _mm256_permute4x64_epi64!(0b00001100)(_a);

        // Drop the last 128 bits and add the source.
        return _mm_add_epi32(_mm256_castsi256_si128(_a), src);
    }
}

unittest
{
    __m128i a = _mm_setr_epi8(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16);
    assert(_mm_dpbusd_epi32(a, a, a).array == [67306015, 134678195, 202050503, 269422939]);
}