/**
* Copyright: Copyright Auburn Sounds 2016-2018.
* License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
* Authors:   Guillaume Piolat
*/
module inteli.types;

version(LDC)
{
    public import core.simd;
    public import ldc.simd;

    // Declare vector types that correspond to MMX types
    // Because they are expressible in IR anyway.
    alias Vector!(long [1]) long1;
    alias Vector!(float[2]) float2;
    alias Vector!(int  [2]) int2;
    alias Vector!(short[4]) short4;
    alias Vector!(byte [8]) byte8;
}
else
{
    // This is a LDC SIMD emulation layer, for use with other D compilers.
    // The goal is to be very similar in precision.
    // The biggest differences are:
    //
    // 1. `cast` everywhere. With LDC vector types, short8 is implicitely convertible to int4
    //   but this is sadly impossible in D without D_SIMD (Windows 32-bit).
    //
    // 2. `vec.array` is directly writeable.

    nothrow:
    @nogc:
    pure:


    /// MMX-like SIMD types
    struct float2
    {
        float[2] array;
        mixin VectorOps!(float2, float[2]);

        enum float TrueMask = allOnes();
        enum float FalseMask = 0.0f;

        private static float allOnes()
        {
            uint m1 = 0xffffffff;
            return *cast(float*)(&m1);
        }
    }

    struct byte8
    {
        byte[8] array;
        mixin VectorOps!(byte8, byte[8]);
        enum byte TrueMask = -1;
        enum byte FalseMask = 0;
    }

    struct short4
    {
        short[4] array;
        mixin VectorOps!(short4, short[4]);
        enum short TrueMask = -1;
        enum short FalseMask = 0;
    }

    struct int2
    {
        int[2] array;
        mixin VectorOps!(int2, int[2]);
        enum int TrueMask = -1;
        enum int FalseMask = 0;
    }

    struct long1
    {
        long[1] array;
        mixin VectorOps!(long1, long[1]);
        enum long TrueMask = -1;
        enum long FalseMask = 0;
    }

    static assert(float2.sizeof == 8);
    static assert(byte8.sizeof == 8);
    static assert(short4.sizeof == 8);
    static assert(int2.sizeof == 8);
    static assert(long1.sizeof == 8);


    /// SSE-like SIMD types

    struct float4
    {
        float[4] array;
        mixin VectorOps!(float4, float[4]);

        enum float TrueMask = allOnes();
        enum float FalseMask = 0.0f;

        private static float allOnes()
        {
            uint m1 = 0xffffffff;
            return *cast(float*)(&m1);
        }
    }

    struct byte16
    {
        byte[16] array;
        mixin VectorOps!(byte16, byte[16]);
        enum byte TrueMask = -1;
        enum byte FalseMask = 0;
    }

    struct short8
    {
        short[8] array;
        mixin VectorOps!(short8, short[8]);
        enum short TrueMask = -1;
        enum short FalseMask = 0;
    }

    struct int4
    {
        int[4] array;
        mixin VectorOps!(int4, int[4]);
        enum int TrueMask = -1;
        enum int FalseMask = 0;
    }

    struct long2
    {
        long[2] array;
        mixin VectorOps!(long2, long[2]);
        enum long TrueMask = -1;
        enum long FalseMask = 0;
    }

    struct double2
    {
        double[2] array;
        mixin VectorOps!(double2, double[2]);

        enum double TrueMask = allOnes();
        enum double FalseMask = 0.0f;

        private static double allOnes()
        {
            ulong m1 = 0xffffffff_ffffffff;
            return *cast(double*)(&m1);
        }
    }

    static assert(float4.sizeof == 16);
    static assert(byte16.sizeof == 16);
    static assert(short8.sizeof == 16);
    static assert(int4.sizeof == 16);
    static assert(long2.sizeof == 16);
    static assert(double2.sizeof == 16);

    mixin template VectorOps(VectorType, ArrayType: BaseType[N], BaseType, size_t N)
    {
        enum Count = N;
        alias Base = BaseType;

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
            // import core.stdc.string: memcpy;
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

    auto extractelement(Vec, int index, Vec2)(Vec2 vec) @trusted
    {
        static assert(Vec.sizeof == Vec2.sizeof);
        import core.stdc.string: memcpy;
        Vec v = void;
        memcpy(&v, &vec, Vec2.sizeof);
        return v.array[index];
    }

    auto insertelement(Vec, int index, Vec2)(Vec2 vec, Vec.Base e) @trusted
    {
        static assert(Vec.sizeof == Vec2.sizeof);
        import core.stdc.string: memcpy;
        Vec v = void;
        memcpy(&v, &vec, Vec2.sizeof);
        v.array[index] = e;
        return v;
    }

    // Note: can't be @safe with this signature
    Vec loadUnaligned(Vec)(const(Vec.Base)* pvec) @trusted
    {
        return *cast(Vec*)(pvec);
    }

     // Note: can't be @safe with this signature
    void storeUnaligned(Vec)(Vec v, Vec.Base* pvec, ) @trusted
    {
        *cast(Vec*)(pvec) = v;
    }


    Vec shufflevector(Vec, mask...)(Vec a, Vec b) @safe
    {
        static assert(mask.length == Vec.Count);

        Vec r = void;
        foreach(int i, m; mask)
        {
            static assert (m < Vec.Count * 2);
            int ind = cast(int)m;
            if (ind < Vec.Count)
                r.array[i] = a.array[ind];
            else
                r.array[i] = b.array[ind-Vec.Count];
        }
        return r;
    }

    // emulate ldc.simd cmpMask

    Vec equalMask(Vec)(Vec a, Vec b) @safe // for floats, equivalent to "oeq" comparison
    {
        alias BaseType = Vec.Base;
        alias Count = Vec.Count;
        Vec result;
        foreach(int i; 0..Count)
        {
            bool cond = a.array[i] == b.array[i];
            result.array[i] = cond ? Vec.TrueMask : Vec.FalseMask;
        }
        return result;
    }

    Vec notEqualMask(Vec)(Vec a, Vec b) @safe // for floats, equivalent to "one" comparison
    {
        alias BaseType = Vec.Base;
        alias Count = Vec.Count;
        Vec result;
        foreach(int i; 0..Count)
        {
            bool cond = a.array[i] != b.array[i];
            result.array[i] = cond ? Vec.TrueMask : Vec.FalseMask;
        }
        return result;
    }

    Vec greaterMask(Vec)(Vec a, Vec b) @safe // for floats, equivalent to "ogt" comparison
    {
        alias BaseType = Vec.Base;
        alias Count = Vec.Count;
        Vec result;
        foreach(int i; 0..Count)
        {
            bool cond = a.array[i] > b.array[i];
            result.array[i] = cond ? Vec.TrueMask : Vec.FalseMask;
        }
        return result;
    }

    Vec greaterOrEqualMask(Vec)(Vec a, Vec b) @safe // for floats, equivalent to "oge" comparison
    {
        alias BaseType = Vec.Base;
        alias Count = Vec.Count;
        Vec result;
        foreach(int i; 0..Count)
        {
            bool cond = a.array[i] > b.array[i];
            result.array[i] = cond ? Vec.TrueMask : Vec.FalseMask;
        }
        return result;
    }

    unittest
    {
        float4 a = [1, 3, 5, 7];
        float4 b = [2, 3, 4, 5];
        int4 c = cast(int4)(greaterMask!float4(a, b));
        static immutable int[4] correct = [0, 0, 0xffff_ffff, 0xffff_ffff];
        assert(c.array == correct);
    }
}

nothrow:
@nogc:

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