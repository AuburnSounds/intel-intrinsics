/**
* Transcendental function on 4 numbers at once.
*
* Copyright: Copyright Auburn Sounds 2016-2018.
*            Copyright (C) 2007  Julien Pommier
* License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
* Authors:   Guillaume Piolat
*/
module inteli.math;

/* Copyright (C) 2007  Julien Pommier

  This software is provided 'as-is', without any express or implied
  warranty.  In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
     claim that you wrote the original software. If you use this software
     in a product, an acknowledgment in the product documentation would be
     appreciated but is not required.
  2. Altered source versions must be plainly marked as such, and must not be
     misrepresented as being the original software.
  3. This notice may not be removed or altered from any source distribution.

  (this is the zlib license)
*/
import inteli.emmintrin;

static immutable __m128 _ps_1   = [1.0f, 1.0f, 1.0f, 1.0f];
static immutable __m128 _ps_0p5 = [0.5f, 0.5f, 0.5f, 0.5f];

/* the smallest non denormalized float number */
static immutable __m128i _psi_min_norm_pos  = [0x00800000,   0x00800000,   0x00800000, 0x00800000];
static immutable __m128i _psi_mant_mask     = [0x7f800000,   0x7f800000,   0x7f800000, 0x7f800000];
static immutable __m128i _psi_inv_mant_mask = [~0x7f800000, ~0x7f800000, ~0x7f800000, ~0x7f800000];
static immutable __m128i _psi_sign_mask     = [0x80000000,   0x80000000,   0x80000000, 0x80000000];
static immutable __m128i _psi_inv_sign_mask = [~0x80000000, ~0x80000000, ~0x80000000, ~0x80000000];

static immutable __m128i _pi32_1    = [1, 1, 1, 1];
static immutable __m128i _pi32_inv1 = [~1, ~1, ~1, ~1];
static immutable __m128i _pi32_2    = [2, 2, 2, 2];
static immutable __m128i _pi32_4    = [4, 4, 4, 4];
static immutable __m128i _pi32_0x7f = [0x7f, 0x7f, 0x7f, 0x7f];

static immutable __m128 _ps_cephes_SQRTHF = [0.707106781186547524, 0.707106781186547524, 0.707106781186547524, 0.707106781186547524];
static immutable __m128 _ps_cephes_log_p0 = [7.0376836292E-2, 7.0376836292E-2, 7.0376836292E-2, 7.0376836292E-2];
static immutable __m128 _ps_cephes_log_p1 = [- 1.1514610310E-1, - 1.1514610310E-1, - 1.1514610310E-1, - 1.1514610310E-1];
static immutable __m128 _ps_cephes_log_p2 = [1.1676998740E-1, 1.1676998740E-1, 1.1676998740E-1, 1.1676998740E-1];
static immutable __m128 _ps_cephes_log_p3 = [- 1.2420140846E-1, - 1.2420140846E-1, - 1.2420140846E-1, - 1.2420140846E-1];
static immutable __m128 _ps_cephes_log_p4 = [+ 1.4249322787E-1, + 1.4249322787E-1, + 1.4249322787E-1, + 1.4249322787E-1];
static immutable __m128 _ps_cephes_log_p5 = [- 1.6668057665E-1, - 1.6668057665E-1, - 1.6668057665E-1, - 1.6668057665E-1];
static immutable __m128 _ps_cephes_log_p6 = [+ 2.0000714765E-1, + 2.0000714765E-1, + 2.0000714765E-1, + 2.0000714765E-1];
static immutable __m128 _ps_cephes_log_p7 = [- 2.4999993993E-1, - 2.4999993993E-1, - 2.4999993993E-1, - 2.4999993993E-1];
static immutable __m128 _ps_cephes_log_p8 = [+ 3.3333331174E-1, + 3.3333331174E-1, + 3.3333331174E-1, + 3.3333331174E-1];
static immutable __m128 _ps_cephes_log_q1 = [-2.12194440e-4, -2.12194440e-4, -2.12194440e-4, -2.12194440e-4];
static immutable __m128 _ps_cephes_log_q2 = [0.693359375, 0.693359375, 0.693359375, 0.693359375];

alias v4sf = __m128;
alias v4si = __m128i;

