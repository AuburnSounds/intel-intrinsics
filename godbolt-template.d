// Note: this is a godbolt template that can help to new intrinsics
import core.simd;

version(GNU) import gcc.builtins;
version(LDC) import ldc.simd;
version(LDC) import ldc.intrinsics;
version(LDC) import ldc.gccbuiltins_x86;

// <YOUR CODE HERE>




// </YOUR CODE HERE>

static if (LDC_with_optimizations) // this save time for bigger projects, since LDCInlineIR gets more expensive there.
{
    /// Provides packed float comparisons
    package int4 cmpps(FPComparison comparison)(float4 a, float4 b) pure @safe
    {
        enum ir = `
            %cmp = fcmp `~ FPComparisonToString[comparison] ~` <4 x float> %0, %1
            %r = sext <4 x i1> %cmp to <4 x i32>
            ret <4 x i32> %r`;

        return LDCInlineIR!(ir, int4, float4, float4)(a, b);
    }

    ///ditto
    package int8 cmpps256(FPComparison comparison)(float8 a, float8 b) pure @safe
    {
        enum ir = `
            %cmp = fcmp `~ FPComparisonToString[comparison] ~` <8 x float> %0, %1
            %r = sext <8 x i1> %cmp to <8 x i32>
            ret <8 x i32> %r`;
        return LDCInlineIR!(ir, int8, float8, float8)(a, b);
    }

    /// Provides packed double comparisons
    package long2 cmppd(FPComparison comparison)(double2 a, double2 b) pure @safe
    {
        enum ir = `
            %cmp = fcmp `~ FPComparisonToString[comparison] ~` <2 x double> %0, %1
            %r = sext <2 x i1> %cmp to <2 x i64>
            ret <2 x i64> %r`;

        return LDCInlineIR!(ir, long2, double2, double2)(a, b);
    }

    ///ditto 
    package long4 cmppd256(FPComparison comparison)(double4 a, double4 b) pure @safe
    {
        enum ir = `
            %cmp = fcmp `~ FPComparisonToString[comparison] ~` <4 x double> %0, %1
            %r = sext <4 x i1> %cmp to <4 x i64>
            ret <4 x i64> %r`;
        return LDCInlineIR!(ir, long4, double4, double4)(a, b);
    }

    /// CMPSS-style comparisons
    /// clang implement it through x86 intrinsics, it is possible with IR alone
    /// but leads to less optimal code.
    /// PERF: try to implement it with __builtin_ia32_cmpss and immediate 0 to 7. 
    /// Not that simple.
    package float4 cmpss(FPComparison comparison)(float4 a, float4 b) pure @safe
    {
        /*
        enum ubyte predicateNumber = FPComparisonToX86Predicate[comparison];
        enum bool invertOp = (predicateNumber & 0x80) != 0;
        static if(invertOp)
            return __builtin_ia32_cmpsd(b, a, predicateNumber & 0x7f);
        else
            return __builtin_ia32_cmpsd(a, b, predicateNumber & 0x7f);
        */
        enum ir = `
            %cmp = fcmp `~ FPComparisonToString[comparison] ~` float %0, %1
            %r = sext i1 %cmp to i32
            %r2 = bitcast i32 %r to float
            ret float %r2`;

        float4 r = a;
        r[0] = LDCInlineIR!(ir, float, float, float)(a[0], b[0]);
        return r;
    }

    /// CMPSD-style comparisons
    /// clang implement it through x86 intrinsics, it is possible with IR alone
    /// but leads to less optimal code.
    /// PERF: try to implement it with __builtin_ia32_cmpsd and immediate 0 to 7. 
    /// Not that simple.    
    package double2 cmpsd(FPComparison comparison)(double2 a, double2 b) pure @safe
    {
        enum ir = `
            %cmp = fcmp `~ FPComparisonToString[comparison] ~` double %0, %1
            %r = sext i1 %cmp to i64
            %r2 = bitcast i64 %r to double
            ret double %r2`;

        double2 r = a;
        r[0] = LDCInlineIR!(ir, double, double, double)(a[0], b[0]);
        return r;
    }
}
else
{
    /// Provides packed float comparisons
    package int4 cmpps(FPComparison comparison)(float4 a, float4 b) pure @trusted
    {
        int4 result;
        foreach(i; 0..4)
        {
            result.ptr[i] = compareFloat!float(comparison, a.array[i], b.array[i]) ? -1 : 0;
        }
        return result;
    }
    ///ditto
    package int8 cmpps256(FPComparison comparison)(float8 a, float8 b) pure @trusted
    {
        int8 result;
        foreach(i; 0..8)
        {
            result.ptr[i] = compareFloat!float(comparison, a.array[i], b.array[i]) ? -1 : 0;
        }
        return result;
    }

    /// Provides packed double comparisons
    package long2 cmppd(FPComparison comparison)(double2 a, double2 b) pure @trusted
    {
        long2 result;
        foreach(i; 0..2)
        {
            result.ptr[i] = compareFloat!double(comparison, a.array[i], b.array[i]) ? -1 : 0;
        }
        return result;
    }
    ///ditto
    package long4 cmppd256(FPComparison comparison)(double4 a, double4 b) pure @trusted
    {
        long4 result;
        foreach(i; 0..4)
        {
            result.ptr[i] = compareFloat!double(comparison, a.array[i], b.array[i]) ? -1 : 0;
        }
        return result;
    }

    /// Provides CMPSS-style comparison
    package float4 cmpss(FPComparison comparison)(float4 a, float4 b) pure @trusted
    {
        int4 result = cast(int4)a;
        result.ptr[0] = compareFloat!float(comparison, a.array[0], b.array[0]) ? -1 : 0;
        return cast(float4)result;
    }

    /// Provides CMPSD-style comparison
    package double2 cmpsd(FPComparison comparison)(double2 a, double2 b) pure @trusted
    {
        long2 result = cast(long2)a;
        result.ptr[0] = compareFloat!double(comparison, a.array[0], b.array[0]) ? -1 : 0;
        return cast(double2)result;
    }
}

