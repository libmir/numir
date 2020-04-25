/++
Various statistics functions on ndslice. (e.g., bincount, var, logsumexp)
 +/
module numir.stats;

import std.traits : isUnsigned, isIntegral, isFloatingPoint, isBoolean;
import std.meta : allSatisfy, anySatisfy;

import mir.ndslice.slice : isSlice, Slice, SliceKind;
import mir.primitives : DimensionCount, elementCount;

// version = test_deprecated;

/// bincountable type is a one-dimentional slice with unsigned elements
enum isBincountable(T) = isUnsigned!(typeof(T.init.front)) && isSlice!T;

/++
Count number of occurrences of each value in slice of non-negative ints.
Params:
    xs = input slice
    minlength = a minimum number of bins for the output array
Returns:
    size_t slice of number of ocurrence
TODO:
    support @nogc
 +/
pure nothrow @safe
auto bincount(T)(T xs, size_t minlength=0) if (isBincountable!T)
{
    import mir.algorithm.iteration : each, reduce;
    import numir.core : zeros, resize;

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
TODO:
    support @nogc
 +/
pure nothrow @safe
auto bincount(T, W)(T xs, W weights, size_t minlength=0) if (isBincountable!T && isSlice!W)
in
{
    assert(xs.length == weights.length);
}
do
{
    import numir.core : zeros, resize;
    import mir.ndslice.slice : DeepElementType;

    alias D = DeepElementType!(typeof(weights));
    auto wsh = weights.shape;
    wsh[0] = minlength;
    auto ret = zeros!D(wsh);
    size_t maxx = 0;
    // TODO use mir.algorithm.iteration.each
    foreach (i; 0 .. xs.length) {
        auto x = xs[i];
        if (ret.length < x+1) {
            maxx = x+1;
            ret = ret.resize(x+1);
        }
        static if (DimensionCount!W == 1)
        {
            ret[x] += weights[i];
        }
        else
        {
            ret[x][] += weights[i];
        }
    }
    return ret[0 .. maxx];
}

///
pure @safe
unittest
{
    import numir : bincount;
    import mir.ndslice : sliced, iota, fuse;

    auto ys = [0, 1, 1, 0, 1].sliced!size_t;
    assert(ys.bincount == [2, 3]);
    assert(ys.bincount(iota(ys.length)) == [0+3, 1+2+4]);
    assert(ys.bincount([[1, 0], [-1, 0], [-1, 0], [1, 0], [-1, 0]].fuse) == [[2, 0], [-3,0]]);
    assert([].sliced!size_t.bincount == [].sliced!size_t);
    assert([].sliced!size_t.bincount([].sliced!double) == [].sliced!double);
}


/+
Computes the median of a slice. Internally, this function allocates copy of x to sort.

Params: x = input slice

Returns: a median value if x.length is the odd number, otherwise mean of two median values

See_Also: https://docs.scipy.org/doc/numpy/reference/generated/numpy.median.html
 +/
pure nothrow @safe
auto median(S)(S x) if (isSlice!S)
in
{
    assert(x.length > 0);
}
do
{
    import std.algorithm.sorting : isSorted;
    import std.traits : Unqual;
    import mir.ndslice.slice : DeepElementType;
    import mir.ndslice.allocation : slice;
    import mir.ndslice.sorting : sort;
    import numir.core : empty;

    immutable i = x.length / 2;
    if (x.isSorted)
 {
        return x.length % 2 == 1 ? x[i]
            : 0.5 * (x[i-1] + x[i]);
    }
    alias R = Unqual!(DeepElementType!S);
    auto s = empty!R(x.shape);
    s[] = x;
    s.sort;

    return x.length % 2 == 1 ? s[i]
        : 0.5 * (s[i-1] + s[i]);
}

///
pure nothrow @safe
unittest
{
    import mir.ndslice : map, alongDim, byDim, iota, slice, sliced;

    // sorted cases
    assert(iota(5).median == 2);
    // [[0,1],
    //  [2,3],
    //  [4,5]]
    assert(iota(3, 2).byDim!1.map!median == [2, 3]);
    assert(iota(3, 2).byDim!0.map!median == [0.5, 2.5, 4.5]);

    assert(iota(3, 2).alongDim!0.map!median == [2, 3]);
    assert(iota(3, 2).alongDim!1.map!median == [0.5, 2.5, 4.5]);

    // not sorted cases
    auto x = [1, 5, 1, 3, 4].sliced;
    assert(x.median == 3);
    auto y = [1, 5, 1, 3, 4, 4].sliced;
    assert(y.median == 3.5);

    auto z = [1, 5, 1, 2, 4, 2,
              1, 5, 1, 2, 4, 3,
              1, 5, 1, 3, 4, 3].sliced(3, 6);

    assert(z.byDim!1.map!median == [1, 5, 1, 2, 4, 3]);
    assert(z.byDim!0.map!median.slice == [2.0, 2.5, 3.0]); // FIXME remove .slice here

    assert(z.alongDim!0.map!median == [1, 5, 1, 2, 4, 3]);
    assert(z.alongDim!1.map!median == [2.0, 2.5, 3.0]);
}


nothrow @nogc: // everything bellow here is nothrow and @nogc.

deprecated("use `import mir.math.stat: mean;`")
nothrow @nogc template mean(sumTemplateArgs ...)
{
    import mir.ndslice.topology : as;
    import mir.math.sum : sum;

    /++
    Params:
        slice = input slice
    Returns:
        mean of slice
    +/
    auto mean(S)(S slice) if (isSlice!S)
    {
        return slice.sum!(sumTemplateArgs) / slice.elementCount;
    }

    deprecated // twice
    auto mean(S, Seed)(S slice, Seed seed) if (isSlice!S)
    {
        return slice.sum!(sumTemplateArgs)(seed) / slice.elementCount;
    }
}

// maybe not need
deprecated("use `import mir.math.stat: mean;`")
auto mean(S)(S slice) if (isSlice!S)
{
    return slice.mean!"appropriate";
}

// maybe not need
deprecated("use `import mir.math.stat: mean;`")
auto mean(S, Seed)(S slice, Seed seed) if (isSlice!S)
{
    return slice.mean!"appropriate"(seed);
}


version(test_deprecated)
@nogc pure nothrow
unittest
{
    import mir.ndslice.slice : sliced;

    static immutable x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                          2.0, 7.5, 5.0, 1.0, 1.5, 0.0];
    assert(x.sliced.mean == 29.25 / 12);
}

