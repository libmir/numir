module numir.stats;

import std.traits : isUnsigned, isIntegral, isFloatingPoint, isBoolean;
import mir.ndslice.slice : isSlice, Slice, SliceKind;
import mir.math.sum : Summation;
import std.meta : allSatisfy, anySatisfy;


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
pure auto bincount(T)(T xs, size_t minlength=0) if (isBincountable!T)
{
    import mir.ndslice.algorithm : each, reduce;
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
pure auto bincount(T, W)(T xs, W weights, size_t minlength=0) if (isBincountable!T && isSlice!W)
in
{
    assert(xs.length == weights.length);
}
do
{
    import numir.core : zeros, resize, Ndim;
    import mir.ndslice.slice : DeepElementType;

    alias D = DeepElementType!(typeof(weights));
    auto wsh = weights.shape;
    wsh[0] = minlength;
    auto ret = zeros!D(wsh);
    size_t maxx = 0;
    // TODO use mir.ndslice.algorithm.each
    foreach (i; 0 .. xs.length) {
        auto x = xs[i];
        if (ret.length < x+1) {
            maxx = x+1;
            ret = ret.resize(x+1);
        }
        static if (Ndim!W == 1)
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
    import numir : bincount, nparray;
    import mir.ndslice : sliced, iota;

    auto ys = [0, 1, 1, 0, 1].sliced!size_t;
    assert(ys.bincount == [2, 3]);
    assert(ys.bincount(iota(ys.length)) == [0+3, 1+2+4]);
    assert(ys.bincount([[1, 0], [-1, 0], [-1, 0], [1, 0], [-1, 0]].nparray) == [[2, 0], [-3,0]]);
    assert([].sliced!size_t.bincount == [].sliced!size_t);
    assert([].sliced!size_t.bincount([].sliced!double) == [].sliced!double);
}


/++
Computes the size of an unpacked slice.

Params:
    slice = input slice
Returns:
    size of unpacked slice
+/
pure @nogc size_t unpackedSize(SliceKind kind, size_t[] packs, Iterator)
                                           (Slice!(kind, packs, Iterator) slice)
{
    static if (packs.length == 1)
    {
        return slice.elementsCount;
    }
    else static if (packs.length > 1)
    {
        import mir.ndslice.topology : unpack;

        return slice.unpack.elementsCount;
    }
    else
    {
        static assert(0, "unpackedSize: Should not be here");
    }
}

///
@safe @nogc pure nothrow
unittest
{
    import mir.ndslice.slice : sliced;
    import mir.ndslice.topology : byDim;

    static immutable x = [0, 1, 2, 3];

    assert(x.sliced.unpackedSize == 4);
    assert(x.sliced(2, 2).unpackedSize == 4);
    assert(x.sliced.sliced(2, 2).byDim!0.unpackedSize == 4);
}

/++
Computes x ^ order.

Params:
    x = value
    order = order of power
Returns:
    x ^ order
+/
@safe @nogc pure nothrow
private T power(T)(T x, int order)
    if (isFloatingPoint!T)
{
    import mir.math.common : powi;

    return x.powi(order);
}

/++
Computes x ^ order.

Params:
    x = value
    order = order of power
Returns:
    x ^ order
+/
@safe @nogc pure nothrow
private T power(T)(T x, in T order)
    if (isFloatingPoint!T)
{
    import mir.math.common : pow;

    return x.pow(order);
}

///
unittest
{
    double x = 2.0;
    assert(x.power(3) == 8.0);
    assert(x.power(3.0) == 8.0);
}

/++
Computes the mean of a slice.

Params:
    sumTemplateArgs = template arguments to pass to mir.math.sum

See_also: $(MATHREF sum, sum)
+/
template mean(sumTemplateArgs...)
{
    import mir.ndslice.topology : as;
    import mir.math.sum : sum;
    @nogc:

    /++
    Params:
        slice = input slice
    Returns:
        mean of slice
    +/
    auto mean(SliceKind kind, size_t[] packs, Iterator)
                                           (Slice!(kind, packs, Iterator) slice)
    {
        return slice.sum!(sumTemplateArgs) / slice.unpackedSize;
    }

    /++
    Params:
        slice = input slice
        seed = seed used to calculate sum
    Returns:
        mean of slice
    +/
    auto mean(SliceKind kind, size_t[] packs, Iterator, Seed)
                                (Slice!(kind, packs, Iterator) slice, Seed seed)
    {
        return slice.sum!(sumTemplateArgs)(seed) / slice.unpackedSize;
    }
}


/// Mean of vector
@nogc pure nothrow
unittest
{
    import mir.ndslice.slice : sliced;

    static immutable x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                          2.0, 7.5, 5.0, 1.0, 1.5, 0.0];
    assert(x.sliced.mean == 29.25 / 12);
}

/// Mean of matrix
@nogc pure nothrow
unittest
{
    import mir.ndslice.slice : sliced;

    static immutable x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                          2.0, 7.5, 5.0, 1.0, 1.5, 0.0];
    assert(x.sliced(2, 6).mean == 29.25 / 12);
}

