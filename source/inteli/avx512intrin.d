/**
* AVX512 intrinsics.
* https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#techs=AVX512
*
* Copyright: cet 2024.
* License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module inteli.avx512intrin;

// It's a little difficult to blanket classify AVX512 like this, but for the sake of
// not requiring a bajillion different imports I think this is good.

// I do decree that as it be willed such that AVX512 masks and 512-bit vectors nay yet
// have a form, this here shall pertain only to such instructions that are not of the 
// "unimplemented" nature in that, most unequivocably, they types which they do relate
// are yet to be capable of such interactions as are necessary.

public import inteli.vpopcntdqintrin;
public import inteli.vnniintrin;