version(test_deprecated)
@nogc pure nothrow
unittest
{
    import mir.ndslice.slice : sliced;

    static immutable x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                          2.0, 7.5, 5.0, 1.0, 1.5, 0.0];
    assert(x.sliced(2, 6).mean == 29.25 / 12);
}

version(test_deprecated)
@nogc pure nothrow
unittest
{
    import mir.ndslice.slice : sliced;
    import mir.ndslice.topology : alongDim, byDim, map;

    static immutable x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                          2.0, 7.5, 5.0, 1.0, 1.5, 0.0];
    static immutable result = [1, 4.25, 3.25, 1.5, 2.5, 2.125];

    // Use byDim or alongDim with map to compute mean of row/column.
    assert(x.sliced(2, 6).byDim!1.map!mean == result);
    assert(x.sliced(2, 6).alongDim!0.map!mean == result);

    // FIXME
    // Without using map, computes the mean of the whole slice
    // assert(x.sliced(2, 6).byDim!1.mean == x.sliced.mean);
    // assert(x.sliced(2, 6).alongDim!0.mean == x.sliced.mean);
}

version(test_deprecated)
@nogc nothrow
unittest
{
    import mir.ndslice.slice: sliced;
    import mir.ndslice.topology: map, repeat;

    //Set sum algorithm or output type
    static immutable a = [1, 1e100, 1, -1e100];
    auto x = a.sliced * 10_000;
    assert(x.mean!"kbn" == 20_000 / 4);
    assert(x.mean!"kb2" == 20_000 / 4);
    assert(x.mean!"precise" == 20_000 / 4);
    assert(x.mean!(double, "precise") == 20_000.0 / 4);

    //Provide a seed
    auto y = uint.max.repeat(3);
    assert(y.mean(ulong.init) == 12884901885 / 3);
}

version(test_deprecated)
@nogc pure nothrow
unittest
{
    import mir.ndslice.slice : sliced;
    import std.math : approxEqual;

    static immutable x = [0, 1, 1, 2, 4, 4,
                          2, 7, 5, 1, 2, 0];
    assert(approxEqual(x.sliced.mean!double, 29.0 / 12, 1.0e-10));
}

version(test_deprecated)
@nogc pure nothrow
unittest
{
    import mir.ndslice.slice : sliced;

    static immutable cdouble[] x = [1.0 + 2i, 2 + 3i, 3 + 4i, 4 + 5i];
    static immutable cdouble result = 2.5 + 3.5i;
    assert(x.sliced.mean == result);
}


version(test_deprecated)
nothrow pure @safe @nogc
unittest
{
    import numir : mean;
    import mir.ndslice : alongDim, iota, as, map;
    /*
      [[0,1,2],
       [3,4,5]]
     */
    auto x = iota(2, 3).as!double;
    assert(x.mean == (5.0 / 2.0));

    static immutable m0 = [(0.0+3.0)/2.0, (1.0+4.0)/2.0, (2.0+5.0)/2.0];
    assert(x.alongDim!0.map!mean == m0);
    assert(x.alongDim!(-2).map!mean == m0);

    static immutable m1 = [(0.0+1.0+2.0)/3.0, (3.0+4.0+5.0)/3.0];
    assert(x.alongDim!1.map!mean == m1);
    assert(x.alongDim!(-1).map!mean == m1);

    assert(iota(2, 3, 4, 5).as!double.alongDim!0.map!mean == iota([3, 4, 5], 3 * 4 * 5 / 2));
}