/// Column mean of matrix
unittest
{
    import mir.ndslice.slice : sliced;
    import mir.ndslice.topology : byDim, map;

    static immutable x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                          2.0, 7.5, 5.0, 1.0, 1.5, 0.0];
    static immutable result = [1, 4.25, 3.25, 1.5, 2.5, 2.125];

    // Use byDim with map to compute mean of row/column.
    auto y = x.sliced(2, 6).byDim!1.map!mean;
    assert(y == result);

    // Without using map, computes the mean of the whole slice
    assert(x.sliced(2, 6).byDim!1.mean == x.sliced.mean);
}

/// Can also pass arguments to sum
unittest
{
    import mir.ndslice.slice: sliced;
    import mir.ndslice.topology: map, repeat;

    //Set sum algorithm or output type
    auto x = [1, 1e100, 1, -1e100].sliced.map!"a * 10_000";
    assert(x.mean!"kbn" == 20_000 / 4);
    assert(x.mean!"kb2" == 20_000 / 4);
    assert(x.mean!"precise" == 20_000 / 4);
    assert(x.mean!(double, "precise") == 20_000.0 / 4);

    //Provide a seed
    auto y = uint.max.repeat(3);
    assert(y.mean(ulong.init) == 12884901885 / 3);
}

/// For integral slices, pass output type as template parameter to ensure output
/// type is correct
@nogc pure nothrow
unittest
{
    import mir.ndslice.slice : sliced;
    import std.math : approxEqual;

    static immutable x = [0, 1, 1, 2, 4, 4,
                          2, 7, 5, 1, 2, 0];
    assert(approxEqual(x.sliced.mean!double, 29.0 / 12, 1.0e-10));
}

/// Mean works for complex numbers (and other user-defined types)
@nogc pure unittest
{
    import mir.ndslice.slice : sliced;

    static immutable cdouble[] x = [1.0 + 2i, 2 + 3i, 3 + 4i, 4 + 5i];
    static immutable cdouble result = 2.5 + 3.5i;
    assert(x.sliced.mean == result);
}


