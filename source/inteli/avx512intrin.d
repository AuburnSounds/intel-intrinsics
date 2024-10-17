// It's a little difficult to blanket classify AVX512 like this, but for the sake of
// not requiring a bajillion different imports I think this is good.

// I do decree that as it be willed such that AVX512 masks and 512-bit vectors nay yet
// have a form, this here shall pertain only to such instructions that are not of the 
// "unimplemented" nature in that, most unequivocably, they types which they do relate
// are yet to be capable of such interactions as are necessary.
module inteli.avx512intrin;

public import inteli.vpopcntdqintrin;