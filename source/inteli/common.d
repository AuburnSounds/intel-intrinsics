/**
* Common definitions.
* https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#techs=SSE
* 
* Copyright: Copyright Guillaume Piolat 2016-2020.
* Copyright: Copyright Kitsunebi Games 2025.
* License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module inteli.common;

version(Have_nurt) {
    import numem.core.hooks : nu_malloc, nu_free, nu_memcpy;
    public import core.internal.exception : onOutOfMemoryError;

    alias malloc = nu_malloc;
    alias free = nu_free;
    alias memcpy = nu_memcpy;
} else {
    public import core.stdc.stdlib: malloc, free;
    public import core.stdc.string: memcpy;
    public import core.exception: onOutOfMemoryError;
}

void __warn_noop(string fname = __FUNCTION__)() {
    pragma(msg, "Warning: ", fname, " is currently not supported, it will become a NO-OP!");
}

RetT __warn_noop_ret(RetT, string fname = __FUNCTION__)(RetT rval = RetT.init) if (!is(RetT == void)) {
    pragma(msg, "Warning: ", fname, " is currently not supported, it will become a NO-OP!");
    return rval;
}