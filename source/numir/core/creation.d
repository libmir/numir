module numir.core.creation;

import mir.ndslice.slice : Slice, SliceKind;
import mir.ndslice.traits : isMatrix, isVector;

/++
Construct new uninitialized slice of element type `E` and shape(`length ...`).

Params:
    length = elements of shape

Returns:
    new uninitialized slice
+/
auto empty(E = double, size_t N)(size_t[N] length...) pure
{
    import mir.ndslice.allocation : uninitSlice;

    return uninitSlice!E(length);
}

///
unittest
{
    assert(empty(2, 3).shape == [2, 3]);
    assert(empty([2, 3]).shape == [2, 3]);
}

/++
Construct new slice having the same element type and shape to given slice.

Params:
    initializer = template function(ElementType)(shape) that initializes slice
    slice = n-dimensional slice to refer shape and element type

Returns:
    new initialized slice with Initializer alias
+/
auto like(alias initializer, S)(S slice) pure
{
    import mir.ndslice.slice : DeepElementType;

    return initializer!(DeepElementType!S)(slice.shape);
}

///
unittest
{
    import mir.ndslice.topology : iota;
    import mir.ndslice.slice : DeepElementType;

    //  -------
    // | 1 2 3 |
    // | 4 5 6 |
    //  -------
    auto s = iota([2, 3], 1);
    //  -------
    // | 0 1 2 |
    // | 3 4 5 |
    //  -------
    auto e = s.like!iota;

    static assert(is(typeof(e) == typeof(s)));
    assert(e.shape == s.shape);
    assert(e != s);
    alias S = DeepElementType!(typeof(s));
    alias E = DeepElementType!(typeof(e));
    static assert(is(S == E));
}

/++
Construct new empty slice having the same element type and shape to given slice.

Params:
    slice = n-dimensional slice to refer shape and element type

Returns:
    new empty slice
+/
auto empty_like(S)(S slice) pure
{
    return slice.like!empty;
}

///
unittest
{
    auto s = empty!int(2, 3);
    auto e = empty_like(s);

    static assert(is(typeof(e) == typeof(s)));
    assert(e.shape == s.shape);
    s[0, 0] += 1;
    assert(e != s);
}

/++
Construct a new slice, filled with ones, of element type `E` and
shape(`length ...`).

Params:
    lengths = elements of shape

Returns:
    new ones slice
+/
auto ones(E = double, size_t N)(size_t[N] length...) pure
{
    import mir.ndslice.allocation : slice;

    return slice!E(length, 1);
}

///
unittest
{
    import mir.ndslice.algorithm : all;

    //  -------
    // | 1 1 1 |
    // | 1 1 1 |
    //  -------
    auto o = ones(2, 3);
    assert(o.all!(x => x == 1));
    assert(o.shape == [2, 3]);
    assert(o == ones([2, 3]));
}

/++
Construct new ones slice having the same element type and shape to given slice.

Params:
    slice = n-dimensional slice to refer shape and element type

Returns:
    new ones slice
+/
auto ones_like(S)(S slice) pure
{
    return slice.like!ones;
}

///
unittest
{
    import mir.ndslice.topology : iota;

    //  -------
    // | 0 1 2 |
    // | 3 4 5 |
    //  -------
    auto e = iota(2, 3);

    assert(e.ones_like == ones(2, 3));
}

/++
Construct a new slice, filled with zeroes, of element type `E` and
shape(`length ...`).

Params:
    lengths = elements of shape

Returns:
    new zeroes slice
+/
auto zeros(E = double, size_t N)(size_t[N] length...) pure
{
    import mir.ndslice.allocation : slice;

    return slice!E(length, 0);
}

///
unittest
{
    import mir.ndslice.algorithm : all;

    //  -------
    // | 0 0 0 |
    // | 0 0 0 |
    //  -------
    auto z = zeros(2, 3);
    assert(z.all!(x => x == 0));
    assert(z.shape == [2, 3]);
    assert(z == zeros([2, 3]));
}

