/**
* Internal stuff only, do not import.
*
* Copyright: Copyright Auburn Sounds 2016-2018, Stefanos Baziotis 2019.
* License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
* Authors:   Guillaume Piolat
*/
module inteli.internals;

import inteli.types;

// The only math functions needed for intel-intrinsics
public import core.math: sqrt; // since it's an intrinsics
public import std.math: abs; // `fabs` is broken with GCC 4.9.2 on Linux 64-bit


version(GNU)
{
    version (X86)
    {
        // For 32-bit x86, disable vector extensions with GDC. 
        // It just doesn't work well.
        enum GDC_with_x86 = true;
        enum GDC_with_MMX = false;
        enum GDC_with_SSE = false;
        enum GDC_with_SSE2 = false;
        enum GDC_with_SSE3 = false;
        enum LDC_with_ARM32 = false;
        enum LDC_with_ARM64 = false;
        enum LDC_with_SSE1 = false;
        enum LDC_with_SSE2 = false;
        enum LDC_with_SSE3 = false;
    }
    else version (X86_64)
    {
        // GDC support uses extended inline assembly:
        //   https://gcc.gnu.org/onlinedocs/gcc/Extended-Asm.html        (general information and hints)
        //   https://gcc.gnu.org/onlinedocs/gcc/Simple-Constraints.html  (binding variables to registers)
        //   https://gcc.gnu.org/onlinedocs/gcc/Machine-Constraints.html (x86 specific register short names)

        public import core.simd;

        // NOTE: These intrinsics are not available in every i386 and x86_64 CPU.
        // For more info: https://gcc.gnu.org/onlinedocs/gcc-4.9.2/gcc/X86-Built-in-Functions.html 
        public import gcc.builtins;
                
        enum GDC_with_x86 = true;
        enum GDC_with_MMX = true; // We don't have a way to detect that at CT, but we assume it's there
        enum GDC_with_SSE = true; // We don't have a way to detect that at CT, but we assume it's there
        enum GDC_with_SSE2 = true; // We don't have a way to detect that at CT, but we assume it's there
        enum GDC_with_SSE3 = false; // TODO: we don't have a way to detect that at CT
        enum LDC_with_ARM32 = false;
        enum LDC_with_ARM64 = false;
        enum LDC_with_SSE1 = false;
        enum LDC_with_SSE2 = false;
        enum LDC_with_SSE3 = false;
    }
    else
    {
        enum GDC_with_x86 = false;
        enum GDC_with_MMX = false;
        enum GDC_with_SSE = false;
        enum GDC_with_SSE2 = false;
        enum GDC_with_SSE3 = false;
        enum LDC_with_ARM32 = false;
        enum LDC_with_ARM64 = false;
        enum LDC_with_SSE1 = false;
        enum LDC_with_SSE2 = false;
        enum LDC_with_SSE3 = false;
    }
}
else version(LDC)
{
    public import core.simd;
    public import ldc.simd;
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
    
    package(inteli)
    {
        enum GDC_with_x86 = false;
        enum GDC_with_MMX = false;
        enum GDC_with_SSE = false;
        enum GDC_with_SSE2 = false;
        enum GDC_with_SSE3 = false;
    }

    version(ARM)
    {
        public import ldc.gccbuiltins_arm;
        enum LDC_with_ARM32 = true;
        enum LDC_with_ARM64 = false;
        enum LDC_with_SSE1 = false;
        enum LDC_with_SSE2 = false;
        enum LDC_with_SSE3 = false;
    }
    else version(AArch64)
    {
        //public import ldc.gccbuiltins_arm;
        enum LDC_with_ARM32 = false;
        enum LDC_with_ARM64 = true;
        enum LDC_with_SSE1 = false;
        enum LDC_with_SSE2 = false;
        enum LDC_with_SSE3 = false;
    }
    else
    {
        public import ldc.gccbuiltins_x86;
        enum LDC_with_ARM32 = false;
        enum LDC_with_ARM64 = false;
        enum LDC_with_SSE1 = __traits(targetHasFeature, "sse");
        enum LDC_with_SSE2 = __traits(targetHasFeature, "sse2");
        enum LDC_with_SSE3 = __traits(targetHasFeature, "sse3");
    }
}
else version(DigitalMars)
{
    package(inteli)
    {
        enum GDC_with_x86 = false;
        enum GDC_with_MMX = false;
        enum GDC_with_SSE = false;
        enum GDC_with_SSE2 = false;
        enum GDC_with_SSE3 = false;
        enum LDC_with_ARM32 = false;
        enum LDC_with_ARM64 = false;
        enum LDC_with_SSE1 = false;
        enum LDC_with_SSE2 = false;
        enum LDC_with_SSE3 = false;
    }
}
else
{
    static assert(false, "Unknown compiler");
}