/// Compute mean tensors along specified dimention of tensors
pure @safe @nogc
unittest
{
    import numir : mean, alongDim;
    import mir.ndslice : iota, as, map;
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
@nogc pure @safe
auto gmean(SliceKind kind, size_t[] packs, Iterator)
                                           (Slice!(kind, packs, Iterator) slice)
{
    import mir.ndslice.algorithm : each;
    import mir.ndslice.slice : DeepElementType;
    import mir.math.numeric : Prod;
    import mir.math.common : exp2, pow;
    import std.math : ldexp;
    alias D = DeepElementType!(typeof(slice));

    Prod!D pr;
    slice.each!(e => pr.put(e));
    auto y = cast(D) 1.0 / slice.unpackedSize;
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
@nogc pure @safe
auto gmean(SliceKind kind, size_t[] packs, Iterator, Seed)
                                (Slice!(kind, packs, Iterator) slice, Seed seed)
{
    return seed * slice.gmean;
}

/// Geometric mean of vector
pure nothrow @safe
unittest
{
    import mir.ndslice.slice : sliced;
    import std.math : approxEqual;

    auto x = [1.1, 0.99, 1.01, 1.2, 0.9, 1.05];

    auto y = x.sliced.gmean;
    assert(approxEqual(y, 1.037513));
}

/// Geometric mean of matrix
pure nothrow @safe
unittest
{
    import mir.ndslice.slice : sliced;
    import std.math : approxEqual;

    auto x = [1.1, 0.99, 1.01, 1.2, 0.9, 1.05];

    auto y = x.sliced(2, 3).gmean;
    assert(approxEqual(y, 1.037513));
}

/// Column geometric mean of matrix
pure nothrow @safe
unittest
{
    import mir.ndslice.slice : sliced;
    import mir.ndslice.topology : byDim, map;
    import std.math : approxEqual;

    auto x = [1.1, 0.99, 1.01, 1.2, 0.9, 1.05];

    // Use byDim with map to compute mean of row/column.
    auto y = x.sliced(2, 3).byDim!1.map!gmean;
    assert(approxEqual(y[0], 1.148913));
    assert(approxEqual(y[1], 0.943928));
    assert(approxEqual(y[2], 1.029806));
}

/// Geometric mean of vector with seed
pure @safe
unittest
{
    import mir.ndslice.slice : sliced;
    import std.math : approxEqual;

    enum l = 2.0 ^^ (double.max_exp - 1);
    enum s = 2.0 ^^ -(double.max_exp - 1);
    auto x = [l, l, l, s, s, s, 0.8 * 2.0 ^^ 10];

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
template hmean(sumTemplateArgs...)
{
    import mir.ndslice.topology : map;
    import mir.ndslice.slice : DeepElementType;

    /++
    Params:
        slice = input slice
    Returns:
        harmonic mean of slice
    +/
    auto hmean(SliceKind kind, size_t[] packs, Iterator)
                                           (Slice!(kind, packs, Iterator) slice)
        if (isFloatingPoint!(DeepElementType!(Slice!(kind, packs, Iterator))))
    {
        return 1 / (slice
                    .map!"1 / a"
                    .mean!sumTemplateArgs);
    }

    /++
    Params:
        slice = input slice
        seed = seed used to calculate sum (for harmonic mean)
    Returns:
        harmonic mean of slice
    +/
    auto hmean(SliceKind kind, size_t[] packs, Iterator, Seed)
                                (Slice!(kind, packs, Iterator) slice, Seed seed)
        if (isFloatingPoint!(DeepElementType!(Slice!(kind, packs, Iterator))))
    {
        return 1 / (slice
                        .map!(a => 1 / a)
                        .mean!(sumTemplateArgs)(seed));
    }
}

/// Harmonic mean of vector
pure nothrow @safe
unittest
{
    import mir.ndslice.slice : sliced;
    import std.math : approxEqual;

    auto x = [20.0, 100.0, 2000.0, 10.0, 5.0, 2.0];

    auto y = x.sliced.hmean;
    assert(approxEqual(y, 6.97269));
}

/// Harmonic mean of matrix
pure nothrow @safe
unittest
{
    import mir.ndslice.slice : sliced;
    import std.math : approxEqual;

    auto x = [20.0, 100.0, 2000.0, 10.0, 5.0, 2.0];

    auto y = x.sliced(2, 3).hmean;
    assert(approxEqual(y, 6.97269));
}

/// Column harmonic mean of matrix
pure nothrow @safe
unittest
{
    import mir.ndslice.slice : sliced;
    import mir.ndslice.topology : byDim, map;
    import std.math : approxEqual;

     auto x = [20.0, 100.0, 2000.0, 10.0, 5.0, 2.0];

    // Use byDim with map to compute mean of row/column.
    auto y = x.sliced(2, 3).byDim!1.map!hmean;
    assert(approxEqual(y[0], 13.33333));
    assert(approxEqual(y[1], 9.52381));
    assert(approxEqual(y[2], 3.996004));
}

/// Can also pass arguments to hmean
unittest
{
    import mir.ndslice.slice: sliced;
    import mir.ndslice.topology: map, repeat;
    import std.math : approxEqual;

    //Set sum algorithm or output type
    auto x = [1, 1e100, 1, -1e100].sliced.map!"a * 10_000";
    assert(approxEqual(x.hmean!"kbn", 20_000));
    assert(approxEqual(x.hmean!"kb2", 20_000));
    assert(approxEqual(x.hmean!"precise", 20_000));
    assert(approxEqual(x.hmean!(double, "precise"), 20_000.0));

    //Provide a seed
    auto y = float.max.repeat(3);
    double seed = 0.0;
    assert(approxEqual(y.hmean(seed), float.max));
}

/++
Lazily centers a slice.

Params:
    sumTemplateArgs = template arguments to pass to mir.math.sum (to compute the
                      mean of the slice)

See_also: $(MATHREF sum, sum)
+/
template center(sumTemplateArgs...)
{
    import mir.ndslice.topology : map;

    /++
    Params:
        slice = input slice
    Returns:
        centered slice
    +/
    auto center(SliceKind kind, size_t[] packs, Iterator)
                                          (Slice!(kind, packs, Iterator)  slice)
    {
        auto sliceMean = slice.mean!(sumTemplateArgs);

        return slice.map!(a => a - sliceMean);
    }

    /++
    Params:
        slice = input slice
        seed = seed used to calculate sum (for mean)
    Returns:
        centered slice
    +/
    auto center(SliceKind kind, size_t[] packs, Iterator, Seed)
                               (Slice!(kind, packs, Iterator)  slice, Seed seed)
    {
        auto sliceMean = slice.mean!(sumTemplateArgs)(seed);

        return slice.map!(a => a - sliceMean);
    }
}

/// Center vector
pure nothrow
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
pure nothrow
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
private template deviationsPow(sumTemplateArgs...)
{
    import mir.ndslice.topology : map;

    /++
    Params:
        slice = input slice
        order = order of power
    Returns:
        centered slice with each each value taken to power
    +/
    auto deviationsPow(SliceKind kind, size_t[] packs, Iterator, Order)
                           (Slice!(kind, packs, Iterator) slice, in Order order)
    {
        auto sliceMean = slice.mean!(sumTemplateArgs);

        return slice
                .map!(a => a - sliceMean)
                .map!(a => a.power(order));
    }

    /++
    Params:
        slice = input slice
        order = order of power
        seed = seed used to calculate sum (for mean)
    Returns:
        centered slice with each each value taken to power
    +/
    auto deviationsPow(SliceKind kind, size_t[] packs, Iterator, Order, Seed)
                (Slice!(kind, packs, Iterator) slice, in Order order, Seed seed)
    {
        auto sliceMean = slice.mean!(sumTemplateArgs)(seed);

        import mir.math.common : pow;

        return slice
                .map!(a => a - sliceMean)
                .map!(a => a.power(order));
    }
}

/// Squared deviations of vector
pure nothrow
unittest
{
    import mir.ndslice.slice : sliced;
    import std.math : approxEqual;

    static immutable x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                          2.0, 7.5, 5.0, 1.0, 1.5, 0.0];
    static immutable result = [5.941406, 2.066406, 0.878906, 0.191406, 1.128906, 3.285156,
                               0.191406, 25.62891, 6.566406, 2.066406, 0.878906, 5.941406];

    assert(approxEqual(x.sliced.deviationsPow(2), result.sliced));
}

/// Squared deviations of matrix
pure nothrow
unittest
{
    import mir.ndslice.slice : sliced;
    import std.math : approxEqual;

    static immutable x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                          2.0, 7.5, 5.0, 1.0, 1.5, 0.0];
    auto result = [5.941406, 2.066406, 0.878906, 0.191406, 1.128906, 3.285156,
                   0.191406, 25.62891, 6.566406, 2.066406, 0.878906, 5.941406].sliced(2, 6);

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
template moment(sumTemplateArgs...)
{
    import mir.math.sum : sum;
    import mir.ndslice.topology : map;

    /++
    Params:
        slice = input slice
        order = order of moment
    Returns:
        n-th central moment of slice
    +/
    auto moment(SliceKind kind, size_t[] packs, Iterator, Order)
                           (Slice!(kind, packs, Iterator) slice, in Order order)
    {
        immutable(size_t) sliceSize = slice.unpackedSize;
        auto sliceMean = slice.sum!(sumTemplateArgs) / sliceSize;

        return slice
                .map!(a => a - sliceMean)
                .map!(a => a.power(order))
                .sum!(sumTemplateArgs)
                / sliceSize;
    }

    /++
    Params:
        slice = input slice
        order = order of moment
        seed = seed used to calculate sum (for mean)
    Returns:
        n-th central moment of slice
    +/
    auto moment(SliceKind kind, size_t[] packs, Iterator, Order, Seed)
                (Slice!(kind, packs, Iterator) slice,  in Order order, Seed seed)
    {
        immutable(size_t) sliceSize = slice.size;
        Seed seedMoment = seed; //so as to not re-use seed below
        auto sliceMean = slice.sum!(sumTemplateArgs)(seed) / sliceSize;

        return slice
                .map!(a => a - sliceMean)
                .map!(a => a.power(order))
                .sum!(sumTemplateArgs)(seedMoment)
                / sliceSize;
    }
}

/// 2nd central moment of vector
pure nothrow
unittest
{
    import std.math : approxEqual;
    import mir.ndslice.slice : sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0];

    assert(approxEqual(x.sliced.moment(2), 54.76563 / 12));
    assert(approxEqual(x.sliced.moment(2.0), 54.76563 / 12));
}

/// 2nd central moment of matrix
pure nothrow
unittest
{
    import mir.ndslice.slice : sliced;
    import std.math : approxEqual;

    static immutable x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                          2.0, 7.5, 5.0, 1.0, 1.5, 0.0];

    assert(approxEqual(x.sliced(2, 6).moment(2.0), 54.76563 / 12));
}