/++
Construct new zeroes slice having the same element type and shape to given
slice.

Params:
    slice = n-dimensional slice to refer shape and element type

Returns:
    new zeroes slice
+/
auto zeros_like(S)(S slice) pure
{
    return slice.like!zeros;
}

///
unittest
{
    import mir.ndslice.topology : iota;

    //  -------
    // | 0 1 2 |
    // | 3 4 5 |
    //  -------
    auto e = iota(2, 3);

    assert(e.zeros_like == zeros(2, 3));
}

/++
Construct a new slice with ones along a diagonal and zeroes elsewhere of element
type `E`.

The diagonal is set through the interaction of `dimension` and `k`. `k`
determines the offset of the diagonal and `dimension` controls the dimension
of that this offset proceeds in. For instance, if `dimension` = 1 and `k` = 1,
then the diagonal after the first column is what is filled with ones.

Params:
    dimension = axis to apply `k` offset
    m = number of rows of output
    n = number of columns of output (default = 0, sets n = m)
    k = offset for start of diagonal (default = 0)

Returns:
    new eye slice
+/
template eye(E = double, size_t dimension = 1)
{
    auto eye(size_t m, size_t n=0, size_t k=0) pure
    {
        if (n == 0) n = m;
        auto z = zeros!E(m, n);
        z.diag!(dimension)(k)[] = 1;
        return z;
    }
}

/++
Returns a `double` `eye` slice.

Params:
    dimension = axis to apply `k` offset
    m = number of rows of output
    n = number of columns of output (default = 0, sets n = m)
    k = offset for start of diagonal (default = 0)

Returns:
    new eye slice
+/
auto eye(size_t dimension)(size_t m, size_t n=0, size_t k=0) pure
{
    return eye!(double, dimension)(m, n, k);
}

///
unittest
{
    assert(eye(2) == [[1.0, 0.0],
                      [0.0, 1.0]]);
}

///
unittest
{
    assert(eye(2, 3) == [[1.0, 0.0, 0.0],
                         [0.0, 1.0, 0.0]]);
    assert(eye(2, 3, 1) == [[0.0, 1.0, 0.0],
                            [0.0, 0.0, 1.0]]);
    assert(eye(2, 3, 2) == [[0.0, 0.0, 1.0],
                            [0.0, 0.0, 0.0]]);
    assert(eye!0(2, 3, 1) == [[0.0, 0.0, 0.0],
                              [1.0, 0.0, 0.0]]);
}

/++
Returns a square slice of element type `E` with ones on the main diagonal and
zeros elsewhere.

Params:
    n = number of rows and columns

Returns:
    new identity slice
+/
auto identity(E=double)(size_t n) pure
{
    return eye!E(n);
}

///
unittest
{
    assert(identity(2) == [[1.0, 0.0],
                           [0.0, 1.0]]);
}

/++
Returns a 1-dimensional slice whose elements are equal to its indices.

Params:
    size = length

Returns:
    1-dimensional slice composed of indices
+/
auto arange(size_t size)
{
    import mir.ndslice.topology : iota;

    return size.iota;
}

/++
Returns a 1-dimensional slice whose elements are equal to its indices.

Params:
    start = value of the first index
    end = value of the last index
    step = value between indices (default = 1)

Returns:
    1-dimensional slice composed of indices
+/
auto arange(E)(E start, E end, E step=1) pure
{
    import std.conv : to;

    size_t num = to!size_t((end - start) / step) + 1;
    return num.steppedIota!E(step, start);
}

///
unittest
{
    assert(arange(3) == [0, 1, 2]);
    assert(arange(2, 3, 0.3) == [2.0, 2.3, 2.6, 2.9]);
}

/++
Returns a slice with evenly spaced numbers over an interval.

Params:
    start = value of the first element
    stop = value of the last element
    num = number of points in the interval (default = 50)

Returns:
    slice with evenly spaced numbers over an interval
