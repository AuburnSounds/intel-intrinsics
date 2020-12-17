/**
* `core.simd` emulation layer.
*
* Copyright: Copyright Auburn Sounds 2016-2018, Stefanos Baziotis 2019.
* License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
* Authors:   Guillaume Piolat
*/
module inteli.types;


pure:
nothrow:
@nogc:

version(GNU)
{
    version(X86_64)
    {
        enum MMXSizedVectorsAreEmulated = false;
        enum SSESizedVectorsAreEmulated = false;

        import gcc.builtins;

        float4 loadUnaligned(Vec)(const(float)* pvec) @trusted if (is(Vec == float4))
        {
            return __builtin_ia32_loadups(pvec);
        }

        double2 loadUnaligned(Vec)(const(double)* pvec) @trusted if (is(Vec == double2))
        {
            return __builtin_ia32_loadupd(pvec);
        }

        byte16 loadUnaligned(Vec)(const(byte)* pvec) @trusted if (is(Vec == byte16))
        {
            return cast(byte16) __builtin_ia32_loaddqu(cast(const(char)*) pvec);
        }

        short8 loadUnaligned(Vec)(const(short)* pvec) @trusted if (is(Vec == short8))
        {
            return cast(short8) __builtin_ia32_loaddqu(cast(const(char)*) pvec);
        }

        int4 loadUnaligned(Vec)(const(int)* pvec) @trusted if (is(Vec == int4))
        {
            return cast(int4) __builtin_ia32_loaddqu(cast(const(char)*) pvec);
        }

        long2 loadUnaligned(Vec)(const(long)* pvec) @trusted if (is(Vec == long2))
        {
            return cast(long2) __builtin_ia32_loaddqu(cast(const(char)*) pvec);
        }

        void storeUnaligned(Vec)(Vec v, float* pvec) @trusted if (is(Vec == float4))
        {
            __builtin_ia32_storeups(pvec, v);
        }

        void storeUnaligned(Vec)(Vec v, double* pvec) @trusted if (is(Vec == double2))
        {
            __builtin_ia32_storeupd(pvec, v);
        }

        void storeUnaligned(Vec)(Vec v, byte* pvec) @trusted if (is(Vec == byte16))
        {
            __builtin_ia32_storedqu(cast(char*)pvec, v);
        }

        void storeUnaligned(Vec)(Vec v, short* pvec) @trusted if (is(Vec == short8))
        {
            __builtin_ia32_storedqu(cast(char*)pvec, v);
        }

        void storeUnaligned(Vec)(Vec v, int* pvec) @trusted if (is(Vec == int4))
        {
            __builtin_ia32_storedqu(cast(char*)pvec, v);
        }

        void storeUnaligned(Vec)(Vec v, long* pvec) @trusted if (is(Vec == long2))
        {
            __builtin_ia32_storedqu(cast(char*)pvec, v);
        }

        // TODO: for performance, replace that anywhere possible by a GDC intrinsic
        Vec shufflevector(Vec, mask...)(Vec a, Vec b) @trusted
        {
            enum Count = Vec.array.length;
            static assert(mask.length == Count);

            Vec r = void;
            foreach(int i, m; mask)
            {
                static assert (m < Count * 2);
                int ind = cast(int)m;
                if (ind < Count)
                    r.ptr[i] = a.array[ind];
                else
                    r.ptr[i] = b.array[ind - Count];
            }
            return r;
        }
    }
    else
    {
        enum MMXSizedVectorsAreEmulated = true;
        enum SSESizedVectorsAreEmulated = true;
    }
}
else version(LDC)
{
    public import ldc.simd;

    enum MMXSizedVectorsAreEmulated = false;
    enum SSESizedVectorsAreEmulated = false;
}
else version(DigitalMars)
{
    public import core.simd;

    version(D_SIMD)
    {
        enum MMXSizedVectorsAreEmulated = true;
        enum SSESizedVectorsAreEmulated = true; // Should be false, but it is blocked by https://issues.dlang.org/show_bug.cgi?id=21474
    }
    else
    {
        // Some DMD 32-bit targets don't have D_SIMD
        enum MMXSizedVectorsAreEmulated = true;
        enum SSESizedVectorsAreEmulated = true;
    }
}

enum CoreSimdIsEmulated = MMXSizedVectorsAreEmulated || SSESizedVectorsAreEmulated;