/++
Computes the geometric mean of a slice.
The product in gmean is computed in logarithms to avoid FP overflows.

Params:
    slice = input slice
Returns:
    geometric mean of slice

See_Also:
    @9il comment https://github.com/libmir/numir/pull/24#discussion_r168958617
 +/
pure nothrow @safe @nogc
auto gmean(S)(S slice) if (isSlice!S)
{
    import mir.algorithm.iteration : each;
    import mir.ndslice.slice : DeepElementType;
    import mir.math.numeric : Prod;
    import mir.math.common : exp2, pow;
    import std.math : ldexp;
    import std.traits : Unqual;
    alias D = Unqual!(DeepElementType!(typeof(slice)));

    Prod!D pr;
    slice.each!(e => pr.put(e));
    auto y = cast(D) 1.0 / slice.elementCount;
    auto z = y * pr.exp;
    auto ep = cast(int) z;
    auto ma = pr.x.pow(y) * exp2(z - ep);
    return ldexp(ma, ep);
    /*
      (pr.x * 2 ^^ pr.exp) ^^ y
      = 2 ^^ (y * (log2(pr.x) + pr.exp))
      = pr.x ^^ y * 2 ^^ z
      = (pr.x ^^ y * 2 ^^ (z - floor(z))) * 2 ^^ (floor(z))
     */
}

/++
Computes the geometric mean of a slice.

Params:
    slice = input slice
    seed = seed used to calculate product (should be 1 in most cases)
Returns:
    geometric mean of slice
+/
pure nothrow @safe @nogc
auto gmean(S, Seed)(S slice, Seed seed) if (isSlice!S)
{
    import mir.algorithm.iteration : each;
    import mir.ndslice.slice : DeepElementType;
    import mir.math.numeric : Prod;
    import mir.math.common : exp2, pow;
    import std.math : ldexp;
    import std.traits : Unqual;

    import std.bitmanip : DoubleRep;
    DoubleRep rep;
    rep.value = seed;
    Prod!Seed pr;
    pr.exp = rep.exponent;
    rep.exponent = 1;
    pr.x = rep.value * 0.5;
    slice.each!(e => pr.put(e));
    auto y = cast(Seed) 1.0 / slice.elementCount;
    auto z = y * pr.exp;
    auto ep = cast(int) z;
    auto ma = pr.x.pow(y) * exp2(z - ep);
    return ldexp(ma, ep);
    /*
      (seed * pr.x * 2 ^^ pr.exp) ^^ y
      = 2 ^^ (y * (log2(seed * pr.x) + pr.exp))
      = pr.x ^^ y * 2 ^^ z
      = (pr.x ^^ y * 2 ^^ (z - floor(z))) * 2 ^^ (floor(z))
     */
}

/// Geometric mean of vector
pure nothrow @safe @nogc
unittest
{
    import mir.ndslice.slice : sliced;
    import std.math : approxEqual;

    static immutable x = [1.1, 0.99, 1.01, 1.2, 0.9, 1.05];

    auto y = x.sliced.gmean;
    assert(approxEqual(y, 1.037513));
}

/// Geometric mean of matrix
pure nothrow @safe @nogc
unittest
{
    import mir.ndslice.slice : sliced;
    import std.math : approxEqual;

    static immutable x = [1.1, 0.99, 1.01, 1.2, 0.9, 1.05];

    auto y = x.sliced(2, 3).gmean;
    assert(approxEqual(y, 1.037513));
}

/// Column geometric mean of matrix
pure nothrow @safe @nogc
unittest
{
    import mir.ndslice.slice : sliced;
    import mir.ndslice.topology : alongDim, byDim, map;
    import numir : approxEqual;

    static immutable x = [1.1, 0.99, 1.01, 1.2, 0.9, 1.05];
    static immutable y = [1.148913, 0.943928, 1.029806];
    // Use byDim or alongDim with map to compute mean of row/column.
    assert(approxEqual(x.sliced(2, 3).byDim!1.map!gmean, y.sliced));
    assert(approxEqual(x.sliced(2, 3).alongDim!0.map!gmean, y.sliced));
}