enum LDC_with_ARM = LDC_with_ARM32 | LDC_with_ARM64; // ARM32 is largely unsupported though

static if (LDC_with_ARM32)
{
    package uint arm_get_fpcr() nothrow @nogc @trusted
    {
        return __builtin_arm_get_fpscr();
    }

    package void arm_set_fpcr(uint cw) nothrow @nogc @trusted
    {
        __builtin_arm_set_fpscr(cw);
    }
}

static if (LDC_with_ARM64)
{
    pragma(LDC_intrinsic, "llvm.aarch64.get.fpcr")
        long __builtin_aarch64_get_fpcr() pure nothrow @nogc @safe;

    package uint arm_get_fpcr() pure nothrow @nogc @trusted
    {
        return cast(uint) __builtin_aarch64_get_fpcr();
    }

    package void arm_set_fpcr(uint cw) nothrow @nogc @trusted
    {
        // Note: there doesn't seem to be an intrinsic in LLVM to set FPCR.
        long save_x2;
        __asm!void("str x2, $1 \n" ~
                   "ldr w2, $0 \n" ~
                   "msr fpcr, x2 \n" ~
                   "ldr x2, $1 "    , "m,m", cw, save_x2);
    }
}

version(DigitalMars)
{
    version(D_InlineAsm_X86)
        enum DMD_with_asm = true;
    else version(D_InlineAsm_X86_64)
        enum DMD_with_asm = true;
    else
        enum DMD_with_asm = false;

    version(D_InlineAsm_X86)
        enum DMD_with_32bit_asm = DMD_with_asm; // sometimes you want a 32-bit DMD only solution
    else
        enum DMD_with_32bit_asm = false;
}
else
{
    enum DMD_with_asm = false;
    enum DMD_with_32bit_asm = false;
}


package:
nothrow @nogc:


// For internal use only, since public API deals with a x86 semantic emulation
enum uint _MM_ROUND_NEAREST_ARM     = 0x00000000;
enum uint _MM_ROUND_DOWN_ARM        = 0x00800000;
enum uint _MM_ROUND_UP_ARM          = 0x00400000;
enum uint _MM_ROUND_TOWARD_ZERO_ARM = 0x00C00000;
enum uint _MM_ROUND_MASK_ARM        = 0x00C00000;
enum uint _MM_FLUSH_ZERO_MASK_ARM = 0x01000000;


//
//  <ROUNDING>
//
//  Why is that there? For DMD, we cannot use rint because _MM_SET_ROUNDING_MODE
//  doesn't change the FPU rounding mode, and isn't expected to do so.
//  So we devised these rounding function to help having consistent rouding between 
//  LDC and DMD. It's important that DMD uses what is in MXCST to round.
//
//  Note: There is no MXCSR in ARM. But there is fpscr that implements similar 
//  functionality the same.
//  https://developer.arm.com/documentation/dui0068/b/vector-floating-point-programming/vfp-system-registers/fpscr--the-floating-point-status-and-control-register
//  There is no
//  We use fpscr since it's thread-local, so we can emulate those x86 conversion albeit slowly.