version(GNU)
{
    enum MMXSizedVectorsAreEmulated = false;
    enum SSESizedVectorsAreEmulated = false;

    enum GDC_with_MMX = true;
    
    static if (!is(Vector!(float[8])))
    {
        enum AVXSizedVectorsAreEmulated = true;
        struct float8
        {
            float[8] array;
            alias ptr = array;
        }
    }
    else
    {
        enum AVXSizedVectorsAreEmulated = false;
    }

    static if (!is(Vector!(double[4])))
    {
        struct double4
        {
            double[4] array;
            alias ptr = array;
        }
    }
    static if (!is(Vector!(long[4])))
    {
        struct long4
        {
            long[4] array;
            alias ptr = array;
        }
    }
    static if (!is(Vector!(short[16])))
    {
        struct short16
        {
            short[16] array;
            alias ptr = array;
        }
    }

     static if (!is(Vector!(int[8])))
    {
        struct int8
        {
            int[8] array;
            alias ptr = array;
        }
    }

     static if (!is(Vector!(byte[32])))
    {
        struct byte32
        {
            byte[32] array;
            alias ptr = array;
        }
    }
}
else
{
    enum GDC_with_MMX = false;
}


version(DigitalMars)
{
    version(D_SIMD)
    {
        version(D_AVX2)
        {

        }
        else
        {
            struct double4
            {
                double[4] array;
                alias ptr = array;
            }

            struct float8
            {
                float[8] array;
                alias ptr = array;
            }

            struct long4
            {
                long[4] array;
                alias ptr = array;
            }
        }
    }
    else
    {
        struct double4
        {
            double[4] array;
            alias ptr = array;
        }

        struct float8
        {
            float[8] array;
            alias ptr = array;
        }

        struct long4
        {
            long[4] array;
            alias ptr = array;
        }
        

        struct long1
        {
            long[1] array;
            alias ptr = array;
        }

        struct short4
        {
            short[4] array;
            alias ptr = array;
        }

        struct int2
        {
            int[2] array;
            alias ptr = array;
        }
    }

    version(D_SIMD)
    {
        enum DMD_with_DSIMD = true;
    }
    else
        enum DMD_with_DSIMD = false;
}
else
    enum DMD_with_DSIMD = false;