/// Geometric mean of vector with seed
pure nothrow @safe @nogc
unittest
{
    import mir.ndslice.slice : sliced;
    import std.math : approxEqual;

    enum l = 2.0 ^^ (double.max_exp - 1);
    enum s = 2.0 ^^ -(double.max_exp - 1);
    static immutable x = [l, l, l, s, s, s, 0.8 * 2.0 ^^ 10];

    real seed = 1;
    auto y = x.sliced.gmean(seed);
    assert(approxEqual(y, (0.8 * 2.0 ^^ 10) ^^ (1.0 / 7.0)));
}

/++
Computes the harmonic mean of a slice.

Params:
    sumTemplateArgs = template arguments to pass to mir.math.sum (to compute the
                      harmonic mean)

See_also: $(MATHREF sum, sum)
+/
nothrow @nogc template hmean(sumTemplateArgs...)
{
    import mir.ndslice.slice : DeepElementType;

    /++
    Params:
        slice = input slice
    Returns:
        harmonic mean of slice
    +/
    auto hmean(S)
                                           (S slice)
        if (isFloatingPoint!(DeepElementType!(S)))
    {
        import mir.math.stat: mean;
        return 1 / (1.0 / slice).mean!sumTemplateArgs;
    }

    deprecated
    auto hmean(S, Seed)
                                (S slice, Seed seed)
        if (isFloatingPoint!(DeepElementType!(S)))
    {
        import mir.math.stat: mean;
        return 1 / ((1.0 / slice).mean!(sumTemplateArgs) + seed);
    }
}

/// Harmonic mean of vector
pure nothrow @safe @nogc
unittest
{
    import mir.ndslice.slice : sliced;
    import std.math : approxEqual;

    static immutable x = [20.0, 100.0, 2000.0, 10.0, 5.0, 2.0];

    auto y = x.sliced.hmean;
    assert(approxEqual(y, 6.97269));
}

/// Harmonic mean of matrix
pure nothrow @safe @nogc
unittest
{
    import mir.ndslice.slice : sliced;
    import std.math : approxEqual;

    static immutable x = [20.0, 100.0, 2000.0, 10.0, 5.0, 2.0];

    auto y = x.sliced(2, 3).hmean;
    assert(approxEqual(y, 6.97269));
}

/// Column harmonic mean of matrix
pure nothrow @safe @nogc
unittest
{
    import mir.ndslice.slice : sliced;
    import mir.ndslice.topology : alongDim, byDim, map;
    import numir : approxEqual;

    static immutable _x = [20.0, 100.0, 2000.0, 10.0, 5.0, 2.0];
    auto x = _x.sliced(2, 3);
    static immutable _y = [13.33333, 9.52381, 3.996004];
    auto y = _y.sliced;

    // Use byDim or alongDim with map to compute mean of row/column.
    assert(approxEqual(x.byDim!1.map!hmean, y));
    assert(approxEqual(x.alongDim!0.map!hmean, y));
}

/// Can also pass arguments to hmean
nothrow @nogc
unittest
{
    import mir.ndslice.slice: sliced;
    import mir.ndslice.topology: map, repeat;
    import std.math : approxEqual;

    //Set sum algorithm or output type
    static immutable _x = [1, 1e100, 1, -1e100];
    auto x = _x.sliced * 10_000;
    assert(approxEqual(x.hmean!"kbn", 20_000));
    assert(approxEqual(x.hmean!"kb2", 20_000));
    assert(approxEqual(x.hmean!"precise", 20_000));
    assert(approxEqual(x.hmean!(double, "precise"), 20_000.0));
}

/++
Lazily centers a slice.

Params:
    sumTemplateArgs = template arguments to pass to mir.math.sum (to compute the
                      mean of the slice)

See_also: $(MATHREF sum, sum)
+/
nothrow pure @nogc template center(sumTemplateArgs...)
{
    /++
    Params:
        slice = input slice
    Returns:
        centered slice
    +/
    auto center(S)(S slice) if (isSlice!S)
    {
        import mir.math.stat: mean;
        return slice - slice.mean!(sumTemplateArgs);
    }

    deprecated
    auto center(S, Seed)(S slice, Seed seed) if (isSlice!S)
    {
        import mir.math.stat: mean;
        return slice - (slice.mean!(sumTemplateArgs) + seed);
    }
}

/// Center vector
pure nothrow @nogc
unittest
{
    import mir.ndslice.slice : sliced;

    static immutable x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                          2.0, 7.5, 5.0, 1.0, 1.5, 0.0];
    static immutable result = [-2.4375, -1.4375, -0.9375, -0.4375,  1.0625,  1.8125,
                               -0.4375,  5.0625,  2.5625, -1.4375, -0.9375, -2.4375];
    assert(x.sliced.center == result.sliced);
}