static if (CoreSimdIsEmulated)
{
    // core.simd is emulated in some capacity: introduce `VectorOps`

    mixin template VectorOps(VectorType, ArrayType: BaseType[N], BaseType, size_t N)
    {
        enum Count = N;
        alias Base = BaseType;

        BaseType* ptr() return pure nothrow @nogc
        {
            return array.ptr;
        }

        // Unary operators
        VectorType opUnary(string op)() pure nothrow @safe @nogc
        {
            VectorType res = void;
            mixin("res.array[] = " ~ op ~ "array[];");
            return res;
        }

        // Binary operators
        VectorType opBinary(string op)(VectorType other) pure const nothrow @safe @nogc
        {
            VectorType res = void;
            mixin("res.array[] = array[] " ~ op ~ " other.array[];");
            return res;
        }

        // Assigning a static array
        void opAssign(ArrayType v) pure nothrow @safe @nogc
        {
            array[] = v[];
        }

        void opOpAssign(string op)(VectorType other) pure nothrow @safe @nogc
        {
            mixin("array[] "  ~ op ~ "= other.array[];");
        }

        // Assigning a dyn array
        this(ArrayType v) pure nothrow @safe @nogc
        {
            array[] = v[];
        }

        // Broadcast constructor
        this(BaseType x) pure nothrow @safe @nogc
        {
            array[] = x;
        }

        /// We can't support implicit conversion but do support explicit casting.
        /// "Vector types of the same size can be implicitly converted among each other."
        /// Casting to another vector type is always just a raw copy.
        VecDest opCast(VecDest)() pure const nothrow @trusted @nogc
            if (VecDest.sizeof == VectorType.sizeof)
            {
                VecDest dest = void;
                // Copy
                dest.array[] = (cast(typeof(dest.array))cast(void[VectorType.sizeof])array)[];
                return dest;
            }

        ref inout(BaseType) opIndex(size_t i) inout pure nothrow @safe @nogc
        {
            return array[i];
        }

    }

    private template BaseType(V)
    {
        alias typeof(V.array[0]) BaseType;
    }

    private template TrueMask(V)
    {
        alias Elem = BaseType!V;

        static if (is(Elem == float))
        {
            immutable uint m1 = 0xffffffff;
            enum Elem TrueMask = *cast(float*)(&m1);
        }
        else static if (is(Elem == double))
        {
            immutable ulong m1 = 0xffffffff_ffffffff;
            enum Elem TrueMask = *cast(double*)(&m1);
        }
        else // integer case
        {
            enum Elem TrueMask = -1;
        }
    }

    // they just weren't interesting enough, use v.array[i] instead.
    deprecated auto extractelement(Vec, int index, Vec2)(Vec2 vec) @trusted
    {
        static assert(Vec.sizeof == Vec2.sizeof);
        import core.stdc.string: memcpy;
        Vec v = void;
        memcpy(&v, &vec, Vec2.sizeof);
        return v.array[index];
    }

    // they just weren't interesting enough, use v.ptr[i] = x instead.
    deprecated auto insertelement(Vec, int index, Vec2)(Vec2 vec, Vec.Base e) @trusted
    {
        static assert(Vec.sizeof == Vec2.sizeof);
        import core.stdc.string: memcpy;
        Vec v = void;
        memcpy(&v, &vec, Vec2.sizeof);
        v.array[index] = e;
        return v;
    }

    template loadUnaligned(Vec)
    {
        // Note: can't be @safe with this signature
        Vec loadUnaligned(const(BaseType!Vec)* pvec) @trusted
        {
            enum bool isVector = ( (Vec.sizeof == 8)  && (!MMXSizedVectorsAreEmulated)
                                || (Vec.sizeof == 16) && (!SSESizedVectorsAreEmulated) );

            static if (isVector)
            {
                // PERF: there is probably something faster to do for this compiler (DMD).
                //       Avoid this on DMD in the future.
                enum size_t Count = Vec.array.length;
                Vec result;
                foreach(int i; 0..Count)
                {
                    result.ptr[i] = pvec[i];
                }
                return result;
            }
            else
            {
                // Since this vector is emulated, it doesn't have alignement constraints
                // and as such we can just cast it.
                return *cast(Vec*)(pvec);
            }
        }
    }

    template storeUnaligned(Vec)
    {
        // Note: can't be @safe with this signature
        void storeUnaligned(Vec v, BaseType!Vec* pvec) @trusted
        {
            enum bool isVector = ( (Vec.sizeof == 8)  && (!MMXSizedVectorsAreEmulated)
                                || (Vec.sizeof == 16) && (!SSESizedVectorsAreEmulated) );

            static if (isVector)
            {
                // PERF: there is probably something faster to do for this compiler (DMD).
                //       Avoid this on DMD in the future.
                enum size_t Count = Vec.array.length;
                foreach(int i; 0..Count)
                    pvec[i] = v.array[i];
            }
            else
            {
                *cast(Vec*)(pvec) = v;
            }
        }
    }

    Vec shufflevector(Vec, mask...)(Vec a, Vec b) @safe
    {
        enum size_t Count = Vec.array.length;
        static assert(mask.length == Count);

        Vec r = void;
        foreach(int i, m; mask)
        {
            static assert (m < Count * 2);
            int ind = cast(int)m;
            if (ind < Count)
                r.array[i] = a.array[ind];
            else
                r.array[i] = b.array[ind-Count];
        }
        return r;
    }

    // emulate ldc.simd cmpMask

    Vec equalMask(Vec)(Vec a, Vec b) @safe // for floats, equivalent to "oeq" comparison
    {
        enum size_t Count = Vec.array.length;
        Vec result;
        foreach(int i; 0..Count)
        {
            bool cond = a.array[i] == b.array[i];
            result.array[i] = cond ? TrueMask!Vec : 0;
        }
        return result;
    }

    Vec notEqualMask(Vec)(Vec a, Vec b) @safe // for floats, equivalent to "one" comparison
    {
        enum size_t Count = Vec.array.length;
        Vec result;
        foreach(int i; 0..Count)
        {
            bool cond = a.array[i] != b.array[i];
            result.array[i] = cond ? TrueMask!Vec : Vec.FalseMask;
        }
        return result;
    }

    Vec greaterMask(Vec)(Vec a, Vec b) @safe // for floats, equivalent to "ogt" comparison
    {
        enum size_t Count = Vec.array.length;
        Vec result;
        foreach(int i; 0..Count)
        {
            bool cond = a.array[i] > b.array[i];
            result.array[i] = cond ? TrueMask!Vec : 0;
        }
        return result;
    }

    Vec greaterOrEqualMask(Vec)(Vec a, Vec b) @safe // for floats, equivalent to "oge" comparison
    {
        enum size_t Count = Vec.array.length;
        Vec result;
        foreach(int i; 0..Count)
        {
            bool cond = a.array[i] > b.array[i];
            result.array[i] = cond ? TrueMask!Vec : Vec.FalseMask;
        }
        return result;
    }

}
else
{
    public import core.simd;
}

