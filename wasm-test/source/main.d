
import inteli.emmintrin;
import inteli.internals;
import core.stdc.stdio;


import std.typetuple;
import std.traits;
static import inteli.avx2intrin;
static import inteli.avxintrin;
static import inteli.bmi2intrin;
static import inteli.emmintrin;
static import inteli.internals;
static import inteli.math;
static import inteli.mmx;
static import inteli.nmmintrin;
static import inteli.pmmintrin;
static import inteli.shaintrin;
static import inteli.smmintrin;
static import inteli.tmmintrin;
static import inteli.types;
static import inteli.xmmintrin;
alias allModules = TypeTuple!(inteli.avx2intrin, 
    inteli.avxintrin, 
    inteli.bmi2intrin, 
    inteli.emmintrin, 
    inteli.internals, 
    inteli.math, 
    inteli.mmx, 
    inteli.nmmintrin, 
    inteli.pmmintrin, 
    inteli.shaintrin, 
    inteli.smmintrin, 
    inteli.tmmintrin, 
    inteli.types, 
    inteli.xmmintrin);

int main(string[] args)
{
    runUnittests();
    return 0;
}

void runUnittests()
{
    foreach(module_; allModules) 
    {
        enum modName = module_.stringof;
        printf("*** %.*s\n", cast(int)modName.length, modName.ptr);
        foreach(test; __traits(getUnitTests, module_)) 
        {
            enum string name = test.stringof;

            printf("%.*s :: ", cast(int)modName.length, modName.ptr);
            printf("%.*s", cast(int)name.length, name.ptr);
            fflush(stdout);
            test();
            printf(" -> OK\n");
        }
            //tests ~= Test(fullyQualifiedName!test, getTestName!test, getTestLocation!test, &test);
    }

    printf("All tests passed.\n");
}


