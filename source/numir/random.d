module numir.random;

import mir.random : unpredictableSeed, Random;
import mir.random.algorithm : range;
import mir.random.variable : Bernoulli2Variable, UniformVariable, NormalVariable;
import std.algorithm : fold;
import mir.ndslice: slicedField, slice;
import mir.random.algorithm: field;


///
class RNG
{
    private static this() {}
    private __gshared Random* _rng = null;

    ///
    static ref get()
    {
        synchronized(RNG.classinfo)
        {
            if (!_rng)
            {
                _rng = new Random(unpredictableSeed);
            }
        }
        return *_rng;
    }

    ///
    static ref setSeed(ulong seed)
    {
        synchronized(RNG.classinfo)
        {
            _rng = new Random(seed);
        }
        return *_rng;
    }
}


///
auto randn(E=double, size_t N)(size_t[N] length...)
{
    auto var = NormalVariable!double(0, 1);
    return RNG.get()
        .field(var)
        .slicedField(length);
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
    import std.stdio;

    auto r0 = randn(3, 4).slice;
    assert(r0.shape == [3, 4]);
    RNG.setSeed(0);
    auto r1 = randn(3, 4).slice;
    assert(r0 != r1);

    RNG.setSeed(0);
    auto r2 = randn(3, 4).slice;
    assert(r1 == r2);
    assert(approxEqual(r1, r2));
}