static if (MMXSizedVectorsAreEmulated)
{
    /// MMX-like SIMD types
    struct float2
    {
        float[2] array;
        mixin VectorOps!(float2, float[2]);

        private static float allOnes() pure nothrow @nogc @trusted
        {
            uint m1 = 0xffffffff;
            return *cast(float*)(&m1);
        }
    }

    struct byte8
    {
        byte[8] array;
        mixin VectorOps!(byte8, byte[8]);
    }

    struct short4
    {
        short[4] array;
        mixin VectorOps!(short4, short[4]);
    }

    struct int2
    {
        int[2] array;
        mixin VectorOps!(int2, int[2]);
    }

    struct long1
    {
        long[1] array;
        mixin VectorOps!(long1, long[1]);
    }
}
else
{
    // For this compiler, defining MMX-sized vectors is working.
    public import core.simd;
    alias Vector!(long [1]) long1;
    alias Vector!(float[2]) float2;
    alias Vector!(int  [2]) int2;
    alias Vector!(short[4]) short4;
    alias Vector!(byte [8]) byte8;
}

static assert(float2.sizeof == 8);
static assert(byte8.sizeof == 8);
static assert(short4.sizeof == 8);
static assert(int2.sizeof == 8);
static assert(long1.sizeof == 8);


static if (SSESizedVectorsAreEmulated)
{
    /// SSE-like SIMD types

    struct float4
    {
        float[4] array;
        mixin VectorOps!(float4, float[4]);
    }

    struct byte16
    {
        byte[16] array;
        mixin VectorOps!(byte16, byte[16]);
    }

    struct short8
    {
        short[8] array;
        mixin VectorOps!(short8, short[8]);
    }

    struct int4
    {
        int[4] array;
        mixin VectorOps!(int4, int[4]);
    }

    struct long2
    {
        long[2] array;
        mixin VectorOps!(long2, long[2]);
    }

    struct double2
    {
        double[2] array;
        mixin VectorOps!(double2, double[2]);
    }
}

static assert(float4.sizeof == 16);
static assert(byte16.sizeof == 16);
static assert(short8.sizeof == 16);
static assert(int4.sizeof == 16);
static assert(long2.sizeof == 16);
static assert(double2.sizeof == 16);


unittest
{
    float4 a = [1, 3, 5, 7];
    float4 b = [2, 3, 4, 5];
    int4 c = cast(int4)(greaterMask!float4(a, b));
    static immutable int[4] correct = [0, 0, 0xffff_ffff, 0xffff_ffff];
    assert(c.array == correct);
}


alias __m128 = float4;
alias __m128i = int4;
alias __m128d = double2;
alias __m64 = long1; // like in Clang, __m64 is a vector of 1 long

int _MM_SHUFFLE2(int x, int y) pure @safe
{
    assert(x >= 0 && x <= 1);
    assert(y >= 0 && y <= 1);
    return (x << 1) | y;
}

int _MM_SHUFFLE(int z, int y, int x, int w) pure @safe
{
    assert(x >= 0 && x <= 3);
    assert(y >= 0 && y <= 3);
    assert(z >= 0 && z <= 3);
    assert(w >= 0 && w <= 3);
    return (z<<6) | (y<<4) | (x<<2) | w;
}

// test assignment from scalar to vector type
unittest
{
    float4 A = 3.0f;
    float[4] correctA = [3.0f, 3.0f, 3.0f, 3.0f];
    assert(A.array == correctA);

    int2 B = 42;
    int[2] correctB = [42, 42];
    assert(B.array == correctB);
}