/// Row 2nd central moment of matrix
pure nothrow @safe
unittest
{
    import mir.ndslice.slice : sliced;
    import mir.ndslice.topology : byDim, map;
    import std.math : approxEqual;

    static immutable x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                          2.0, 7.5, 5.0, 1.0, 1.5, 0.0];

    // Use byDim with map to compute moment of row/column.
    auto y = x.sliced(2, 6).byDim!0.map!(a => a.moment(2.0));
    assert(approxEqual(y[0], 2.092014));
    assert(approxEqual(y[1], 6.722222));
}

/++
Computes the variance of a slice.

Params:
    sumTemplateArgs = template arguments to pass to mir.math.sum (to compute the
                      mean & variance of the slice)

See_also: $(MATHREF sum, sum)
+/
template var(sumTemplateArgs...)
{
    import mir.math.sum : sum;
    import mir.ndslice.topology : map;
    pure @nogc:

    /++
    Params:
        slice = input slice
        isPopulation = true (default) if computing population variance, false otherwise
    Returns:
        variance of slice
    +/
    auto var(SliceKind kind, size_t[] packs, Iterator)
                                          (Slice!(kind, packs, Iterator) slice,
                                           bool isPopulation = true)
    {
        size_t sliceSize = slice.unpackedSize;
        auto v = ((slice - slice.mean!sumTemplateArgs) ^^ 2.0).mean!sumTemplateArgs;
        if (!isPopulation) { v *= cast(double) sliceSize / (sliceSize - 1); }
        return v;
    }

    /++
    Params:
        slice = input slice
        seed = seed used to calculate sum (for mean and variance)
        isPopulation = true (default) if computing population variance, false otherwise
    Returns:
        variance of slice
    +/
    auto var(SliceKind kind, size_t[] packs, Iterator, Seed)
                                (Slice!(kind, packs, Iterator) slice, Seed seed,
                                 bool isPopulation = true)
    {
        size_t sliceSize = slice.unpackedSize;
        auto v = ((slice - slice.mean!sumTemplateArgs) ^^ 2.0).mean!sumTemplateArgs;
        if (!isPopulation) { v *= cast(double) sliceSize / (sliceSize - 1); }
        return v;
    }
}

