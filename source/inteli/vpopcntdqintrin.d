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

/// Count the number of logical 1 bits in packed 32-bit integers in a and return the results.
__m256i _mm256_popcnt_epi32(__m256i a)
{
    static if (LDC_with_AVX512VPOPCNTDQ)
    {
        return cast(__m256i)__asm!(int8)("
            vpopcntd $1, $1"
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
    auto a = _mm256_set1_epi32(0b11100110);
    assert((cast(int8)_mm256_popcnt_epi32(a)).array == [5, 5, 5, 5, 5, 5, 5, 5]);
}

/// Count the number of logical 1 bits in packed 64-bit integers in a and return the results.
__m256i _mm256_popcnt_epi64(__m256i a)
{
    static if (LDC_with_AVX512VPOPCNTDQ)
    {
        return cast(__m256i)__asm!(long4)("
            vpopcntq $1, $1"
        , "=v,v", a);
    }
    else
    {
        // There's probably a better way to do this, but I don't it and this likely isn't much worse.
        __m256i ret = _mm256_popcnt_epi32(a);
        ret = _mm256_and_si256(ret, _mm256_set_epi32(0, uint.max, 0, uint.max, 0, uint.max, 0, uint.max));
        return _mm256_add_epi32(ret, ret);
    }
}

unittest
{
    auto a = _mm256_set1_epi32(0b11100110);
    assert(_mm256_popcnt_epi64(a).array == [10, 10, 10, 10]);
}