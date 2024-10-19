/**
* AVX512-VPOPCNTDQ intrinsics.
* https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#techs=AVX512
*
* Copyright: cet 2024.
* License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module inteli.vpopcntdqintrin;

public import inteli.types;
import inteli.internals;

// Pull in all previous instruction set intrinsics.
public import inteli.avx2intrin;

// TODO: _mm256_popcnt_epi8
// TODO: _mm256_popcnt_epi16
// TODO: _mm_popcnt_epi8
// TODO: _mm_popcnt_epi16
// TODO: _mm_popcnt_epi32
// TODO: _mm_popcnt_epi64

/// Count the number of logical 1 bits in a, sum all result elements, and return the final count.
/// #BONUS
int _mm256_popcnt(const __m256i a) pure
{
    // We use the 32-bit variant here because it has better pathing.
    __m256i cnt = _mm256_popcnt_epi32(a);
    // Total approx 10~11 cycles but optimized for throughput so this should be ok.
    // 6 cycles 1 throughput
    cnt = _mm256_hadd_epi32(cnt, cnt);
    cnt = _mm256_hadd_epi32(cnt, cnt);
    // 4 cycles .33 throughput (throttled by the add)
    cnt = _mm256_add_epi32(cnt, _mm256_permute2f128_si256!0b01110001(cnt, cnt));
    return (cast(int8)cnt)[0];
}

unittest
{
    __m256i a = _mm256_set1_epi32(0b11100110);
    assert(_mm256_popcnt(a) == 40);
}

/// Count the number of logical 1 bits in packed 32-bit integers in a and return the results.
__m256i _mm256_popcnt_epi32(const __m256i a) pure
{
    // TODO: Fix, same issue as _mm256_bslli_epi128.
    static if (LDC_with_AVX512VPOPCNTDQ)
    {
        return cast(__m256i)__asm!(int8)("
            vpopcntd $1, $0"
        , "=v,v", a);
    }
    else
    {
        const __m256i mask = _mm256_set1_epi8(0x0f);
        const __m256i lookup = _mm256_setr_epi8(
            /* 0 */ 0, /* 1 */ 1, /* 2 */ 1, /* 3 */ 2,
            /* 4 */ 1, /* 5 */ 2, /* 6 */ 2, /* 7 */ 3,
            /* 8 */ 1, /* 9 */ 2, /* a */ 2, /* b */ 3,
            /* c */ 2, /* d */ 3, /* e */ 3, /* f */ 4,

            /* 0 */ 0, /* 1 */ 1, /* 2 */ 1, /* 3 */ 2,
            /* 4 */ 1, /* 5 */ 2, /* 6 */ 2, /* 7 */ 3,
            /* 8 */ 1, /* 9 */ 2, /* a */ 2, /* b */ 3,
            /* c */ 2, /* d */ 3, /* e */ 3, /* f */ 4
        );

        const __m256i lo  = _mm256_and_si256(a, mask);
        const __m256i hi  = _mm256_and_si256(_mm256_srli_epi16(a, 4), mask);

        __m256i ret = _mm256_shuffle_epi8(lookup, lo);
        ret = _mm256_add_epi8(ret, _mm256_shuffle_epi8(lookup, hi));

        return ret;
    }
}

unittest
{
    __m256i a = _mm256_set1_epi32(0b11100110);
    assert((cast(int8)_mm256_popcnt_epi32(a)).array == [5, 5, 5, 5, 5, 5, 5, 5]);
}

/// Count the number of logical 1 bits in packed 64-bit integers in a and return the results.
__m256i _mm256_popcnt_epi64(const __m256i a) pure
{
    static if (LDC_with_AVX512VPOPCNTDQ)
    {
        return cast(__m256i)__asm!(long4)("
            vpopcntq $1, $0"
        , "=v,v", a);
    }
    else
    {
        // There's probably a better way to do this, but I don't know it and this likely isn't much worse.
        __m256i ret = _mm256_popcnt_epi32(a);
        return _mm256_sad_epu8(_mm256_setzero_si256(), ret);
    }
}

unittest
{
    __m256i a = _mm256_set_epi64x(1, 2, 3, 4);
    assert(_mm256_popcnt_epi64(a).array == [1, 2, 1, 1]);
}