/* natural logarithm computed for 4 simultaneous float 
   return NaN for x <= 0
*/
v4sf _mm_log_ps(v4sf x)
{
    v4si emm0;
    v4sf one = _ps_1;
    v4sf invalid_mask = _mm_cmple_ps(x, _mm_setzero_ps());
    x = _mm_max_ps(x, cast(v4sf)_psi_min_norm_pos);  /* cut off denormalized stuff */
    emm0 = _mm_srli_epi32(_mm_castps_si128(x), 23);

    /* keep only the fractional part */
    x = _mm_and_ps(x,cast(v4sf)_psi_inv_mant_mask);
    x = _mm_or_ps(x, _ps_0p5);

    emm0 = _mm_sub_epi32(emm0, cast(v4si)_pi32_0x7f);
    v4sf e = _mm_cvtepi32_ps(emm0);

    e = _mm_add_ps(e, one);

    /* part2: 
     if( x < SQRTHF ) {
       e -= 1;
       x = x + x - 1.0;
     } else { x = x - 1.0; }
    */
    v4sf mask = _mm_cmplt_ps(x, _ps_cephes_SQRTHF);
    v4sf tmp = _mm_and_ps(x, mask);
    x = _mm_sub_ps(x, one);
    e = _mm_sub_ps(e, _mm_and_ps(one, mask));
    x = _mm_add_ps(x, tmp);
    v4sf z = _mm_mul_ps(x,x);
    v4sf y = _ps_cephes_log_p0;
    y = _mm_mul_ps(y, x);
    y = _mm_add_ps(y, _ps_cephes_log_p1);
    y = _mm_mul_ps(y, x);
    y = _mm_add_ps(y, _ps_cephes_log_p2);
    y = _mm_mul_ps(y, x);
    y = _mm_add_ps(y, _ps_cephes_log_p3);
    y = _mm_mul_ps(y, x);
    y = _mm_add_ps(y, _ps_cephes_log_p4);
    y = _mm_mul_ps(y, x);
    y = _mm_add_ps(y, _ps_cephes_log_p5);
    y = _mm_mul_ps(y, x);
    y = _mm_add_ps(y, _ps_cephes_log_p6);
    y = _mm_mul_ps(y, x);
    y = _mm_add_ps(y, _ps_cephes_log_p7);
    y = _mm_mul_ps(y, x);
    y = _mm_add_ps(y, _ps_cephes_log_p8);
    y = _mm_mul_ps(y, x);
    y = _mm_mul_ps(y, z);
    tmp = _mm_mul_ps(e, _ps_cephes_log_q1);
    y = _mm_add_ps(y, tmp);
    tmp = _mm_mul_ps(z, _ps_0p5);
    y = _mm_sub_ps(y, tmp);
    tmp = _mm_mul_ps(e, _ps_cephes_log_q2);
    x = _mm_add_ps(x, y);
    x = _mm_add_ps(x, tmp);
    x = _mm_or_ps(x, invalid_mask); // negative arg will be NAN
    return x;
}

static immutable __m128 _ps_exp_hi         = [88.3762626647949f, 88.3762626647949f, 88.3762626647949f, 88.3762626647949f];
static immutable __m128 _ps_exp_lo         = [-88.3762626647949f, -88.3762626647949f, -88.3762626647949f, -88.3762626647949f];
static immutable __m128 _ps_cephes_LOG2EF  = [1.44269504088896341, 1.44269504088896341, 1.44269504088896341, 1.44269504088896341];
static immutable __m128 _ps_cephes_exp_C1  = [0.693359375, 0.693359375, 0.693359375, 0.693359375];
static immutable __m128 _ps_cephes_exp_C2  = [-2.12194440e-4, -2.12194440e-4, -2.12194440e-4, -2.12194440e-4];
static immutable __m128 _ps_cephes_exp_p0  = [1.9875691500E-4, 1.9875691500E-4, 1.9875691500E-4, 1.9875691500E-4];
static immutable __m128 _ps_cephes_exp_p1  = [1.3981999507E-3, 1.3981999507E-3, 1.3981999507E-3, 1.3981999507E-3];
static immutable __m128 _ps_cephes_exp_p2  = [8.3334519073E-3, 8.3334519073E-3, 8.3334519073E-3, 8.3334519073E-3];
static immutable __m128 _ps_cephes_exp_p3  = [4.1665795894E-2, 4.1665795894E-2, 4.1665795894E-2, 4.1665795894E-2];
static immutable __m128 _ps_cephes_exp_p4  = [1.6666665459E-1, 1.6666665459E-1, 1.6666665459E-1, 1.6666665459E-1];
static immutable __m128 _ps_cephes_exp_p5  = [5.0000001201E-1, 5.0000001201E-1, 5.0000001201E-1, 5.0000001201E-1];