int convertFloatToInt32UsingMXCSR(float value) @trusted
{
    int result;
    version(GNU)
    {
        asm pure nothrow @nogc @trusted
        {
            "cvtss2si %1, %0\n": "=r"(result) : "x" (value);
        }
    }
    else static if (LDC_with_ARM32)
    {
        result = __asm!int(`vldr s2, $1
                            vcvtr.s32.f32 s2, s2
                            vmov $0, s2`, "=r,m", value);
    }
    else static if (LDC_with_ARM64)
    {
        // Get current rounding mode.
        uint fpscr = arm_get_fpcr();

        switch(fpscr & _MM_ROUND_MASK_ARM)
        {
            default:
            case _MM_ROUND_NEAREST_ARM:
                result = __asm!int(`ldr s2, $1
                                    fcvtns $0,s2`, "=r,m", value);
                break;
            case _MM_ROUND_DOWN_ARM:
                result = __asm!int(`ldr s2, $1
                                    fcvtms $0,s2`, "=r,m", value);
                break;
            case _MM_ROUND_UP_ARM:
                result = __asm!int(`ldr s2, $1
                                    fcvtps $0,s2`, "=r,m", value);
                break;
            case _MM_ROUND_TOWARD_ZERO_ARM:
                result = cast(int)value;
                break;
        }
    }
    else
    {        
        asm pure nothrow @nogc @trusted
        {
            cvtss2si EAX, value;
            mov result, EAX;
        }
    }
    return result;
}

int convertDoubleToInt32UsingMXCSR(double value) @trusted
{
    int result;
    version(GNU)
    {
        asm pure nothrow @nogc @trusted
        {
            "cvtsd2si %1, %0\n": "=r"(result) : "x" (value);
        }
    }
    else static if (LDC_with_ARM32)
    {
        result = __asm!int(`vldr d2, $1
                            vcvtr.s32.f64 s2, d2
                            vmov $0, s2`, "=r,m", value);
    }
    else static if (LDC_with_ARM64)
    {
        // Get current rounding mode.
        uint fpscr = arm_get_fpcr();

        switch(fpscr & _MM_ROUND_MASK_ARM)
        {
            default:
            case _MM_ROUND_NEAREST_ARM:
                result = __asm!int(`ldr d2, $1
                                    fcvtns $0,d2`, "=r,m", value);
                break;
            case _MM_ROUND_DOWN_ARM:
                result = __asm!int(`ldr d2, $1
                                    fcvtms $0,d2`, "=r,m", value);
                break;
            case _MM_ROUND_UP_ARM:
                result = __asm!int(`ldr d2, $1
                                    fcvtps $0,d2`, "=r,m", value);
                break;
            case _MM_ROUND_TOWARD_ZERO_ARM:
                result = cast(int)value;
                break;
        }
    }
    else
    {
        asm pure nothrow @nogc @trusted
        {
            cvtsd2si EAX, value;
            mov result, EAX;
        }
    }
    return result;
}