enum DMD_with_32bit_asm = false;

version(LDC)
{
    alias Vector!(long [1]) long1;
    alias Vector!(float[2]) float2;
    alias Vector!(int  [2]) int2;
    alias Vector!(short[4]) short4;
    alias Vector!(byte [8]) byte8;

    enum MMXSizedVectorsAreEmulated = false;
    enum SSESizedVectorsAreEmulated = false;
    enum AVXSizedVectorsAreEmulated = false;
}

alias __m64 = long1;

alias __m128i = int4;
alias __m128 = float4;
alias __m128d = double2;

alias __m256 = float8;
alias __m256d = double4;
alias __m256i = long4;


version(LDC)
{
    version(ARM)
    {
        enum LDC_with_ARM32 = true;
    }
    else
        enum LDC_with_ARM32 = false;

    enum LDC_with_SSE   = __traits(targetHasFeature, "sse");
    enum LDC_with_SSE2  = __traits(targetHasFeature, "sse2");
    enum LDC_with_SSE3  = __traits(targetHasFeature, "sse3");
    enum LDC_with_SSSE3 = __traits(targetHasFeature, "ssse3");
    enum LDC_with_AVX   = __traits(targetHasFeature, "avx");
    enum LDC_with_AVX2  = __traits(targetHasFeature, "avx2");
    
    enum LDC_with_ARM64 = __traits(targetHasFeature, "neon");
    enum LDC_with_SSE41 = __traits(targetHasFeature, "sse4.1");
    enum LDC_with_SSE42 = __traits(targetHasFeature, "sse4.2");

    enum LDC_with_AVX512F = __traits(targetHasFeature, "avx512f") && LDC_with_ia32_builtins;
    enum LDC_with_AVX512CD = __traits(targetHasFeature, "avx512cd") && LDC_with_ia32_builtins;
    enum LDC_with_AVX512ER = __traits(targetHasFeature, "avx512er") && LDC_with_ia32_builtins;
    enum LDC_with_AVX512PF = __traits(targetHasFeature, "avx512pf") && LDC_with_ia32_builtins;
    enum LDC_with_AVX512BW = __traits(targetHasFeature, "avx512bw") && LDC_with_ia32_builtins;
    enum LDC_with_AVX512DQ = __traits(targetHasFeature, "avx512dq") && LDC_with_ia32_builtins;
    enum LDC_with_AVX512VL = __traits(targetHasFeature, "avx512vl") && LDC_with_ia32_builtins;
    enum LDC_with_AVX512IFMA = __traits(targetHasFeature, "avx512ifma") && LDC_with_ia32_builtins;
    enum LDC_with_AVX512VBMI = __traits(targetHasFeature, "avx512vbmi") && LDC_with_ia32_builtins;
    enum LDC_with_AVX512VBMI2 = __traits(targetHasFeature, "avx512vbmi2") && LDC_with_ia32_builtins;

    enum LDC_with_AVX512FP16 = __traits(targetHasFeature, "avx512fp16") && LDC_with_ia32_builtins;
    enum LDC_with_AVX512BF16 = __traits(targetHasFeature, "avx512bf16") && LDC_with_ia32_builtins;
    enum LDC_with_AVX512VNNI = __traits(targetHasFeature, "avx512vnni") && LDC_with_ia32_builtins;
    enum LDC_with_AVX512BITALG = __traits(targetHasFeature, "avx512bitalg") && LDC_with_ia32_builtins;

    enum LDC_with_AVX512VP2INTERSECT = __traits(targetHasFeature, "avx512vp2intersect") && LDC_with_ia32_builtins;
    enum LDC_with_AVX512VPOPCNTDQ = __traits(targetHasFeature, "avx512vpopcntdq") && LDC_with_ia32_builtins;


    version(WebAssembly)
    {
        enum LDC_with_WASM32 = (void*).sizeof == 4;
        enum LDC_with_WASM64 = (void*).sizeof == 8;
        enum LDC_with_WASM_SIMD = (LDC_with_WASM32 || LDC_with_WASM64) && __traits(targetHasFeature, "simd128");
    }
    else
    {
        enum LDC_with_WASM32 = false;
        enum LDC_with_WASM64 = false;
        enum LDC_with_WASM_SIMD = false;
    }
    alias shufflevectorLDC = shufflevector;

     enum LDC_with_WASM_RELAXED_SIMD = LDC_with_WASM_SIMD
            && (__VERSION__ >= 2103) // LDC 1.33+, relaxed SIMD builtins came at about this time
            && __traits(targetHasFeature, "relaxed-simd");
}
else
{
    enum LDC_with_SSE = false;
    enum LDC_with_SSE2 = false;
    enum LDC_with_SSE3 = false;
    enum LDC_with_SSSE3 = false;
    enum LDC_with_AVX = false;
    enum LDC_with_AVX2 = false;
    
    enum LDC_with_ARM32 = false;
    enum LDC_with_ARM64 = false;
    
    enum LDC_with_SSE41 = false;
    enum LDC_with_SSE42 = false;

    enum LDC_with_AVX512F = false;
    enum LDC_with_AVX512CD = false;
    enum LDC_with_AVX512ER = false;
    enum LDC_with_AVX512PF = false;
    enum LDC_with_AVX512BW = false;
    enum LDC_with_AVX512DQ = false;
    enum LDC_with_AVX512VL = false;
    enum LDC_with_AVX512IFMA = false;
    enum LDC_with_AVX512VBMI = false;
    enum LDC_with_AVX512VBMI2 = false;

    enum LDC_with_AVX512FP16 = false;
    enum LDC_with_AVX512BF16 = false;
    enum LDC_with_AVX512VNNI = false;
    enum LDC_with_AVX512BITALG = false;

    enum LDC_with_AVX512VP2INTERSECT = false;
    enum LDC_with_AVX512VPOPCNTDQ = false;
    enum LDC_with_WASM32 = false;
    enum LDC_with_WASM64 = false;
    enum LDC_with_WASM_SIMD = false;
    enum LDC_with_WASM_RELAXED_SIMD = false;

}