/// Variance of vector
pure nothrow
unittest
{
    import std.math : approxEqual;
    import mir.ndslice.slice : sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0];

    assert(approxEqual(x.sliced.var, 54.76563 / 12));
    assert(approxEqual(x.sliced.var(false), 54.76563 / 11));
    assert(approxEqual(x.sliced.var(true), 54.76563 / 12));
}

/// Variance of matrix
pure nothrow
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
pure nothrow @safe
unittest
{
    import mir.ndslice.slice : sliced;
    import mir.ndslice.topology : byDim, map;
    import std.math : approxEqual;

    static immutable x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                          2.0, 7.5, 5.0, 1.0, 1.5, 0.0];

    // Use byDim with map to compute variance of row/column.
    auto y = x.sliced(2, 6).byDim!0.map!(a => a.var(true));
    assert(approxEqual(y[0], 2.092014));
    assert(approxEqual(y[1], 6.722222));
}

/// Compute variance tensors along specified dimention of tensors
pure @safe // @nogc
unittest
{
    import mir.ndslice : iota, map, as;
    import numir : var, alongDim;
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
template std(sumTemplateArgs...)
{
    import mir.math.common : sqrt;

    /++
    Params:
        slice = input slice
        isPopulation = true if computing population standard deviation, false
                       otherwise (default)
    Returns:
        standard deviation of slice
    +/
    auto std(SliceKind kind, size_t[] packs, Iterator)
                                          (Slice!(kind, packs, Iterator) slice,
                                           bool isPopulation = false)
    {
        return slice.var!(sumTemplateArgs)(isPopulation).sqrt;
    }

    /++
    Params:
        slice = input slice
        seed = seed used to calculate sum (for mean and variance)
        isPopulation = true if computing population standard deviation, false
               otherwise (default)
    Returns:
        standard deviation of slice
    +/
    auto std(SliceKind kind, size_t[] packs, Iterator, Seed)
                                (Slice!(kind, packs, Iterator) slice, Seed seed,
                                 bool isPopulation = false)
    {
        return slice.var!(sumTemplateArgs)(seed, isPopulation).sqrt;
    }
}

/// Standard deviation of vector
pure nothrow
unittest
{
    import std.math : approxEqual;
    import mir.ndslice.slice : sliced;
    import mir.math.common : sqrt;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0];

    assert(approxEqual(x.sliced.std, sqrt(54.76563 / 11)));
    assert(approxEqual(x.sliced.std(false), sqrt(54.76563 / 11)));
    assert(approxEqual(x.sliced.std(true), sqrt(54.76563 / 12)));
}

