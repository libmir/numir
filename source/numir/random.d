module numir.random;

import std.algorithm : fold;
import mir.random : unpredictableSeed, Random;
import mir.random.algorithm : range;
import mir.random.variable : UniformVariable, NormalVariable;
import mir.ndslice: slicedField, slice;
import mir.random.algorithm: field;


///
class RNG
{
    private static this() {}
    private __gshared Random* _rng = null;

    ///
    static auto get(V)(V var)
    {
        if (!_rng)
        {
            synchronized(RNG.classinfo)
            {
                _rng = new Random(unpredictableSeed);
            }
        }
        return field(*_rng, var);
    }

    ///
    static void setSeed(uint seed)
    {
        _rng = new Random(seed);
    }
}


/* 
// FIXME: this test won't finish
unittest
{
    import std.parallelism;
    import std.range;
    import std.stdio;

    auto pool = new TaskPool();

    RNG.setSeed(1);
    foreach (i, p; iota(4).parallel)
    {
        uniform(3).writeln;
    }
}
*/

///
auto generate(V, size_t N)(V var, size_t[N] length...)
{
    return RNG.get(var)
        .slicedField(length).slice;
}

///
auto normal(E=double, size_t N)(size_t[N] length...)
{
    auto var = NormalVariable!E(0, 1);
    return generate(var, length);
}

///
auto uniform(E=double, size_t N)(size_t[N] length...)
{
    auto var = UniformVariable!E(0, 1);
    return generate(var, length);
}

///
bool approxEqual(double eps=1e-10, S1, S2)(S1 s1, S2 s2)
{
    import mir.ndslice : equal;
    import std.math : abs;
    assert(s1.shape == s2.shape);
    return equal!((a, b) => abs(a - b) < eps)(s1, s2);
}

///
unittest
{
    import mir.ndslice : all;

    auto r0 = normal(3, 4);
    assert(r0.shape == [3, 4]);
    RNG.setSeed(0);
    auto r1 = normal(3, 4);
    assert(r0 != r1);

    RNG.setSeed(0);
    auto r2 = normal(3, 4);
    assert(r1 == r2);
    assert(approxEqual(r1, r2));

    auto u = uniform(3, 4);
    assert(u.shape == [3, 4]);
    assert(u.all!(a => (0 <= a && a < 1)));
}
