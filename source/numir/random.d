module numir.random;

import std.algorithm : fold;
import mir.random : unpredictableSeed, Random;
import mir.random.algorithm : range;
import mir.random.variable : UniformVariable, NormalVariable;
import mir.ndslice: slicedField, slice;


///
class RNG
{
    private static this() {}
    private __gshared Random* _rng = null;

    /// 
    @property static ref get()
    {
        if (!_rng)
        {
            synchronized(RNG.classinfo)
            {
                _rng = new Random(unpredictableSeed);
            }
        }
        return *_rng;
    }

    ///
    static auto field(V)(V var)
    {
        import mir.random.algorithm : field;
        return field(this.get, var);
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

/// general function for random slice generation with global RNG
auto generate(V, size_t N)(V var, size_t[N] length...)
{
    return RNG.field(var).slicedField(length);
}

///
auto normal(E=double, size_t N)(size_t[N] length...)
{
    return NormalVariable!E(0, 1).generate(length);
}

///
auto uniform(E=double, size_t N)(size_t[N] length...)
{
    return UniformVariable!E(0, 1).generate(length);
}

///
unittest
{
    import mir.ndslice : all;
    import std.algorithm : sum;
    import mir.random.variable : BernoulliVariable;
    auto bs = BernoulliVariable!double(0.25).generate(100).sum;
    assert(0 < bs && bs < 50, "maybe fail");

    // pre-defined random variables (normal and uniform)
    RNG.setSeed(1);
    auto r0 = normal(3, 4).slice;
    assert(r0.shape == [3, 4]);
    RNG.setSeed(0);
    auto r1 = normal(3, 4).slice;
    assert(r0 != r1);

    RNG.setSeed(0);
    auto r2 = normal(3, 4).slice;
    assert(r1 == r2);

    auto u = uniform(3, 4).slice;
    assert(u.shape == [3, 4]);
    assert(u.all!(a => (0 <= a && a < 1)));
}



/// generate a sequence as same as numir.core.arange but shuffled
auto permutation(T...)(T t) {
    import numir.core : arange;
    import mir.ndslice : slice;
    import mir.random.algorithm : shuffle;
    auto a = arange(t).slice;
    shuffle(RNG.get, a);
    return a;
}


///
unittest {
    import numir : arange;
    import mir.ndslice.sorting : sort;
    import numir.testing : approxEqual;
    import std.stdio;
    auto ps1 = permutation(100);
    auto ps2 = permutation(100);
    assert(ps1 != ps2, "maybe fail at 1%");
    assert(ps1.sort() == arange(100));

    auto ps3 = permutation(1, 10, 0.1);
    auto ps4 = permutation(1, 10, 0.1);
    assert(ps3 != ps4);
    assert(ps4.sort.approxEqual(arange(1, 10, 0.1)));
}