long convertFloatToInt64UsingMXCSR(float value) @trusted
{
    static if (LDC_with_ARM32)
    {
        // We have to resort to libc since 32-bit ARM 
        // doesn't seem to have 64-bit registers.
        
        uint fpscr = arm_get_fpcr(); // Get current rounding mode.

        // Note: converting to double precision else rounding could be different for large integers
        double asDouble = value; 

        switch(fpscr & _MM_ROUND_MASK_ARM)
        {
            default:
            case _MM_ROUND_NEAREST_ARM:     return cast(long)(llvm_round(asDouble));
            case _MM_ROUND_DOWN_ARM:        return cast(long)(llvm_floor(asDouble));
            case _MM_ROUND_UP_ARM:          return cast(long)(llvm_ceil(asDouble));
            case _MM_ROUND_TOWARD_ZERO_ARM: return cast(long)(asDouble);
        }
    }
    else static if (LDC_with_ARM64)
    {
        uint fpscr = arm_get_fpcr();

        switch(fpscr & _MM_ROUND_MASK_ARM)
        {
            default:
            case _MM_ROUND_NEAREST_ARM:
                return __asm!long(`ldr s2, $1
                                   fcvtns $0,s2`, "=r,m", value);
            case _MM_ROUND_DOWN_ARM:
                return __asm!long(`ldr s2, $1
                                   fcvtms $0,s2`, "=r,m", value);
            case _MM_ROUND_UP_ARM:
                return __asm!long(`ldr s2, $1
                                   fcvtps $0,s2`, "=r,m", value);
            case _MM_ROUND_TOWARD_ZERO_ARM:
                return cast(long)value;
        }
    }
    // 64-bit can use an SSE instruction
    else version(D_InlineAsm_X86_64)
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
    else static if (GDC_with_x86)
    {
        version(X86_64) // 64-bit can just use the right instruction
        {
            static assert(GDC_with_SSE);
            __m128 A;
            A.ptr[0] = value;
            return __builtin_ia32_cvtss2si64 (A);
        }
        else version(X86) // 32-bit
        {
            // This is untested!
            uint sseRounding;
            ushort savedFPUCW;
            ushort newFPUCW;
            long result;
            asm pure nothrow @nogc @trusted
            {
                "stmxcsr %1;\n" ~
                "fld %2;\n" ~
                "fnstcw %3;\n" ~
                "movw %3, %%ax;\n" ~
                "andw $0xf3ff, %%ax;\n" ~
                "movzwl %1, %%ecx;\n" ~
                "andl $0x6000, %%ecx;\n" ~
                "shrl $3, %%ecx;\n" ~
                "orw %%cx, %%ax\n" ~
                "movw %%ax, %4;\n" ~
                "fldcw %4;\n" ~
                "fistpll %0;\n" ~
                "fldcw %3;\n" 
                  : "=m"(result)    // %0
                  : "m" (sseRounding),
                    "f" (value),
                    "m" (savedFPUCW),
                    "m" (newFPUCW) 
                  : "eax", "ecx", "st";
            }
            return result;
        }
        else
            static assert(false);
    }
    else
        static assert(false);
}