v4sf _mm_exp_ps(v4sf x) 
{
    v4sf tmp = _mm_setzero_ps(), fx;
    v4si emm0;
    v4sf one = _ps_1;

    x = _mm_min_ps(x, _ps_exp_hi);
    x = _mm_max_ps(x, _ps_exp_lo);

    /* express exp(x) as exp(g + n*log(2)) */
    fx = _mm_mul_ps(x, _ps_cephes_LOG2EF);
    fx = _mm_add_ps(fx, _ps_0p5);

    /* how to perform a floorf with SSE: just below */
    emm0 = _mm_cvttps_epi32(fx);
    tmp  = _mm_cvtepi32_ps(emm0);

    /* if greater, substract 1 */
    v4sf mask = _mm_cmpgt_ps(tmp, fx);    
    mask = _mm_and_ps(mask, one);
    fx = _mm_sub_ps(tmp, mask);

    tmp = _mm_mul_ps(fx, _ps_cephes_exp_C1);
    v4sf z = _mm_mul_ps(fx, _ps_cephes_exp_C2);
    x = _mm_sub_ps(x, tmp);
    x = _mm_sub_ps(x, z);

    z = _mm_mul_ps(x,x);

    v4sf y = _ps_cephes_exp_p0;
    y = _mm_mul_ps(y, x);
    y = _mm_add_ps(y, _ps_cephes_exp_p1);
    y = _mm_mul_ps(y, x);
    y = _mm_add_ps(y, _ps_cephes_exp_p2);
    y = _mm_mul_ps(y, x);
    y = _mm_add_ps(y, _ps_cephes_exp_p3);
    y = _mm_mul_ps(y, x);
    y = _mm_add_ps(y, _ps_cephes_exp_p4);
    y = _mm_mul_ps(y, x);
    y = _mm_add_ps(y, _ps_cephes_exp_p5);
    y = _mm_mul_ps(y, z);
    y = _mm_add_ps(y, x);
    y = _mm_add_ps(y, one);

    /* build 2^n */
    emm0 = _mm_cvttps_epi32(fx);
    emm0 = _mm_add_epi32(emm0, cast(v4si)_pi32_0x7f);
    emm0 = _mm_slli_epi32(emm0, 23);
    v4sf pow2n = _mm_castsi128_ps(emm0);
    y = _mm_mul_ps(y, pow2n);
    return y;
}

static immutable __m128 _ps_minus_cephes_DP1 = [-0.78515625, -0.78515625, -0.78515625, -0.78515625];
static immutable __m128 _ps_minus_cephes_DP2 = [-2.4187564849853515625e-4, -2.4187564849853515625e-4, -2.4187564849853515625e-4, -2.4187564849853515625e-4];
static immutable __m128 _ps_minus_cephes_DP3 = [-3.77489497744594108e-8, -3.77489497744594108e-8, -3.77489497744594108e-8, -3.77489497744594108e-8];
static immutable __m128 _ps_sincof_p0        = [-1.9515295891E-4, -1.9515295891E-4, -1.9515295891E-4, -1.9515295891E-4];
static immutable __m128 _ps_sincof_p1        = [ 8.3321608736E-3,  8.3321608736E-3,  8.3321608736E-3,  8.3321608736E-3];
static immutable __m128 _ps_sincof_p2        = [-1.6666654611E-1, -1.6666654611E-1, -1.6666654611E-1, -1.6666654611E-1];
static immutable __m128 _ps_coscof_p0        = [ 2.443315711809948E-005,  2.443315711809948E-005,  2.443315711809948E-005,  2.443315711809948E-005];
static immutable __m128 _ps_coscof_p1        = [-1.388731625493765E-003, -1.388731625493765E-003, -1.388731625493765E-003, -1.388731625493765E-003];
static immutable __m128 _ps_coscof_p2        = [ 4.166664568298827E-002,  4.166664568298827E-002,  4.166664568298827E-002,  4.166664568298827E-002];
static immutable __m128 _ps_cephes_FOPI      = [ 1.27323954473516,  1.27323954473516,  1.27323954473516,  1.27323954473516];


