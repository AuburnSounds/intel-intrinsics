module inteli.pmmintrin;
/* Copyright (C) 2003-2017 Free Software Foundation, Inc.

   This file is part of GCC.

   GCC is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 3, or (at your option)
   any later version.

   GCC is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   Under Section 7 of GPL version 3, you are granted additional
   permissions described in the GCC Runtime Library Exception, version
   3.1, as published by the Free Software Foundation.

   You should have received a copy of the GNU General Public License and
   a copy of the GCC Runtime Library Exception along with this program;
   see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see
   <http://www.gnu.org/licenses/>.  */

/* Implemented from the specification included in the Intel C++ Compiler
   User Guide and Reference, version 9.0.  */

/* We need definitions from the SSE2 and SSE header files*/

public import inteli.types;

import inteli.internals;

public import inteli.mmx;
public import inteli.xmmintrin;
public import inteli.emmintrin;

package:
@nogc @trusted:
// pragma(inline,true):

/* Additional bits in the MXCSR.  */
enum int _MM_DENORMALS_ZERO_MASK	=	0x0040;
enum int _MM_DENORMALS_ZERO_ON	=	0x0040;
enum int _MM_DENORMALS_ZERO_OFF	=	0x0000;

void _MM_SET_DENORMALS_ZERO_MODE(mode)() 
{
    _mm_setcsr((_mm_getcsr & ~_MM_DENORMALS_ZERO_MASK) | (mode));
}

auto _MM_GET_DENORMALS_ZERO_MODE() 
{
    return (_mm_getcsr & _MM_DENORMALS_ZERO_MASK);
}


__m128 _mm_addsub_ps(__m128 a, __m128 b) 
{
    version(LDC) return __asm!__m128("addsubps $2,$0","=x,0,x",a,b);
    else{
        a.array[0] =a.array[0]-b.array[0];
        a.array[1] =a.array[1]+b.array[1];
        a.array[2] =a.array[2]-b.array[2];
        a.array[3] =a.array[3]+b.array[3];
        return a;
    }
}


__m128 _mm_hadd_ps (__m128 a, __m128 b) 
{
    version(LDC) return __asm!__m128("haddps $2,$0","=x,0,x",a,b);
    else{
        a.array[0] =a.array[0]+a.array[1];
        a.array[1] =a.array[2]+a.array[3];
        a.array[2] =b.array[0]+b.array[1];
        a.array[3] =b.array[2]+b.array[3];
        return a;
    }
}


__m128 _mm_hsub_ps (__m128 a, __m128 b) 
{
    version(LDC) return __asm!__m128("hsubps $2,$0","=x,0,x",a,b);
    else{
        a.array[0] =a.array[0]-a.array[1];
        a.array[1] =a.array[2]-a.array[3];
        a.array[2] =b.array[0]-b.array[1];
        a.array[3] =b.array[2]-b.array[3];
        return a;
    }
}

__m128 _mm_movehdup_ps (__m128 a) 
{
    version(LDC) return __asm!__m128("movshdup $1,$0","=x,x",a);
    else{
        a.array[0] =a.array[1];
        a.array[1] =a.array[1];
        a.array[2] =a.array[3];
        a.array[3] =a.array[3];
        return a;
    }
}


__m128 _mm_moveldup_ps (__m128 a) 
{
    version(LDC) return __asm!__m128("movsldup $1,$0","=x,x",a);
    else{
        a.array[0] =a.array[0];
        a.array[1] =a.array[0];
        a.array[2] =a.array[2];
        a.array[3] =a.array[2];
        return a;
    }
}

unittest{
    auto v1 =_mm_setr_ps(1.0,2.0,3.0,4.0);
    auto v2 =_mm_setr_ps(1.0,2.0,3.0,4.0);
    assert(_mm_addsub_ps(v1,v2)==_mm_setr_ps(0.0,4.0,0.0,8.0));
    assert(_mm_hadd_ps(v1,v2)==_mm_setr_ps(3.0,7.0,3.0,7.0));
    assert(_mm_hsub_ps(v1,v2)==_mm_setr_ps(-1.0,-1.0,-1.0,-1.0));
    assert(_mm_moveldup_ps(v1)==_mm_setr_ps(1.0,1.0,3.0,3.0));
    assert(_mm_movehdup_ps(v1)==_mm_setr_ps(2.0,2.0,4.0,4.0));
}

__m128d _mm_addsub_pd (__m128d a, __m128d b) 
{
    version(LDC) return __asm!__m128d("addsubpd $2,$0","=x,0,x",a,b);
    else{
        a.array[0] =a.array[0]-b.array[0];
        a.array[1] =a.array[1]+b.array[1];
        return a;
    }
}


__m128d _mm_hadd_pd (__m128d a, __m128d b) 
{
    version(LDC) return __asm!__m128d("haddpd $2,$0","=x,0,x",a,b);
    else{
        a.array[0] =a.array[0]+a.array[1];
        a.array[1] =b.array[0]+b.array[1];
        return a;
    }
}


__m128d _mm_hsub_pd (__m128d a, __m128d b) 
{
    version(LDC) return __asm!__m128d("hsubpd $2,$0","=x,0,x",a,b);
    else{
        a.array[0] =a.array[0]-a.array[1];
        a.array[1] =b.array[0]-b.array[1];
        return a;
    }
}


__m128d _mm_loaddup_pd (const(double) *__P) 
{
    return _mm_load1_pd(__P);
}

__m128d _mm_movedup_pd (__m128d a) 
{
    return _mm_shuffle_pd!(_MM_SHUFFLE2(0,0))(a, a);
}

unittest{
    auto v1 =_mm_setr_pd(1.0,2.0);
    auto v2 =_mm_setr_pd(1.0,2.0);
    assert(_mm_addsub_pd(v1,v2)==_mm_setr_pd(0.0,4.0));
    assert(_mm_hadd_pd(v1,v2)==_mm_setr_pd(3.0,3.0));
    assert(_mm_hsub_pd(v1,v2)==_mm_setr_pd(-1.0,-1.0));
}

__m128i _mm_lddqu_si128 (const(__m128i)  * a) 
{
    version(LDC) return __asm!__m128("lddqu $1,$0","=x,*m",a);
    else{
        return _mm_loadu_si128(a);
    }
}

unittest{
    import core.stdc.stdlib:malloc;
    int[] v = (cast(int *)malloc(int.sizeof*4))[0..4];
    v[0] = 1;
    v[1] = 2;
    v[2] = 3;
    v[3] = 4;
    auto v1 =_mm_lddqu_si128(cast(__m128i *)v.ptr);
    auto v2 =_mm_lddqu_si128(cast(__m128i *)v.ptr);
    assert(_mm_add_epi32(v1,v2)==_mm_setr_epi32(2,4,6,8));
}


void _mm_monitor (const(void)  * __P, uint __E, uint __H)
{
    asm @nogc nothrow pure
    {
        mov RAX, __P;
        mov ECX, __E;
        mov EDX, __H;
        monitor ;
    }
}

void _mm_mwait (uint __E, uint __H)
{
    asm @nogc nothrow pure
    {
        mov EAX, __H;
        mov ECX, __E;
        mwait ;
    }
}

