/**
* AVX512F intrinsics.
* https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#techs=AVX512
*
* Copyright: cet 2024.
* License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module inteli.avx512intrin.core;

public import inteli.types;
import inteli.internals;

// Pull in all previous instruction set intrinsics.
public import inteli.avx2intrin;

nothrow:
@nogc:

/// Sign extend 16-bit integers of the low halves of each lane in `a` to 32-bit integers and return the results.
/// #BONUS
__m128i _mm256_cvtepi32lo_epi16(__m256i a) pure
{
    // I don't think there's any way to optimize this more.
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

    return _mm256_castsi256_si128(
        _mm256_permute4x64_epi64!(0b00001100)(_mm256_shuffle_epi8(a, mask))
    );
}

unittest
{
    __m256i a = _mm256_setr_epi16(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16);
    assert(cast(int[])_mm256_cvtepi32lo_epi16(a).array == [1, 2, 9, 10]);
}