+/
auto linspace(E=double)(E start, E stop, size_t num=50)
{
    import std.traits : isFloatingPoint;
    import std.conv : to;
    import mir.ndslice.topology : linspace;

    static if (!isFloatingPoint!E)
    {
        alias E = double;
    }
    return linspace([num].to!(size_t[1]), [[start, stop]].to!(E[2][1]));
}

///
unittest
{
    assert(linspace(1, 2, 3) == [1.0, 1.5, 2.0]);
}

/++
An alternate, 1-dimensional version of iota (and different API).

Params:
    num = number of values to return
    step = value between indices
    start = value of the first index

Returns:
    1-dimensional slice composed of indices
+/
auto steppedIota(E)(size_t num, E step, E start=0) pure
{
    import mir.ndslice.topology : iota, map;

    return iota(num).map!(i => E(i * step + start));
}

///
unittest
{
    assert(steppedIota!double(4, 0.3, 2.0) == [2.0, 2.3, 2.6, 2.9]);
}

/++
Returns a slice with numbers evenly spaced over a log scale.

In linear space, the sequence starts at `base ^^ start` (`base to the power of
`start) and ends with `base ^^ stop`.

Params:
    start = `base ^^ start` is the value of the first element
    stop = `base ^^ stop` is the value of the last element
    num = number of points in the interval (default = 50)
    base = the base of the log space (default = 10)

Returns:
    slice with numbers evenly spaced over a log scale
+/
auto logspace(E=double)(E start, E stop, size_t num=50, E base=10)
{
    import mir.ndslice.topology : map;

    return linspace(start, stop, num).map!(x => base ^^ x);
}

///
unittest
{
    assert(logspace(1, 2, 3, 10) == [10. ^^ 1.0, 10. ^^ 1.5, 10. ^^ 2.0]);
}

/++
Extract the diagonal of a 2-dimensional slice.

Params:
    dimension = dimension to apply the offset, `k` (default = 1)
    s = 2-dimensional slice
    k = offset from the main diagonal, `k > 0` for diagonals above the main
        diagonal, and `k < 0` for diagonals below the main diagonal

Returns:
    the extracted diagonal slice
+/
template diag(size_t dimension = 1)
{
    auto diag(SliceKind kind, size_t[] packs, Iterator)
                           (Slice!(kind, packs, Iterator) s, size_t k = 0) pure
        if (isMatrix!(Slice!(kind, packs, Iterator)))
    {
        import mir.ndslice.topology : diagonal;

        auto sk = s.select!dimension(k, s.length!dimension);
        return sk.diagonal;
    }
}

///
unittest
{
    import mir.ndslice.topology : iota;

    //  -------
    // | 0 1 2 |
    // | 3 4 5 |
    //  -------
    auto a = iota(2, 3);
    assert(a.diag == [0, 4]);
    assert(a.diag!1(1) == [1, 5]);
    assert(a.diag!0(1) == [3]);
}


/++
Create a diagonal 2-dimensional slice from a 1-dimensional slice.

Params:
    s = 1-dimensional slice

Returns:
    diagonal 2-dimensional slice
+/
auto diag(SliceKind kind, size_t[] packs, Iterator)
                       (Slice!(kind, packs, Iterator) s) pure
    if (isVector!(Slice!(kind, packs, Iterator)))
{
     import mir.ndslice.topology : diagonal;
     import mir.ndslice.slice : DeepElementType;

     alias zeroType = DeepElementType!(Slice!(kind, packs, Iterator));

     auto result = zeros!(zeroType)([s.length, s.length]);
     result.diagonal[] = s;
     return result;
}

///
unittest
{
    import mir.ndslice.topology : iota;
    import mir.ndslice.slice : sliced;

    //  -------
    // | 0 1 2 |
    //  -------
    auto a = iota(3).diag;
    auto result = [[0, 0, 0],
                   [0, 1, 0],
                   [0, 0, 2]].sliced;
    assert(a[0] == result[0]);
    assert(a[1] == result[1]);
    assert(a[2] == result[2]);
}