/* evaluation of 4 sines at onces, using only SSE1+MMX intrinsics so
   it runs also on old athlons XPs and the pentium III of your grand
   mother.

   The code is the exact rewriting of the cephes sinf function.
   Precision is excellent as long as x < 8192 (I did not bother to
   take into account the special handling they have for greater values
   -- it does not return garbage for arguments over 8192, though, but
   the extra precision is missing).

   Note that it is such that sinf((float)M_PI) = 8.74e-8, which is the
   surprising but correct result.

   Performance is also surprisingly good, 1.33 times faster than the
   macos vsinf SSE2 function, and 1.5 times faster than the
   __vrs4_sinf of amd's ACML (which is only available in 64 bits). Not
   too bad for an SSE1 function (with no special tuning) !
   However the latter libraries probably have a much better handling of NaN,
   Inf, denormalized and other special arguments..

   On my core 1 duo, the execution of this function takes approximately 95 cycles.

   From what I have observed on the experiments with Intel AMath lib, switching to an
   SSE2 version would improve the perf by only 10%.

   Since it is based on SSE intrinsics, it has to be compiled at -O2 to
   deliver full speed.
*/
v4sf _mm_sin_ps(v4sf x)  // any x
{
    v4sf xmm1, xmm2 = _mm_setzero_ps(), xmm3, sign_bit, y;

    v4si emm0, emm2;
    sign_bit = x;
    /* take the absolute value */
    x = _mm_and_ps(x,cast(v4sf)_psi_inv_sign_mask);
    /* extract the sign bit (upper one) */
    sign_bit = _mm_and_ps(sign_bit,cast(v4sf)_psi_sign_mask);

    /* scale by 4/Pi */
    y = _mm_mul_ps(x,_ps_cephes_FOPI);

    /* store the integer part of y in mm0 */
    emm2 = _mm_cvttps_epi32(y);
    /* j=(j+1) & (~1) (see the cephes sources) */
    emm2 = _mm_add_epi32(emm2, cast(v4si)_pi32_1);
    emm2 = _mm_and_si128(emm2, cast(v4si)_pi32_inv1);
    y = _mm_cvtepi32_ps(emm2);

    /* get the swap sign flag */
    emm0 = _mm_and_si128(emm2, cast(v4si)_pi32_4);
    emm0 = _mm_slli_epi32(emm0, 29);
    /* get the polynom selection mask 
     there is one polynom for 0 <= x <= Pi/4
     and another one for Pi/4<x<=Pi/2

     Both branches will be computed.
    */
    emm2 = _mm_and_si128(emm2, cast(v4si)_pi32_2);
    emm2 = _mm_cmpeq_epi32(emm2, _mm_setzero_si128());

    v4sf swap_sign_bit = _mm_castsi128_ps(emm0);
    v4sf poly_mask = _mm_castsi128_ps(emm2);
    sign_bit = _mm_xor_ps(sign_bit, swap_sign_bit);

    /* The magic pass: "Extended precision modular arithmetic" 
     x = ((x - y * DP1) - y * DP2) - y * DP3; */
    xmm1 =_ps_minus_cephes_DP1;
    xmm2 =_ps_minus_cephes_DP2;
    xmm3 =_ps_minus_cephes_DP3;
    xmm1 = _mm_mul_ps(y, xmm1);
    xmm2 = _mm_mul_ps(y, xmm2);
    xmm3 = _mm_mul_ps(y, xmm3);
    x = _mm_add_ps(x, xmm1);
    x = _mm_add_ps(x, xmm2);
    x = _mm_add_ps(x, xmm3);

    /* Evaluate the first polynom  (0 <= x <= Pi/4) */
    y =_ps_coscof_p0;
    v4sf z = _mm_mul_ps(x,x);

    y = _mm_mul_ps(y, z);
    y = _mm_add_ps(y,_ps_coscof_p1);
    y = _mm_mul_ps(y, z);
    y = _mm_add_ps(y,_ps_coscof_p2);
    y = _mm_mul_ps(y, z);
    y = _mm_mul_ps(y, z);
    v4sf tmp = _mm_mul_ps(z,_ps_0p5);
    y = _mm_sub_ps(y, tmp);
    y = _mm_add_ps(y,_ps_1);

    /* Evaluate the second polynom  (Pi/4 <= x <= 0) */

    v4sf y2 =_ps_sincof_p0;
    y2 = _mm_mul_ps(y2, z);
    y2 = _mm_add_ps(y2,_ps_sincof_p1);
    y2 = _mm_mul_ps(y2, z);
    y2 = _mm_add_ps(y2,_ps_sincof_p2);
    y2 = _mm_mul_ps(y2, z);
    y2 = _mm_mul_ps(y2, x);
    y2 = _mm_add_ps(y2, x);

    /* select the correct result from the two polynoms */  
    xmm3 = poly_mask;
    y2 = _mm_and_ps(xmm3, y2); //, xmm3);
    y = _mm_andnot_ps(xmm3, y);
    y = _mm_add_ps(y,y2);
    /* update the sign */
    y = _mm_xor_ps(y, sign_bit);
    return y;
}