enum LDC_with_ARM = LDC_with_ARM32 | LDC_with_ARM64;
enum LDC_with_WASM = LDC_with_WASM32 | LDC_with_WASM64;

version(GNU)
{
    static if (__VERSION__ >= 2100) // Starting at GDC 12.1
    {
        enum GDC_with_AVX2 = __traits(compiles, __builtin_ia32_mpsadbw256);
        enum GDC_with_AVX = __traits(compiles, __builtin_ia32_vbroadcastf128_pd256);        
        enum GDC_with_SSE2 = true;
        enum GDC_with_SSE = true;
        enum GDC_with_SSE41 = __traits(compiles, __builtin_ia32_blendps);
        enum GDC_with_SSE42 = __traits(compiles, __builtin_ia32_pcmpgtq);
        enum GDC_with_SSSE3 = __traits(compiles, __builtin_ia32_pshufb128);
    }
    else
    {
        enum GDC_with_SSE = false;
        enum GDC_with_SSE2 = false;
        enum GDC_with_AVX = false;
        enum GDC_with_AVX2 = false;
        enum GDC_with_SSE41 = false;
        enum GDC_with_SSE42 = false;
        enum GDC_with_SSSE3 = false;
    }
}
else
{
    enum GDC_with_SSE = false;
    enum GDC_with_SSE2 = false;
    enum GDC_with_AVX = false;
    enum GDC_with_AVX2 = false;
    enum GDC_with_SSE41 = false;
    enum GDC_with_SSE42 = false;
    enum GDC_with_SSSE3 = false;
}