///ditto
long convertDoubleToInt64UsingMXCSR(double value) @trusted
{
    static if (LDC_with_ARM32)
    {
        // We have to resort to libc since 32-bit ARM 
        // doesn't seem to have 64-bit registers.
        uint fpscr = arm_get_fpcr(); // Get current rounding mode.
        switch(fpscr & _MM_ROUND_MASK_ARM)
        {
            default:
            case _MM_ROUND_NEAREST_ARM:     return cast(long)(llvm_round(value));
            case _MM_ROUND_DOWN_ARM:        return cast(long)(llvm_floor(value));
            case _MM_ROUND_UP_ARM:          return cast(long)(llvm_ceil(value));
            case _MM_ROUND_TOWARD_ZERO_ARM: return cast(long)(value);
        }
    }
    else static if (LDC_with_ARM64)
    {
        // Get current rounding mode.
        uint fpscr = arm_get_fpcr();

        switch(fpscr & _MM_ROUND_MASK_ARM)
        {
            default:
            case _MM_ROUND_NEAREST_ARM:
                return __asm!long(`ldr d2, $1
                                   fcvtns $0,d2`, "=r,m", value);
            case _MM_ROUND_DOWN_ARM:
                return __asm!long(`ldr d2, $1
                                   fcvtms $0,d2`, "=r,m", value);
            case _MM_ROUND_UP_ARM:
                return __asm!long(`ldr d2, $1
                                   fcvtps $0,d2`, "=r,m", value);
            case _MM_ROUND_TOWARD_ZERO_ARM:
                return cast(long)value;
        }
    }
    // 64-bit can use an SSE instruction
    else version(D_InlineAsm_X86_64)
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
    else static if (GDC_with_x86)
    {
        version(X86_64)
        {
            static assert(GDC_with_SSE2);
            __m128d A;
            A.ptr[0] = value;
            return __builtin_ia32_cvtsd2si64 (A);
        }
        else
        {
            // This is untested!
            uint sseRounding;
            ushort savedFPUCW;
            ushort newFPUCW;
            long result;
            asm pure nothrow @nogc @trusted
            {
                "stmxcsr %1;\n" ~
                "fld %2;\n" ~
                "fnstcw %3;\n" ~
                "movw %3, %%ax;\n" ~
                "andw $0xf3ff, %%ax;\n" ~
                "movzwl %1, %%ecx;\n" ~
                "andl $0x6000, %%ecx;\n" ~
                "shrl $3, %%ecx;\n" ~
                "orw %%cx, %%ax\n" ~
                "movw %%ax, %4;\n" ~
                "fldcw %4;\n" ~
                "fistpll %0;\n" ~
                "fldcw %3;\n"         
                  : "=m"(result)    // %0
                  : "m" (sseRounding),
                    "t" (value),
                    "m" (savedFPUCW),
                    "m" (newFPUCW) 
                  : "eax", "ecx", "st";
            }
            return result;
        }
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

    void _mm_print_pi64(__m64 v) @trusted
    {
        long1 vl = cast(long1)v;
        printf("%lld\n", vl.array[0]);
    }

    void _mm_print_pi32(__m64 v) @trusted
    {
        int[2] C = (cast(int2)v).array;
        printf("%d %d\n", C[0], C[1]);
    }

    void _mm_print_pi16(__m64 v) @trusted
    {
        short[4] C = (cast(short4)v).array;
        printf("%d %d %d %d\n", C[0], C[1], C[2], C[3]);
    }

    void _mm_print_pi8(__m64 v) @trusted
    {
        byte[8] C = (cast(byte8)v).array;
        printf("%d %d %d %d %d %d %d %d\n",
        C[0], C[1], C[2], C[3], C[4], C[5], C[6], C[7]);
    }

    void _mm_print_epi64(__m128i v) @trusted
    {
        long2 vl = cast(long2)v;
        printf("%lld %lld\n", vl.array[0], vl.array[1]);
    }

    void _mm_print_epi32(__m128i v) @trusted
    {
        printf("%d %d %d %d\n",
              v.array[0], v.array[1], v.array[2], v.array[3]);
    }  

    void _mm_print_epi16(__m128i v) @trusted
    {
        short[8] C = (cast(short8)v).array;
        printf("%d %d %d %d %d %d %d %d\n",
        C[0], C[1], C[2], C[3], C[4], C[5], C[6], C[7]);
    }

    void _mm_print_epi8(__m128i v) @trusted
    {
        byte[16] C = (cast(byte16)v).array;
        printf("%d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d\n",
        C[0], C[1], C[2], C[3], C[4], C[5], C[6], C[7], C[8], C[9], C[10], C[11], C[12], C[13], C[14], C[15]);
    }

    void _mm_print_ps(__m128 v) @trusted
    {
        float[4] C = (cast(float4)v).array;
        printf("%f %f %f %f\n", C[0], C[1], C[2], C[3]);
    }

    void _mm_print_pd(__m128d v) @trusted
    {
        double[2] C = (cast(double2)v).array;
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
    package int4 cmpps(FPComparison comparison)(float4 a, float4 b) pure @trusted
    {
        int4 result;
        foreach(i; 0..4)
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

    package int comss(FPComparison comparison)(float4 a, float4 b) pure @safe
    {
        return compareFloat!float(comparison, a.array[0], b.array[0]) ? 1 : 0;
    }

    // Note: ucomss and ucomsd are left unimplemented
    package int comsd(FPComparison comparison)(double2 a, double2 b) pure @safe
    {
        return compareFloat!double(comparison, a.array[0], b.array[0]) ? 1 : 0;
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
        int expected = compareFloat!float(comparison, A.array[0], B.array[0]) ? -1 : 0;
        assert(iresult.array[0] == expected);
        assert(result.array[1] == A.array[1]);
        assert(result.array[2] == A.array[2]);
        assert(result.array[3] == A.array[3]);

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
        long expected = compareFloat!double(comparison, A.array[0], B.array[0]) ? -1 : 0;
        assert(iresult.array[0] == expected);
        assert(result.array[1] == A.array[1]);

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


__m64 to_m64(__m128i a) pure @trusted
{
    long2 la = cast(long2)a;
    long1 r;
    r.ptr[0] = la.array[0];
    return r;
}

__m128i to_m128i(__m64 a) pure @trusted
{
    long2 r = [0, 0];
    r.ptr[0] = a.array[0];
    return cast(__m128i)r;
}

// SOME NEON INTRINSICS
// Emulating some x86 intrinsics needs access to a range of ARM intrinsics.
// Not in the public API but the simde project expose it all for the user to use.
// MAYDO: create a new neon.d module, for internal use only.
// MAYDO: port them to ARM32 so that ARM32 can be as fast as ARM64.
static if (LDC_with_ARM64)
{
    // VERY USEFUL LINK
    // https://github.com/ldc-developers/llvm-project/blob/ldc-release/11.x/llvm/include/llvm/IR/IntrinsicsAArch64.td

    pragma(LDC_intrinsic, "llvm.aarch64.neon.addp.v8i8")
        byte8 vpadd_u8(byte8 a, byte8 b) pure @safe;

    byte8 vand_u8(byte8 a, byte8 b) pure @safe
    {
        return a & b;
    }

    int4 vcombine_s32(int2 lo, int2 hi) pure @trusted
    {
        int4 r;
        r.ptr[0] = lo.array[0];
        r.ptr[1] = lo.array[1];
        r.ptr[2] = hi.array[0];
        r.ptr[3] = hi.array[1];
        return r;
    }

    byte16 vcombine_s8(byte8 lo, byte8 hi) pure @trusted
    {
        byte16 r;
        r.ptr[0]  = lo.array[0];
        r.ptr[1]  = lo.array[1];
        r.ptr[2]  = lo.array[2];
        r.ptr[3]  = lo.array[3];
        r.ptr[4]  = lo.array[4];
        r.ptr[5]  = lo.array[5];
        r.ptr[6]  = lo.array[6];
        r.ptr[7]  = lo.array[7];
        r.ptr[8]  = hi.array[0];
        r.ptr[9]  = hi.array[1];
        r.ptr[10] = hi.array[2];
        r.ptr[11] = hi.array[3];
        r.ptr[12] = hi.array[4];
        r.ptr[13] = hi.array[5];
        r.ptr[14] = hi.array[6];
        r.ptr[15] = hi.array[7];
        return r;
    }

    pragma(LDC_intrinsic, "llvm.aarch64.neon.fcvtms.v4i32.v4f32")
        int4 vcvtmq_s32_f32(float4 a) pure @safe;

    pragma(LDC_intrinsic, "llvm.aarch64.neon.fcvtns.v4i32.v4f32")
        int4 vcvtnq_s32_f32(float4 a) pure @safe;

    pragma(LDC_intrinsic, "llvm.aarch64.neon.fcvtps.v4i32.v4f32")
        int4 vcvtpq_s32_f32(float4 a) pure @safe;

    pragma(LDC_intrinsic, "llvm.aarch64.neon.fcvtzs.v4i32.v4f32")
        int4 vcvtzq_s32_f32(float4 a) pure @safe;

    short4 vget_high_s16(short8 a) pure @trusted
    {
        short4 r;
        r.ptr[0] = a.array[4];
        r.ptr[1] = a.array[5];
        r.ptr[2] = a.array[6];
        r.ptr[3] = a.array[7];
        return r;
    }

    int2 vget_high_s32(int4 a) pure @trusted
    {
        int2 r;
        r.ptr[0] = a.array[2];
        r.ptr[1] = a.array[3];
        return r;
    }

    byte8 vget_high_u8(byte16 a) pure @trusted
    {
        byte8 r;
        r.ptr[0] = a.array[8];
        r.ptr[1] = a.array[9];
        r.ptr[2] = a.array[10];
        r.ptr[3] = a.array[11];
        r.ptr[4] = a.array[12];
        r.ptr[5] = a.array[13];
        r.ptr[6] = a.array[14];
        r.ptr[7] = a.array[15];
        return r;
    }

    short4 vget_low_s16(short8 a) pure @trusted
    {
        short4 r;
        r.ptr[0] = a.array[0];
        r.ptr[1] = a.array[1];
        r.ptr[2] = a.array[2];
        r.ptr[3] = a.array[3];
        return r;
    } 

    int2 vget_low_s32(int4 a) pure @trusted
    {
        int2 r;
        r.ptr[0] = a.array[0];
        r.ptr[1] = a.array[1];
        return r;
    }

    byte8 vget_low_u8(byte16 a) pure @trusted
    {
        byte8 r;
        r.ptr[0] = a.array[0];
        r.ptr[1] = a.array[1];
        r.ptr[2] = a.array[2];
        r.ptr[3] = a.array[3];
        r.ptr[4] = a.array[4];
        r.ptr[5] = a.array[5];
        r.ptr[6] = a.array[6];
        r.ptr[7] = a.array[7];
        return r;
    }

    pragma(LDC_intrinsic, "llvm.aarch64.neon.smax.v8i16")
        short8 vmaxq_s16(short8 a, short8 b) pure @safe;

    pragma(LDC_intrinsic, "llvm.aarch64.neon.smin.v8i16")
        short8 vminq_s16(short8 a, short8 b) pure @safe;

    int4 vmull_s16(short4 a, short4 b) pure @trusted
    {
        int4 r;
        r.ptr[0] = a.array[0] * b.array[0];
        r.ptr[1] = a.array[1] * b.array[1];
        r.ptr[2] = a.array[2] * b.array[2];
        r.ptr[3] = a.array[3] * b.array[3];
        return r;
    }

    static if(__VERSION__ >= 2088) // LDC 1.18 start using LLVM9 who changes the name of the builtin
    {
        pragma(LDC_intrinsic, "llvm.aarch64.neon.faddp.v4f32")
            float4 vpaddq_f32(float4 a, float4 b) pure @safe;
    }
    else
    {
        pragma(LDC_intrinsic, "llvm.aarch64.neon.addp.v4f32")
            float4 vpaddq_f32(float4 a, float4 b) pure @safe;
    }

    pragma(LDC_intrinsic, "llvm.aarch64.neon.addp.v2i32")
        int2 vpadd_s32(int2 a, int2 b) pure @safe;

    pragma(LDC_intrinsic, "llvm.aarch64.neon.addp.v16i8")
        byte16 vpaddq_s8(byte16 a, byte16 b) pure @safe;

    pragma(LDC_intrinsic, "llvm.aarch64.neon.sqxtn.v8i8")
        byte8 vqmovn_s16(short8 a) pure @safe;

    pragma(LDC_intrinsic, "llvm.aarch64.neon.sqxtun.v8i8")
        byte8 vqmovun_s16(short8 a) pure @safe;

    pragma(LDC_intrinsic, "llvm.aarch64.neon.urhadd.v16i8")
        byte16 vrhadd_u8(byte16 a, byte16 b) pure @safe;

    pragma(LDC_intrinsic, "llvm.aarch64.neon.urhadd.v8i16")
        short8 vrhadd_u16(short8 a, short8 b) pure @safe;

    byte8 vshr_u8(byte8 a, byte8 b) pure @safe
    {
        return a >>> b;
    }
}