/// Standard deviation of matrix
pure nothrow
unittest
{
    import mir.ndslice.slice : sliced;
    import std.math : approxEqual;
    import mir.math.common : sqrt;

    static immutable x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                          2.0, 7.5, 5.0, 1.0, 1.5, 0.0];

    assert(approxEqual(x.sliced(2, 6).std, sqrt(54.76563 / 11)));
    assert(approxEqual(x.sliced(2, 6).std(false), sqrt(54.76563 / 11)));
    assert(approxEqual(x.sliced(2, 6).std(true), sqrt(54.76563 / 12)));
}

/// Row standard deviation of matrix
pure nothrow @safe
unittest
{
    import mir.ndslice.slice : sliced;
    import mir.ndslice.topology : byDim, map;
    import std.math : approxEqual;
    import mir.math.common : sqrt;

    static immutable x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                          2.0, 7.5, 5.0, 1.0, 1.5, 0.0];

    // Use byDim with map to compute variance of row/column.
    auto y = x.sliced(2, 6).byDim!0.map!(a => a.std(true));
    assert(approxEqual(y[0], sqrt(2.092014)));
    assert(approxEqual(y[1], sqrt(6.722222)));
}

/++
Computes the zscore of a slice.

Params:
    sumTemplateArgs = template arguments to pass to mir.math.sum (to compute the
                      mean & standard deviation of the slice)