/* almost the same as sin_ps */
v4sf _mm_cos_ps(v4sf x) 
{ // any x
    v4sf xmm1, xmm2 = _mm_setzero_ps(), xmm3, y;
    v4si emm0, emm2;

    /* take the absolute value */
    x = _mm_and_ps(x,cast(v4sf)_psi_inv_sign_mask);

    /* scale by 4/Pi */
    y = _mm_mul_ps(x,_ps_cephes_FOPI);

    /* store the integer part of y in mm0 */
    emm2 = _mm_cvttps_epi32(y);
    /* j=(j+1) & (~1) (see the cephes sources) */
    emm2 = _mm_add_epi32(emm2, cast(v4si)_pi32_1);
    emm2 = _mm_and_si128(emm2, cast(v4si)_pi32_inv1);
    y = _mm_cvtepi32_ps(emm2);

    emm2 = _mm_sub_epi32(emm2, cast(v4si)_pi32_2);

    /* get the swap sign flag */
    emm0 = _mm_andnot_si128(emm2, cast(v4si)_pi32_4);
    emm0 = _mm_slli_epi32(emm0, 29);
    /* get the polynom selection mask */
    emm2 = _mm_and_si128(emm2, cast(v4si)_pi32_2);
    emm2 = _mm_cmpeq_epi32(emm2, _mm_setzero_si128());

    v4sf sign_bit = _mm_castsi128_ps(emm0);
    v4sf poly_mask = _mm_castsi128_ps(emm2);

    /* The magic pass: "Extended precision modular arithmetic" 
     x = ((x - y * DP1) - y * DP2) - y * DP3; */
    xmm1 =_ps_minus_cephes_DP1;
    xmm2 =_ps_minus_cephes_DP2;
    xmm3 =_ps_minus_cephes_DP3;
    xmm1 = _mm_mul_ps(y, xmm1);
    xmm2 = _mm_mul_ps(y, xmm2);
    xmm3 = _mm_mul_ps(y, xmm3);
    x = _mm_add_ps(x, xmm1);
    x = _mm_add_ps(x, xmm2);
    x = _mm_add_ps(x, xmm3);

    /* Evaluate the first polynom  (0 <= x <= Pi/4) */
    y =_ps_coscof_p0;
    v4sf z = _mm_mul_ps(x,x);

    y = _mm_mul_ps(y, z);
    y = _mm_add_ps(y,_ps_coscof_p1);
    y = _mm_mul_ps(y, z);
    y = _mm_add_ps(y,_ps_coscof_p2);
    y = _mm_mul_ps(y, z);
    y = _mm_mul_ps(y, z);
    v4sf tmp = _mm_mul_ps(z,_ps_0p5);
    y = _mm_sub_ps(y, tmp);
    y = _mm_add_ps(y,_ps_1);

    /* Evaluate the second polynom  (Pi/4 <= x <= 0) */

    v4sf y2 =_ps_sincof_p0;
    y2 = _mm_mul_ps(y2, z);
    y2 = _mm_add_ps(y2,_ps_sincof_p1);
    y2 = _mm_mul_ps(y2, z);
    y2 = _mm_add_ps(y2,_ps_sincof_p2);
    y2 = _mm_mul_ps(y2, z);
    y2 = _mm_mul_ps(y2, x);
    y2 = _mm_add_ps(y2, x);

    /* select the correct result from the two polynoms */  
    xmm3 = poly_mask;
    y2 = _mm_and_ps(xmm3, y2); //, xmm3);
    y = _mm_andnot_ps(xmm3, y);
    y = _mm_add_ps(y,y2);
    /* update the sign */
    y = _mm_xor_ps(y, sign_bit);

    return y;
}

/* since sin_ps and cos_ps are almost identical, sincos_ps could replace both of them..
   it is almost as fast, and gives you a free cosine with your sine */