enum GDC_or_LDC_with_AVX = LDC_with_AVX || GDC_with_AVX;
enum GDC_or_LDC_with_AVX2 = LDC_with_AVX2 || GDC_with_AVX2;


version(LDC)
{
    // Since LDC 1.13, using the new ldc.llvmasm.__ir variants instead of inlineIR
    static if (__VERSION__ >= 2083)
    {
         import ldc.llvmasm;
         alias LDCInlineIR = __ir_pure;

         // A version of inline IR with prefix/suffix didn't exist before LDC 1.13
         alias LDCInlineIREx = __irEx_pure; 
    }
    else
    {
        alias LDCInlineIR = inlineIR;
    }
}

version(LDC)
{
    static if (__VERSION__ >= 2097) // LDC 1.27+
    {
        pragma(LDC_intrinsic, "llvm.abs.i#")
            T inteli_llvm_abs(T)(T val, bool attrib);
    }

    static if (__VERSION__ >= 2092) // LDC 1.22+
    {
        pragma(LDC_intrinsic, "llvm.sadd.sat.i#")
            T inteli_llvm_adds(T)(T a, T b) pure @safe;
        pragma(LDC_intrinsic, "llvm.ssub.sat.i#")
            T inteli_llvm_subs(T)(T a, T b) pure @safe;
        pragma(LDC_intrinsic, "llvm.uadd.sat.i#")
            T inteli_llvm_addus(T)(T a, T b) pure @safe;
        pragma(LDC_intrinsic, "llvm.usub.sat.i#")
            T inteli_llvm_subus(T)(T a, T b) pure @safe;
    }
}

static if (__VERSION__ >= 2102)
{
    enum SIMD_COMPARISON_MASKS_8B  = !MMXSizedVectorsAreEmulated; // can do < <= => > with builtin 8 bytes __vectors.
    enum SIMD_COMPARISON_MASKS_16B = !SSESizedVectorsAreEmulated; // can do < <= => > with builtin 16 bytes __vectors.
    enum SIMD_COMPARISON_MASKS_32B = !AVXSizedVectorsAreEmulated; // can do < <= => > with builtin 32 bytes __vectors.
}
else
{
    enum SIMD_COMPARISON_MASKS_8B = false;
    enum SIMD_COMPARISON_MASKS_16B = false;
    enum SIMD_COMPARISON_MASKS_32B = false;
}

version(LDC)
{
    version(D_Optimized)
    {
        enum bool LDC_with_optimizations = true;
    }
    else
    {
        enum bool LDC_with_optimizations = false;
    }
}
else
{
    enum bool LDC_with_optimizations = false;
}

__m128i _mm256_extractf128_si256(ubyte imm8)(__m256i a) pure @trusted
{
    version(GNU) pragma(inline, true); // else GDC has trouble inlining this

    // PERF DMD
    static if (GDC_with_AVX)
    {
        // Note: if it weren't for this GDC intrinsic, _mm256_extractf128_si256
        // could be a non-template, however, this wins in -O0.
        // Same story for _mm256_extractf128_ps and _mm256_extractf128_pd
        return __builtin_ia32_vextractf128_si256(cast(int8)a, imm8 & 1);
    }
    else
    {
        long2 r = void;
        enum int index = 2*(imm8 & 1);
        r.ptr[0] = a.array[index+0];
        r.ptr[1] = a.array[index+1];
        return cast(__m128i)r;
    }
}

