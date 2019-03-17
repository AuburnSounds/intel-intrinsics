/**
* Copyright: Copyright Auburn Sounds 2016-2018.
* License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
* Authors:   Guillaume Piolat
*/
module inteli.internals;

import inteli.types;

// The only math functions needed for intel-intrinsics
public import core.math: fabs, sqrt; // since they are intrinsics

version(LDC)
{
    public import core.simd;
    public import ldc.simd;
    public import ldc.gccbuiltins_x86;
    public import ldc.intrinsics;
    public import ldc.llvmasm: __asm;

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



package:
nothrow @nogc:


//
//  <ROUNDING>
//
//  Why is that there? For DMD, we cannot use rint because _MM_SET_ROUNDING_MODE
//  doesn't change the FPU rounding mode, and isn't expected to do so.
//  So we devised these rounding function to help having consistent rouding between 
//  LDC and DMD. It's important that DMD uses what is in MXCST to round.
//


int convertFloatToInt32UsingMXCSR(float value) pure @safe
{
    int result;
    asm pure nothrow @nogc @trusted
    {
        cvtss2si EAX, value;
        mov result, EAX;
    }
    return result;
}

int convertDoubleToInt32UsingMXCSR(double value) pure @safe
{
    int result;
    asm pure nothrow @nogc @trusted
    {
        cvtsd2si EAX, value;
        mov result, EAX;
    }
    return result;
}

long convertFloatToInt64UsingMXCSR(float value) pure @safe
{
    // 64-bit can use an SSE instruction
    version(D_InlineAsm_X86_64)
    {
        long result;
        version(LDC) // work-around for " Data definition directives inside inline asm are not supported yet."
        {
            asm pure nothrow @nogc @trusted
            {
                movss XMM0, value;
                cvtss2si RAX, XMM0;
                mov result, RAX;
            }
        }
        else
        {
            asm pure nothrow @nogc @trusted
            {
                movss XMM0, value;
                db 0xf3; db 0x48; db 0x0f; db 0x2d; db 0xc0; // cvtss2si RAX, XMM0 (DMD refuses to emit)
                mov result, RAX;
            }
        }
        return result;
    }
    else version(D_InlineAsm_X86)
    {
        // In the case of 32-bit x86 there is no SSE2 way to convert FP to 64-bit int
        // This leads to an unfortunate FPU sequence in every C++ compiler.
        // See: https://godbolt.org/z/vZym77

        // Get current MXCSR rounding
        uint sseRounding;
        ushort savedFPUCW;
        ushort newFPUCW;
        long result;
        asm pure nothrow @nogc @trusted
        {
            stmxcsr sseRounding;
            fld value;
            fnstcw savedFPUCW;
            mov AX, savedFPUCW;
            and AX, 0xf3ff;          // clear FPU rounding bits
            movzx ECX, word ptr sseRounding;
            and ECX, 0x6000;         // only keep SSE rounding bits
            shr ECX, 3;
            or AX, CX;               // make a new control word for FPU with SSE bits
            mov newFPUCW, AX;
            fldcw newFPUCW;
            fistp qword ptr result;            // convert, respecting MXCSR (but not other control word things)
            fldcw savedFPUCW;
        }
        return result;
    }
    else
        static assert(false);
}

///ditto
long convertDoubleToInt64UsingMXCSR(double value) pure @safe
{
    // 64-bit can use an SSE instruction
    version(D_InlineAsm_X86_64)
    {
        long result;
        version(LDC) // work-around for "Data definition directives inside inline asm are not supported yet."
        {
            asm pure nothrow @nogc @trusted
            {
                movsd XMM0, value;
                cvtsd2si RAX, XMM0;
                mov result, RAX;
            }
        }
        else
        {
            asm pure nothrow @nogc @trusted
            {
                movsd XMM0, value;
                db 0xf2; db 0x48; db 0x0f; db 0x2d; db 0xc0; // cvtsd2si RAX, XMM0 (DMD refuses to emit)
                mov result, RAX;
            }
        }
        return result;
    }
    else version(D_InlineAsm_X86)
    {
        // In the case of 32-bit x86 there is no SSE2 way to convert FP to 64-bit int
        // This leads to an unfortunate FPU sequence in every C++ compiler.
        // See: https://godbolt.org/z/vZym77

        // Get current MXCSR rounding
        uint sseRounding;
        ushort savedFPUCW;
        ushort newFPUCW;
        long result;
        asm pure nothrow @nogc @trusted
        {
            stmxcsr sseRounding;
            fld value;
            fnstcw savedFPUCW;
            mov AX, savedFPUCW;
            and AX, 0xf3ff;
            movzx ECX, word ptr sseRounding;
            and ECX, 0x6000;
            shr ECX, 3;
            or AX, CX;
            mov newFPUCW, AX;
            fldcw newFPUCW;
            fistp result;
            fldcw savedFPUCW;
        }
        return result;
    }
    else
        static assert(false);
}


//
//  </ROUNDING>
//


// using the Intel terminology here

byte saturateSignedWordToSignedByte(short value) pure @safe
{
    if (value > 127) value = 127;
    if (value < -128) value = -128;
    return cast(byte) value;
}

ubyte saturateSignedWordToUnsignedByte(short value) pure @safe
{
    if (value > 255) value = 255;
    if (value < 0) value = 0;
    return cast(ubyte) value;
}

short saturateSignedIntToSignedShort(int value) pure @safe
{
    if (value > 32767) value = 32767;
    if (value < -32768) value = -32768;
    return cast(short) value;
}

ushort saturateSignedIntToUnsignedShort(int value) pure @safe
{
    if (value > 65535) value = 65535;
    if (value < 0) value = 0;
    return cast(ushort) value;
}

unittest // test saturate operations
{
    assert( saturateSignedWordToSignedByte(32000) == 127);
    assert( saturateSignedWordToUnsignedByte(32000) == 255);
    assert( saturateSignedWordToSignedByte(-4000) == -128);
    assert( saturateSignedWordToUnsignedByte(-4000) == 0);
    assert( saturateSignedIntToSignedShort(32768) == 32767);
    assert( saturateSignedIntToUnsignedShort(32768) == 32768);
    assert( saturateSignedIntToSignedShort(-32769) == -32768);
    assert( saturateSignedIntToUnsignedShort(-32769) == 0);
}

version(unittest)
{
    // This is just for debugging tests
    import core.stdc.stdio: printf;

    // printing vectors for implementation
    // Note: you can override `pure` within a `debug` clause

    void _mm_print_pi32(__m64 v) @trusted
    {
        int2 C = cast(int2)v;
        printf("%d %d\n", C[0], C[1]);
    }

    void _mm_print_pi16(__m64 v) @trusted
    {
        short4 C = cast(short4)v;
        printf("%d %d %d %d\n", C[0], C[1], C[2], C[3]);
    }

    void _mm_print_pi8(__m64 v) @trusted
    {
        byte8 C = cast(byte8)v;
        printf("%d %d %d %d %d %d %d %d\n",
        C[0], C[1], C[2], C[3], C[4], C[5], C[6], C[7]);
    }

    void _mm_print_epi32(__m128i v) @trusted
    {
        printf("%d %d %d %d\n",
              v[0], v[1], v[2], v[3]);
    }

    void _mm_print_epi16(__m128i v) @trusted
    {
        short8 C = cast(short8)v;
        printf("%d %d %d %d %d %d %d %d\n",
        C[0], C[1], C[2], C[3], C[4], C[5], C[6], C[7]);
    }

    void _mm_print_epi8(__m128i v) @trusted
    {
        byte16 C = cast(byte16)v;
        printf("%d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d\n",
        C[0], C[1], C[2], C[3], C[4], C[5], C[6], C[7], C[8], C[9], C[10], C[11], C[12], C[13], C[14], C[15]);
    }

    void _mm_print_ps(__m128 v) @trusted
    {
        float4 C = cast(float4)v;
        printf("%f %f %f %f\n", C[0], C[1], C[2], C[3]);
    }

    void _mm_print_pd(__m128d v) @trusted
    {
        double2 C = cast(double2)v;
        printf("%f %f\n", C[0], C[1]);
    }    
}


//
//  <FLOATING-POINT COMPARISONS>
//
// Note: `ldc.simd` cannot express all nuances of FP comparisons, so we
//       need different IR generation.

enum FPComparison
{
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
}

private static immutable string[FPComparison.max+1] FPComparisonToString =
[
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
];

// Individual float comparison: returns -1 for true or 0 for false.
// Useful for DMD and testing
private bool compareFloat(T)(FPComparison comparison, T a, T b) pure @safe
{
    import std.math;
    bool unordered = isNaN(a) || isNaN(b);
    final switch(comparison) with(FPComparison)
    {
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
    }
}

version(LDC)
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

    /// Provides packed double comparisons
    package long2 cmppd(FPComparison comparison)(double2 a, double2 b) pure @safe
    {
        enum ir = `
            %cmp = fcmp `~ FPComparisonToString[comparison] ~` <2 x double> %0, %1
            %r = sext <2 x i1> %cmp to <2 x i64>
            ret <2 x i64> %r`;

        return LDCInlineIR!(ir, long2, double2, double2)(a, b);
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

    // Note: ucomss and ucomsd are left unimplemented
    package int comss(FPComparison comparison)(float4 a, float4 b) pure @safe
    {
        enum ir = `
            %cmp = fcmp `~ FPComparisonToString[comparison] ~` float %0, %1
            %r = zext i1 %cmp to i32
            ret i32 %r`;

        return LDCInlineIR!(ir, int, float, float)(a[0], b[0]);
    }

    // Note: ucomss and ucomsd are left unimplemented
    package int comsd(FPComparison comparison)(double2 a, double2 b) pure @safe
    {
        enum ir = `
            %cmp = fcmp `~ FPComparisonToString[comparison] ~` double %0, %1
            %r = zext i1 %cmp to i32
            ret i32 %r`;

        return LDCInlineIR!(ir, int, double, double)(a[0], b[0]);
    }
}
else
{
    /// Provides packed float comparisons
    package int4 cmpps(FPComparison comparison)(float4 a, float4 b) pure @safe
    {
        int4 result;
        foreach(i; 0..4)
        {
            result[i] = compareFloat!float(comparison, a[i], b[i]) ? -1 : 0;
        }
        return result;
    }

    /// Provides packed double comparisons
    package long2 cmppd(FPComparison comparison)(double2 a, double2 b) pure @safe
    {
        long2 result;
        foreach(i; 0..2)
        {
            result[i] = compareFloat!double(comparison, a[i], b[i]) ? -1 : 0;
        }
        return result;
    }

    /// Provides CMPSS-style comparison
    package float4 cmpss(FPComparison comparison)(float4 a, float4 b) pure @safe
    {
        int4 result = cast(int4)a;
        result[0] = compareFloat!float(comparison, a[0], b[0]) ? -1 : 0;
        return cast(float4)result;
    }

    /// Provides CMPSD-style comparison
    package double2 cmpsd(FPComparison comparison)(double2 a, double2 b) pure @safe
    {
        long2 result = cast(long2)a;
        result[0] = compareFloat!double(comparison, a[0], b[0]) ? -1 : 0;
        return cast(double2)result;
    }

    package int comss(FPComparison comparison)(float4 a, float4 b) pure @safe
    {
        return compareFloat!float(comparison, a[0], b[0]) ? 1 : 0;
    }

    // Note: ucomss and ucomsd are left unimplemented
    package int comsd(FPComparison comparison)(double2 a, double2 b) pure @safe
    {
        return compareFloat!double(comparison, a[0], b[0]) ? 1 : 0;
    }
}
unittest // cmpps
{
    // Check all comparison type is working
    float4 A = [1, 3, 5, float.nan];
    float4 B = [2, 3, 4, 5];

    int4 result_oeq = cmpps!(FPComparison.oeq)(A, B);
    int4 result_ogt = cmpps!(FPComparison.ogt)(A, B);
    int4 result_oge = cmpps!(FPComparison.oge)(A, B);
    int4 result_olt = cmpps!(FPComparison.olt)(A, B);
    int4 result_ole = cmpps!(FPComparison.ole)(A, B);
    int4 result_one = cmpps!(FPComparison.one)(A, B);
    int4 result_ord = cmpps!(FPComparison.ord)(A, B);
    int4 result_ueq = cmpps!(FPComparison.ueq)(A, B);
    int4 result_ugt = cmpps!(FPComparison.ugt)(A, B);
    int4 result_uge = cmpps!(FPComparison.uge)(A, B);
    int4 result_ult = cmpps!(FPComparison.ult)(A, B);
    int4 result_ule = cmpps!(FPComparison.ule)(A, B);
    int4 result_une = cmpps!(FPComparison.une)(A, B);
    int4 result_uno = cmpps!(FPComparison.uno)(A, B);

    static immutable int[4] correct_oeq    = [ 0,-1, 0, 0];
    static immutable int[4] correct_ogt    = [ 0, 0,-1, 0];
    static immutable int[4] correct_oge    = [ 0,-1,-1, 0];
    static immutable int[4] correct_olt    = [-1, 0, 0, 0];
    static immutable int[4] correct_ole    = [-1,-1, 0, 0];
    static immutable int[4] correct_one    = [-1, 0,-1, 0];
    static immutable int[4] correct_ord    = [-1,-1,-1, 0];
    static immutable int[4] correct_ueq    = [ 0,-1, 0,-1];
    static immutable int[4] correct_ugt    = [ 0, 0,-1,-1];
    static immutable int[4] correct_uge    = [ 0,-1,-1,-1];
    static immutable int[4] correct_ult    = [-1, 0, 0,-1];
    static immutable int[4] correct_ule    = [-1,-1, 0,-1];
    static immutable int[4] correct_une    = [-1, 0,-1,-1];
    static immutable int[4] correct_uno    = [ 0, 0, 0,-1];

    assert(result_oeq.array == correct_oeq);
    assert(result_ogt.array == correct_ogt);
    assert(result_oge.array == correct_oge);
    assert(result_olt.array == correct_olt);
    assert(result_ole.array == correct_ole);
    assert(result_one.array == correct_one);
    assert(result_ord.array == correct_ord);
    assert(result_ueq.array == correct_ueq);
    assert(result_ugt.array == correct_ugt);
    assert(result_uge.array == correct_uge);
    assert(result_ult.array == correct_ult);
    assert(result_ule.array == correct_ule);
    assert(result_une.array == correct_une);
    assert(result_uno.array == correct_uno);
}
unittest
{
    double2 a = [1, 3];
    double2 b = [2, 3];
    long2 c = cmppd!(FPComparison.ult)(a, b);
    static immutable long[2] correct = [cast(long)(-1), 0];
    assert(c.array == correct);
}
unittest // cmpss and comss
{
    void testComparison(FPComparison comparison)(float4 A, float4 B)
    {
        float4 result = cmpss!comparison(A, B);
        int4 iresult = cast(int4)result;
        int expected = compareFloat!float(comparison, A[0], B[0]) ? -1 : 0;
        assert(iresult[0] == expected);
        assert(result[1] == A[1]);
        assert(result[2] == A[2]);
        assert(result[3] == A[3]);

        // check comss
        int comResult = comss!comparison(A, B);
        assert( (expected != 0) == (comResult != 0) );
    }

    // Check all comparison type is working
    float4 A = [1, 3, 5, 6];
    float4 B = [2, 3, 4, 5];
    float4 C = [float.nan, 3, 4, 5];

    testComparison!(FPComparison.oeq)(A, B);
    testComparison!(FPComparison.oeq)(A, C);
    testComparison!(FPComparison.ogt)(A, B);
    testComparison!(FPComparison.ogt)(A, C);
    testComparison!(FPComparison.oge)(A, B);
    testComparison!(FPComparison.oge)(A, C);
    testComparison!(FPComparison.olt)(A, B);
    testComparison!(FPComparison.olt)(A, C);
    testComparison!(FPComparison.ole)(A, B);
    testComparison!(FPComparison.ole)(A, C);
    testComparison!(FPComparison.one)(A, B);
    testComparison!(FPComparison.one)(A, C);
    testComparison!(FPComparison.ord)(A, B);
    testComparison!(FPComparison.ord)(A, C);
    testComparison!(FPComparison.ueq)(A, B);
    testComparison!(FPComparison.ueq)(A, C);
    testComparison!(FPComparison.ugt)(A, B);
    testComparison!(FPComparison.ugt)(A, C);
    testComparison!(FPComparison.uge)(A, B);
    testComparison!(FPComparison.uge)(A, C);
    testComparison!(FPComparison.ult)(A, B);
    testComparison!(FPComparison.ult)(A, C);
    testComparison!(FPComparison.ule)(A, B);
    testComparison!(FPComparison.ule)(A, C);
    testComparison!(FPComparison.une)(A, B);
    testComparison!(FPComparison.une)(A, C);
    testComparison!(FPComparison.uno)(A, B);
    testComparison!(FPComparison.uno)(A, C);
}
unittest // cmpsd and comsd
{
    void testComparison(FPComparison comparison)(double2 A, double2 B)
    {
        double2 result = cmpsd!comparison(A, B);
        long2 iresult = cast(long2)result;
        long expected = compareFloat!double(comparison, A[0], B[0]) ? -1 : 0;
        assert(iresult[0] == expected);
        assert(result[1] == A[1]);

        // check comsd
        int comResult = comsd!comparison(A, B);
        assert( (expected != 0) == (comResult != 0) );
    }

    // Check all comparison type is working
    double2 A = [1, 3];
    double2 B = [2, 4];
    double2 C = [double.nan, 5];

    testComparison!(FPComparison.oeq)(A, B);
    testComparison!(FPComparison.oeq)(A, C);
    testComparison!(FPComparison.ogt)(A, B);
    testComparison!(FPComparison.ogt)(A, C);
    testComparison!(FPComparison.oge)(A, B);
    testComparison!(FPComparison.oge)(A, C);
    testComparison!(FPComparison.olt)(A, B);
    testComparison!(FPComparison.olt)(A, C);
    testComparison!(FPComparison.ole)(A, B);
    testComparison!(FPComparison.ole)(A, C);
    testComparison!(FPComparison.one)(A, B);
    testComparison!(FPComparison.one)(A, C);
    testComparison!(FPComparison.ord)(A, B);
    testComparison!(FPComparison.ord)(A, C);
    testComparison!(FPComparison.ueq)(A, B);
    testComparison!(FPComparison.ueq)(A, C);
    testComparison!(FPComparison.ugt)(A, B);
    testComparison!(FPComparison.ugt)(A, C);
    testComparison!(FPComparison.uge)(A, B);
    testComparison!(FPComparison.uge)(A, C);
    testComparison!(FPComparison.ult)(A, B);
    testComparison!(FPComparison.ult)(A, C);
    testComparison!(FPComparison.ule)(A, B);
    testComparison!(FPComparison.ule)(A, C);
    testComparison!(FPComparison.une)(A, B);
    testComparison!(FPComparison.une)(A, C);
    testComparison!(FPComparison.uno)(A, B);
    testComparison!(FPComparison.uno)(A, C);
}

//
//  </FLOATING-POINT COMPARISONS>
//


__m64 to_m64(__m128i a) pure @safe
{
    long2 la = cast(long2)a;
    long1 r;
    r[0] = la[0];
    return r;
}

__m128i to_m128i(__m64 a) pure @safe
{
    long2 r = [0, 0];
    r[0] = a[0];
    return cast(__m128i)r;
}