void _mm_sincos_ps(v4sf x, v4sf *s, v4sf *c) 
{
    v4sf xmm1, xmm2, xmm3 = _mm_setzero_ps(), sign_bit_sin, y;
    v4si emm0, emm2, emm4;

    sign_bit_sin = x;
    /* take the absolute value */
    x = _mm_and_ps(x, cast(v4sf)_psi_inv_sign_mask);
    /* extract the sign bit (upper one) */
    sign_bit_sin = _mm_and_ps(sign_bit_sin, cast(v4sf)_psi_sign_mask);

    /* scale by 4/Pi */
    y = _mm_mul_ps(x,_ps_cephes_FOPI);

    /* store the integer part of y in emm2 */
    emm2 = _mm_cvttps_epi32(y);

    /* j=(j+1) & (~1) (see the cephes sources) */
    emm2 = _mm_add_epi32(emm2, cast(v4si)_pi32_1);
    emm2 = _mm_and_si128(emm2, cast(v4si)_pi32_inv1);
    y = _mm_cvtepi32_ps(emm2);

    emm4 = emm2;

    /* get the swap sign flag for the sine */
    emm0 = _mm_and_si128(emm2, cast(v4si)_pi32_4);
    emm0 = _mm_slli_epi32(emm0, 29);
    v4sf swap_sign_bit_sin = _mm_castsi128_ps(emm0);

    /* get the polynom selection mask for the sine*/
    emm2 = _mm_and_si128(emm2, cast(v4si)_pi32_2);
    emm2 = _mm_cmpeq_epi32(emm2, _mm_setzero_si128());
    v4sf poly_mask = _mm_castsi128_ps(emm2);

    /* The magic pass: "Extended precision modular arithmetic" 
     x = ((x - y * DP1) - y * DP2) - y * DP3; */
    xmm1 =_ps_minus_cephes_DP1;
    xmm2 =_ps_minus_cephes_DP2;
    xmm3 =_ps_minus_cephes_DP3;
    xmm1 = _mm_mul_ps(y, xmm1);
    xmm2 = _mm_mul_ps(y, xmm2);
    xmm3 = _mm_mul_ps(y, xmm3);
    x = _mm_add_ps(x, xmm1);
    x = _mm_add_ps(x, xmm2);
    x = _mm_add_ps(x, xmm3);

    emm4 = _mm_sub_epi32(emm4, cast(v4si)_pi32_2);
    emm4 = _mm_andnot_si128(emm4, cast(v4si)_pi32_4);
    emm4 = _mm_slli_epi32(emm4, 29);
    v4sf sign_bit_cos = _mm_castsi128_ps(emm4);

    sign_bit_sin = _mm_xor_ps(sign_bit_sin, swap_sign_bit_sin);


    /* Evaluate the first polynom  (0 <= x <= Pi/4) */
    v4sf z = _mm_mul_ps(x,x);
    y = _ps_coscof_p0;

    y = _mm_mul_ps(y, z);
    y = _mm_add_ps(y, _ps_coscof_p1);
    y = _mm_mul_ps(y, z);
    y = _mm_add_ps(y, _ps_coscof_p2);
    y = _mm_mul_ps(y, z);
    y = _mm_mul_ps(y, z);
    v4sf tmp = _mm_mul_ps(z, _ps_0p5);
    y = _mm_sub_ps(y, tmp);
    y = _mm_add_ps(y, _ps_1);

    /* Evaluate the second polynom  (Pi/4 <= x <= 0) */

    v4sf y2 = _ps_sincof_p0;
    y2 = _mm_mul_ps(y2, z);
    y2 = _mm_add_ps(y2, _ps_sincof_p1);
    y2 = _mm_mul_ps(y2, z);
    y2 = _mm_add_ps(y2, _ps_sincof_p2);
    y2 = _mm_mul_ps(y2, z);
    y2 = _mm_mul_ps(y2, x);
    y2 = _mm_add_ps(y2, x);

    /* select the correct result from the two polynoms */  
    xmm3 = poly_mask;
    v4sf ysin2 = _mm_and_ps(xmm3, y2);
    v4sf ysin1 = _mm_andnot_ps(xmm3, y);
    y2 = _mm_sub_ps(y2,ysin2);
    y = _mm_sub_ps(y, ysin1);

    xmm1 = _mm_add_ps(ysin1,ysin2);
    xmm2 = _mm_add_ps(y,y2);

    /* update the sign */
    *s = _mm_xor_ps(xmm1, sign_bit_sin);
    *c = _mm_xor_ps(xmm2, sign_bit_cos);
}