__m256i _mm256_set_m128i (__m128i hi, __m128i lo) pure @trusted
{
    // DMD PERF
    static if (GDC_with_AVX)
    {
        __m256i r = cast(long4) __builtin_ia32_si256_si (lo);
        return cast(long4) __builtin_ia32_vinsertf128_si256(cast(int8)r, hi, 1);
    }
    else
    {
        int8 r = void;
        r.ptr[0] = lo.array[0];
        r.ptr[1] = lo.array[1];
        r.ptr[2] = lo.array[2];
        r.ptr[3] = lo.array[3];
        r.ptr[4] = hi.array[0];
        r.ptr[5] = hi.array[1];
        r.ptr[6] = hi.array[2];
        r.ptr[7] = hi.array[3];
        return cast(long4)r;
    }
}

// Individual float comparison: returns -1 for true or 0 for false.
// Useful for DMD and testing
private bool compareFloat(T)(FPComparison comparison, T a, T b) pure @safe
{
    bool unordered = isnan(a) || isnan(b);
    final switch(comparison) with(FPComparison)
    {
        case false_: return false;
        case oeq: return a == b;
        case ogt: return a > b;
        case oge: return a >= b;
        case olt: return a < b;
        case ole: return a <= b;
        case one: return !unordered && (a != b); // NaN with != always yields true
        case ord: return !unordered; 
        case ueq: return unordered || (a == b);
        case ugt: return unordered || (a > b);
        case uge: return unordered || (a >= b);
        case ult: return unordered || (a < b);
        case ule: return unordered || (a <= b);
        case une: return (a != b); // NaN with != always yields true
        case uno: return unordered;
        case true_: return true;
    }
}

bool isnan(float x) pure @trusted
{
    uint u = *cast(uint*)(&x);
    bool result = ((u & 0x7F800000) == 0x7F800000) && (u & 0x007FFFFF);
    return result;
}


private static immutable string[FPComparison.max+1] FPComparisonToString =
[
    "false",
    "oeq",
    "ogt",
    "oge",
    "olt",
    "ole",
    "one",
    "ord",
    "ueq",
    "ugt",
    "uge",
    "ult",
    "ule",
    "une",
    "uno",
    "true"
];

enum FPComparison
{
    false_,// always false
    oeq,   // ordered and equal
    ogt,   // ordered and greater than
    oge,   // ordered and greater than or equal
    olt,   // ordered and less than
    ole,   // ordered and less than or equal
    one,   // ordered and not equal
    ord,   // ordered (no nans)
    ueq,   // unordered or equal
    ugt,   // unordered or greater than ("nle")
    uge,   // unordered or greater than or equal ("nlt")
    ult,   // unordered or less than ("nge")
    ule,   // unordered or less than or equal ("ngt")
    une,   // unordered or not equal ("neq")
    uno,   // unordered (either nans)
    true_, // always true
}

__m64 to_m64(__m128i a) pure @trusted
{
    long2 la = cast(long2)a;
    long1 r = la.array[0];
    return r;
}

__m128i to_m128i(__m64 a) pure @trusted
{
    {
        long2 r = [0, 0];
        r.ptr[0] = a.array[0];
        return cast(__m128i)r;
    }
}

enum LDC_with_x86_asm = false;

static if (LDC_with_WASM)
{
    // Note: this fake control word follow the x86 format.
    // This is a #TLS variable!
    // Only the 2 rounding mode bits will be used.
    // This defaults to: _MM_ROUND_NEAREST.
    static uint _mm_WASM_CW = 0x9fff;

    package uint wasm_get_fpcr() nothrow @nogc @trusted
    {
        return _mm_WASM_CW;
    }

    package void wasm_set_fpcr(uint cw) nothrow @nogc @trusted
    {
        _mm_WASM_CW = cw;
    }
}

package
{
    enum int _MM_ROUND_NEAREST     = 0x0000;
    enum int _MM_ROUND_DOWN        = 0x2000;
    enum int _MM_ROUND_UP          = 0x4000;
    enum int _MM_ROUND_TOWARD_ZERO = 0x6000;
    enum int _MM_ROUND_MASK        = 0x6000;
}