See_also: $(MATHREF sum, sum)
+/
template zscore(sumTemplateArgs...)
{
    import mir.math.sum : sum;
    import mir.math.common : sqrt;
    import mir.ndslice.topology : map;

    /++
    Params:
        slice = input slice
        isPopulation = true (default) if computing population standard
                       deviation, false otherwise
    Returns:
        zscore of slice
    +/
    auto zscore(SliceKind kind, size_t[] packs, Iterator)
                                           (Slice!(kind, packs, Iterator) slice,
                                            bool isPopulation = true)
    {
        auto sliceSize = slice.unpackedSize;
        auto sliceMean = slice.sum!(sumTemplateArgs) / sliceSize;
        auto sliceCenter = slice.map!(a => a - sliceMean);
        if (isPopulation == false)
            sliceSize--;
        auto sliceVar = sliceCenter
                            .map!(a => a.power(2))
                            .sum!(sumTemplateArgs)
                            / sliceSize;

        return sliceCenter
                .map!(a => a / sliceVar.sqrt);
    }

    /++
    Params:
        slice = input slice
        seed = seed used to calculate sum (for mean and standard deviation)
        isPopulation = true (default) if computing population standard
                       deviation, false otherwise
    Returns:
        zscore of slice
    +/
    auto zscore(SliceKind kind, size_t[] packs, Iterator, Seed)
                               (Slice!(kind, packs, Iterator) slice, Seed seed,
                                bool isPopulation = true)
    {
        size_t sliceSize = slice.unpackedSize;
        Seed seedVar = seed;        //so as to not re-use seed below
        auto sliceMean = slice.sum!(sumTemplateArgs)(seed) / sliceSize;
        auto sliceCenter = slice.map!(a => a - sliceMean);
        if (isPopulation == false)
            sliceSize--;
        auto sliceVar = sliceCenter
                            .map!(a => a.power(2))
                            .sum!(sumTemplateArgs)(seedVar)
                            / sliceSize;

        return sliceCenter
                .map!(a => a / sliceVar.sqrt);
    }
}

/// Z-score of vector
pure nothrow
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
//pure nothrow
unittest
{
    import mir.ndslice.slice : sliced;
    import std.math : approxEqual;

    static immutable x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                          2.0, 7.5, 5.0, 1.0, 1.5, 0.0];
    auto resultSample = [-1.09241, -0.64424, -0.42016, -0.19607, 0.47618, 0.812307,
                         -0.19607, 2.268858, 1.148434, -0.64424, -0.42016, -1.09241].sliced(2, 6);
    auto resultPop = [-1.14099, -0.67289, -0.43884, -0.20479, 0.497354, 0.848427,
                      -0.20479, 2.369745, 1.199501, -0.67289, -0.43884, -1.14099].sliced(2, 6);

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
