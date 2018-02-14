module numir.stats;

import std.traits : isUnsigned;
import mir.ndslice : sliced, DeepElementType, each, isSlice;
import numir.core : zeros, nparray, resize;

/++
Count number of occurrences of each value in slice of non-negative ints.

Params:
    xs = input slice
    minlength = a minimum number of bins for the output array

Returns:
    size_t slice of number of ocurrence
 +/
auto bincount(T)(T xs, size_t minlength=0) pure if (isUnsigned!(typeof(xs.front)) && isSlice!T) {
    auto ret = zeros!size_t(minlength);
    auto maxx = minlength;
    xs.each!((x) {
        if (ret.length < x+1) {
            maxx = x+1;
            ret = ret.resize(x+1);
        }
        ret[x] += 1;
    });
    return ret[0 .. maxx];
}

/++
Count weighted number of occurrences of each value in slice of non-negative ints.
Note that empty weight causes compiler error.

Params:
    xs = input slice
    weights = weights slice of the same length as `xs`
    minlength = a minimum number of bins for the output array

Returns:
    slice like weights of weighted number of ocurrences
 +/
auto bincount(T, W)(T xs, W weights, size_t minlength=0) pure if (isUnsigned!(typeof(xs.front)) && isSlice!T  && isSlice!W)
in { assert(xs.length == weights.length); }
do {
    alias D = DeepElementType!(typeof(weights));
    auto wsh = weights.shape;
    wsh[0] = minlength;
    auto ret = zeros!D(wsh);
    size_t maxx = 0;
    // TODO use mir.ndslice.algorithm.each
    for (size_t i = 0; i < xs.length; ++i) {
        auto x = xs[i];
        if (ret.length < x+1) {
            maxx = x+1;
            ret = ret.resize(x+1);
        }
        ret[x][] += weights[i];
    }
    return ret[0 .. maxx];
}

///
unittest {
    import numir;

    auto ys = [0, 1, 1, 0, 1].sliced!size_t;
    assert(ys.bincount == [2, 3]);
    assert(ys.bincount([[1, 0], [-1, 0], [-1, 0], [1, 0], [-1, 0]].nparray) == [[2, 0], [-3,0]]);
    assert([].sliced!size_t.bincount == [].sliced!size_t);
    // FIXME
    // assert([].sliced!size_t.bincount([].sliced!double) == [].sliced!double);
}