/// Center matrix
pure nothrow @nogc
unittest
{
    import mir.ndslice.slice : sliced;

    static immutable x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                          2.0, 7.5, 5.0, 1.0, 1.5, 0.0];
    static immutable result = [-2.4375, -1.4375, -0.9375, -0.4375,  1.0625,  1.8125,
                               -0.4375,  5.0625,  2.5625, -1.4375, -0.9375, -2.4375];
    assert(x.sliced(2, 6).center == result.sliced(2, 6));
}

/++
Lazily centers a slice and then takes each value to a power.

Params:
    sumTemplateArgs = template arguments to pass to mir.math.sum (to compute the
                      mean of the slice)

See_also: $(MATHREF sum, sum)
+/
pure nothrow @nogc private template deviationsPow(sumTemplateArgs...)
{
    import std.traits;
    /++
    Params:
        slice = input slice
        order = order of power
    Returns:
        centered slice with each each value taken to power
    +/
    auto deviationsPow(S, Order)
        (S slice, in Order order) if (isSlice!S)
    {
        import mir.math.stat: mean;
        return (slice - slice.mean!(sumTemplateArgs)) ^^ order;
    }

    deprecated
    auto deviationsPow(S, Order, Seed)
        (S slice, in Order order, Seed seed) if (isSlice!S)
    {
        import mir.math.stat: mean;
        return (slice - (slice.mean!(sumTemplateArgs) + seed)) ^^ order;
    }
}

/// Squared deviations of vector
pure nothrow @nogc
unittest
{
    import mir.ndslice.slice : sliced;
    import std.math : approxEqual;

    static immutable x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                          2.0, 7.5, 5.0, 1.0, 1.5, 0.0];
    static immutable result = [5.941406, 2.066406, 0.878906, 0.191406, 1.128906, 3.285156,
                               0.191406, 25.62891, 6.566406, 2.066406, 0.878906, 5.941406];

    // FIXME 2.0 -> 2 gives error
    assert(approxEqual(x.sliced.deviationsPow(2.0), result.sliced));
}

/// Squared deviations of matrix
pure nothrow @nogc
unittest
{
    import mir.ndslice.slice : sliced;
    import std.math : approxEqual;

    static immutable x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                          2.0, 7.5, 5.0, 1.0, 1.5, 0.0];
    static immutable _result = [5.941406, 2.066406, 0.878906, 0.191406, 1.128906, 3.285156,
                                0.191406, 25.62891, 6.566406, 2.066406, 0.878906, 5.941406];
    auto result = _result.sliced(2, 6);

    auto y = x.sliced(2, 6).deviationsPow(2);

    assert(approxEqual(y[0], result[0]));
    assert(approxEqual(y[1], result[1]));
}

/++
Computes the n-th central moment of a slice.

Params:
    sumTemplateArgs = template arguments to pass to mir.math.sum (to compute the
                      mean of the slice and the relevant moment)

See_also: $(MATHREF sum, sum)
+/
pure nothrow @nogc template moment(sumTemplateArgs...)
{
    /++
    Params:
        slice = input slice
        order = order of moment
    Returns:
        n-th central moment of slice
    +/
    auto moment(S, Order)
        (S slice, in Order order) if (isSlice!S)
    {
        import mir.math.stat: mean;
        return ((slice - slice.mean!sumTemplateArgs) ^^ order).mean!sumTemplateArgs;
    }

    deprecated
    auto moment(S, Order, Seed)
        (S slice,  in Order order, Seed seed) if (isSlice!S)
    {
        import mir.math.stat: mean;
        immutable(size_t) sliceSize = slice.size;
        Seed seedMoment = seed; //so as to not re-use seed below
        return ((slice - (slice.mean!sumTemplateArgs + seed)) ^^ order)
            .mean!sumTemplateArgs(seedMoment);
    }
}

/// 2nd central moment of vector
pure nothrow @nogc
unittest
{
    import std.math : approxEqual;
    import mir.ndslice.slice : sliced;

    static immutable x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                          2.0, 7.5, 5.0, 1.0, 1.5, 0.0];

    // FIXME assert(approxEqual(x.sliced.moment(2), 54.76563 / 12));
    assert(approxEqual(x.sliced.moment(2.0), 54.76563 / 12));
}

/// 2nd central moment of matrix
pure nothrow @nogc
unittest
{
    import mir.ndslice.slice : sliced;
    import std.math : approxEqual;

    static immutable x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                          2.0, 7.5, 5.0, 1.0, 1.5, 0.0];

    assert(approxEqual(x.sliced(2, 6).moment(2.0), 54.76563 / 12));
}

/// Row 2nd central moment of matrix
pure nothrow @safe @nogc
unittest
{
    import mir.ndslice.slice : sliced;
    import mir.ndslice.topology : byDim, alongDim, map;
    import std.math : approxEqual;

    static immutable x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                          2.0, 7.5, 5.0, 1.0, 1.5, 0.0];
    static immutable y = [2.092014, 6.722222];

    // Use byDim or alongDim with map to compute moment of row/column.
    assert(approxEqual(x.sliced(2, 6).byDim!0.map!(a => a.moment(2.0)), y.sliced));
    assert(approxEqual(x.sliced(2, 6).alongDim!1.map!(a => a.moment(2.0)), y.sliced));
}

/++
Computes the variance of a slice.

Params:
    sumTemplateArgs = template arguments to pass to mir.math.sum (to compute the
                      mean & variance of the slice)

TODO:
    merge fast implementation in https://github.com/libmir/numir/pull/22#issuecomment-366526194

See_also: $(MATHREF sum, sum)
+/
pure nothrow @nogc template var(sumTemplateArgs...)
{
    /++
    Params:
        slice = input slice
        isPopulation = true (default) if computing population variance, false otherwise
    Returns:
        variance of slice
    +/
    auto var(S)(S slice, bool isPopulation = true) if (isSlice!S)
    {
        import mir.math.stat: mean;
        size_t sliceSize = slice.elementCount;
        auto v = ((slice - slice.mean!sumTemplateArgs) ^^ 2.0).mean!sumTemplateArgs;
        if (!isPopulation) { v *= cast(double) sliceSize / (sliceSize - 1); }
        return v;
    }

    deprecated
    auto var(S, Seed)(S slice, Seed seed, bool isPopulation = true) if (isSlice!S)
    {
        size_t sliceSize = slice.elementCount;
        auto v = ((slice - (slice.mean!sumTemplateArgs + seed)) ^^ 2.0).mean!sumTemplateArgs;
        if (!isPopulation) { v *= cast(double) sliceSize / (sliceSize - 1); }
        return v;
    }
}

/// Variance of vector
pure nothrow @nogc
unittest
{
    import std.math : approxEqual;
    import mir.ndslice.slice : sliced;

    static immutable x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                          2.0, 7.5, 5.0, 1.0, 1.5, 0.0];

    assert(approxEqual(x.sliced.var, 54.76563 / 12));
    assert(approxEqual(x.sliced.var(false), 54.76563 / 11));
    assert(approxEqual(x.sliced.var(true), 54.76563 / 12));
}

/// Variance of matrix
pure nothrow @nogc
unittest
{
    import mir.ndslice.slice : sliced;
    import std.math : approxEqual;

    static immutable x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                          2.0, 7.5, 5.0, 1.0, 1.5, 0.0];

    assert(approxEqual(x.sliced(2, 6).var, 54.76563 / 12));
    assert(approxEqual(x.sliced(2, 6).var(false), 54.76563 / 11));
    assert(approxEqual(x.sliced(2, 6).var(true), 54.76563 / 12));
}

/// Row variance of matrix
pure nothrow @safe @nogc
unittest
{
    import mir.ndslice.slice : sliced;
    import mir.ndslice.topology : alongDim, byDim, map;
    import numir : approxEqual;

    static immutable x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                          2.0, 7.5, 5.0, 1.0, 1.5, 0.0];
    static immutable y = [2.092014, 6.722222];

    // Use byDim or alongDim with map to compute variance of row/column.
    assert(approxEqual(x.sliced(2, 6).byDim!0.map!(a => a.var(true)), y.sliced));
    assert(approxEqual(x.sliced(2, 6).alongDim!1.map!(a => a.var(true)), y.sliced));
}

/// Compute variance tensors along specified dimention of tensors with the negative dim support
pure nothrow @safe @nogc
unittest
{
    import mir.ndslice : alongDim, iota, map, as;
    import numir : var;
    /*
      [[1, 2],
       [3, 4]]
     */
    auto x = iota([2, 2], 1).as!double;
    static immutable v0 = [1.0, 1.0];
    static immutable v1 = [0.25, 0.25];
    /*
      [[1, 2, 3],
       [4, 5, 6]]
     */
    auto y = iota([2, 3], 1).as!double;
    static immutable v2 = [2.25, 2.25, 2.25];
    // static foreach (faster; [true, false])
    {
        assert(x.alongDim!0.map!var == v0);
        assert(x.alongDim!(-2).map!var == v0);

        assert(x.alongDim!1.map!var == v1);
        assert(x.alongDim!(-1).map!var == v1);

        assert(y.alongDim!0.map!var == v2);
        assert(y.alongDim!(-2).map!var == v2);
    }
}

/++
Computes the standard deviation of a slice.

Params:

    sumTemplateArgs = template arguments to pass to mir.math.sum (to compute the
                      mean & variance of the slice)

See_also: $(MATHREF sum, sum)
+/
pure nothrow @nogc template std(sumTemplateArgs...)
{
    import mir.math.common : sqrt;

    /++
    Params:
        slice = input slice
        isPopulation = true (default) if computing population standard deviation, false
                       otherwise
    Returns:
        standard deviation of slice
    +/
    auto std(S)(S slice, bool isPopulation = true) if (isSlice!S)
    {
        return slice.var!(sumTemplateArgs)(isPopulation).sqrt;
    }

    deprecated
    auto std(S, Seed)(S slice, Seed seed, bool isPopulation = false) if (isSlice!S)
    {
        return slice.var!(sumTemplateArgs)(seed, isPopulation).sqrt;
    }
}

/// Standard deviation of vector
pure nothrow @nogc
unittest
{
    import std.math : approxEqual;
    import mir.ndslice.slice : sliced;
    import mir.math.common : sqrt;

    static immutable x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                          2.0, 7.5, 5.0, 1.0, 1.5, 0.0];

    assert(approxEqual(x.sliced.std, sqrt(54.76563 / 12)));
    assert(approxEqual(x.sliced.std(false), sqrt(54.76563 / 11)));
    assert(approxEqual(x.sliced.std(true), sqrt(54.76563 / 12)));
}

/// Standard deviation of matrix
pure nothrow @nogc
unittest
{
    import mir.ndslice.slice : sliced;
    import std.math : approxEqual;
    import mir.math.common : sqrt;

    static immutable x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                          2.0, 7.5, 5.0, 1.0, 1.5, 0.0];

    assert(approxEqual(x.sliced(2, 6).std, sqrt(54.76563 / 12)));
    assert(approxEqual(x.sliced(2, 6).std(false), sqrt(54.76563 / 11)));
    assert(approxEqual(x.sliced(2, 6).std(true), sqrt(54.76563 / 12)));
}

/// Row standard deviation of matrix
pure nothrow @safe @nogc
unittest
{
    import mir.ndslice.slice : sliced;
    import mir.ndslice.topology : alongDim, byDim, map;
    import mir.math.common : sqrt;
    import numir : approxEqual;

    static immutable x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                          2.0, 7.5, 5.0, 1.0, 1.5, 0.0];
    static immutable y = [sqrt(2.092014), sqrt(6.722222)];

    // Use byDim or alongDim or alongDim with map to compute variance of row/column.
    assert(approxEqual(x.sliced(2, 6).byDim!0.map!(a => a.std(true)), y.sliced));
    assert(approxEqual(x.sliced(2, 6).alongDim!1.map!(a => a.std(true)), y.sliced));
}

/++
Computes the zscore of a slice.

Params:
    sumTemplateArgs = template arguments to pass to mir.math.sum (to compute the
                      mean & standard deviation of the slice)

See_also: $(MATHREF sum, sum)
+/
pure nothrow @nogc template zscore(sumTemplateArgs...)
{
    import mir.math.sum : sum;
    import mir.math.common : sqrt;

    /++
    Params:
        slice = input slice
        isPopulation = true (default) if computing population standard
                       deviation, false otherwise
    Returns:
        zscore of slice
    +/
    auto zscore(S)(S slice, bool isPopulation = true) if (isSlice!S)
    {
        auto sliceSize = slice.elementCount;
        auto sliceCenter = slice - slice.sum!(sumTemplateArgs) / sliceSize;
        if (isPopulation == false) { sliceSize--; }
        auto sliceVar = (sliceCenter ^^ 2).sum!(sumTemplateArgs) / sliceSize;
        return sliceCenter / sliceVar.sqrt;
    }

    deprecated
    auto zscore(S, Seed)(S slice, Seed seed, bool isPopulation = true) if (isSlice!S)
    {
        size_t sliceSize = slice.elementCount;
        Seed seedVar = seed;        //so as to not re-use seed below
        auto sliceMean = slice.sum!(sumTemplateArgs)(seed) / sliceSize;
        auto sliceCenter = slice - sliceMean;
        if (isPopulation == false) { sliceSize--; }
        auto sliceVar = (sliceCenter ^^ 2).sum!(sumTemplateArgs)(seedVar) / sliceSize;
        return sliceCenter / sliceVar.sqrt;
    }
}

/// Z-score of vector
pure nothrow @nogc
unittest
{
    import mir.ndslice.slice : sliced;
    import std.math : approxEqual;

    static immutable x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                          2.0, 7.5, 5.0, 1.0, 1.5, 0.0];
    static immutable resultSample = [-1.09241, -0.64424, -0.42016, -0.19607, 0.47618, 0.812307,
                                     -0.19607, 2.268858, 1.148434, -0.64424, -0.42016, -1.09241];
    static immutable resultPop = [-1.14099, -0.67289, -0.43884, -0.20479, 0.497354, 0.848427,
                                  -0.20479, 2.369745, 1.199501, -0.67289, -0.43884, -1.14099];

    assert(approxEqual(x.sliced.zscore, resultPop.sliced));
    assert(approxEqual(x.sliced.zscore(false), resultSample.sliced));
    assert(approxEqual(x.sliced.zscore(true), resultPop.sliced));

}

/// Z-score of matrix
pure nothrow @nogc
unittest
{
    import mir.ndslice.slice : sliced;
    import std.math : approxEqual;

    static immutable x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                          2.0, 7.5, 5.0, 1.0, 1.5, 0.0];
    static immutable _resultSample = [-1.09241, -0.64424, -0.42016, -0.19607, 0.47618, 0.812307,
                                      -0.19607, 2.268858, 1.148434, -0.64424, -0.42016, -1.09241];
    auto resultSample = _resultSample.sliced(2, 6);
    static immutable _resultPop = [-1.14099, -0.67289, -0.43884, -0.20479, 0.497354, 0.848427,
                                   -0.20479, 2.369745, 1.199501, -0.67289, -0.43884, -1.14099];
    auto resultPop = _resultPop.sliced(2, 6);

    auto y1 = x.sliced(2, 6).zscore;
    assert(approxEqual(y1[0], resultPop[0]));
    assert(approxEqual(y1[1], resultPop[1]));

    auto y2 = x.sliced(2, 6).zscore(false);
    assert(approxEqual(y2[0], resultSample[0]));
    assert(approxEqual(y2[1], resultSample[1]));

    auto y3 = x.sliced(2, 6).zscore(true);
    assert(approxEqual(y3[0], resultPop[0]));
    assert(approxEqual(y3[1], resultPop[1]));
}


/++
Computes the log of the sum of exponentials of input elements.

Params:
    sumTemplateArgs = template arguments to pass to mir.math.sum (to compute the
                      mean & standard deviation of the slice)

See_also: https://github.com/scipy/scipy/blob/maintenance/1.0.x/scipy/special/_logsumexp.py
+/
nothrow @nogc template logsumexp(sumTemplateArgs...)
{
    import mir.algorithm.iteration : maxPos;
    import mir.ndslice.topology : map;
    import mir.math.common : exp, log;
    import mir.math.sum : sum;
    import mir.ndslice.slice : DeepElementType;
    import mir.algorithm.iteration : all;

    /++
    Params
        a = input slice

    Returns:
        log-sum-exp value. if `a` is empty, this function returns -inf as mir.math.sum([]) does too.
     +/
    auto logsumexp(A)(A a) if (isSlice!A)
    in
    {
        assert(a.all!"a >= 0");
    }
    do
    {
        if (a.elementCount == 0) return -DeepElementType!A.infinity;
        auto a_max = a.maxPos.first;
        auto tmp = map!exp(a - a_max);
        return tmp.sum!sumTemplateArgs.log + a_max;
    }

    /++
    Params
        a = input slice
        b = scaling factor slice for `exp(a)` must have the same shape to b
    Returns:
        log-sum-exp value. if `a` is empty, this function returns -inf as mir.math.sum([]) does too.
     +/
    auto logsumexp(A, B)(A a, B b) if (isSlice!A && isSlice!B)
    in
    {
        import numir.testing : assertShapeEqual;
        assert(a.all!"a >= 0");
        assertShapeEqual(a, b);
    }
    do
    {
        if (a.elementCount == 0) return -DeepElementType!A.infinity;
        auto a_max = a.maxPos.first;
        auto tmp = map!exp(a - a_max) * b;
        return tmp.sum!sumTemplateArgs.log + a_max;
    }
}

///
pure nothrow @nogc
unittest
{
    // logsumexp example from doctest https://github.com/scipy/scipy/blob/maintenance/1.0.x/scipy/special/_logsumexp.py
    import mir.ndslice : iota, map, sliced, as;
    import mir.math.common : log, exp;
    import mir.math.sum;
    import std.math : approxEqual;
    {
        auto x = iota(10).as!double;
        assert(logsumexp(x).approxEqual(9.4586297444267107));
        assert(log(sum(map!exp(x))).approxEqual(logsumexp(x)));
    }
    {
        auto x = iota(0).as!double;
        assert(sum(x) == 0);
        assert(logsumexp(x) == -double.infinity);
        assert(log(sum(map!exp(x))).approxEqual(logsumexp(x)));
    }
    {
        auto a = iota(10).as!double;
        auto b = iota([10], 10, -1).as!double;
        assert(logsumexp(a, b).approxEqual(9.9170178533034665));
        assert(log(sum(map!exp(a) * b)).approxEqual(logsumexp(a, b)));
    }
    {
        auto a = iota(0).as!double;
        auto b = iota(0).as!double;
        assert(logsumexp(a, b) == -double.infinity);
        assert(log(sum(map!exp(a) * b)).approxEqual(logsumexp(a, b)));
    }
}
