module numir.core.manipulation;

/++
Create a slice of element type `E` with shape matching the shape of `a` and
filled with its values. In other words, `nparray` retains the nested array
lengths as slice shape (unlike `mir.ndslice.sliced`).

Params:
    a = input used to fill result

Returns:
    slice filled with values of `a` with the shape of nested lengths.
+/
auto nparray(E=void, T)(T a)
{
    import numir.core.utility : NestedElementType, shapeNested;
    import mir.ndslice.allocation : slice;

    static if (is(E == void))
    {
        alias E = NestedElementType!T;
    }
    auto m = slice!E(a.shapeNested);
    m[] = a;
    return m;
}

///
unittest
{
    import mir.ndslice.slice : sliced, DeepElementType;

    auto s = [[1, 2],[3, 4]].sliced; // mir's sliced
    // error: s[0, 0] = -1;

    auto m = nparray([[1, 2],[3, 4]]);
    m[0, 0] = -1;
    assert(m == [[-1, 2], [3, 4]]);
    static assert(is(DeepElementType!(typeof(m)) == int));
}

unittest
{
    auto v = nparray([1, 2]);
    v[1] = -2;
    assert(v == [1, -2]);
}

/++
Join multiple `slices` along an `axis.`

Params:
    axis = dimension of concatenation
    slice = slices to concatentate

Returns:
    concatenated slices
+/
auto concatenate(int axis=0, Slices...)(Slices slices) pure
{
    import mir.ndslice.concatenation : concatenation;
    import mir.ndslice.allocation : slice;
    import numir.core.utility : Ndim, view;
    import std.format : format;
    import std.meta : staticMap;

    enum int N = Ndim!(Slices[0]);
    static assert(-N <= axis, "out of bounds: axis(=%s) < %s".format(axis, -N));
    static assert(axis < N, "out of bounds: %s <= axis(=%s)".format(N, axis));
    static if (axis < 0) {
        enum axis = axis + N;
    }

    foreach (S; Slices) {
        static assert(Ndim!S == N,
                      "all the input arrays must have same number of dimensions: %s"
                      .format([staticMap!(Ndim, Slices)]));
    }

    return concatenation!axis(slices).slice;
}

///
unittest
{
    import mir.ndslice.topology : universal;
    import mir.ndslice.dynamic : transposed;

    auto m = nparray([[1, 2],[3, 4]]);
    auto u = nparray([[5, 6]]);

    assert(concatenate(m, u) == [[1, 2], [3, 4], [5, 6]]);
    assert(concatenate(u, m) == [[5, 6], [1, 2], [3, 4]]);

    auto uT = u.universal.transposed;
    assert(concatenate!1(m, uT) == [[1, 2, 5], [3, 4, 6]]);
}

///
unittest
{
    import mir.ndslice.topology : iota;

    assert(concatenate!0([[0, 1]].nparray,
                         [[2, 3]].nparray,
                         [[4, 5]].nparray) == iota(3, 2));
    assert(concatenate!1([[0, 1]].nparray,
                            [[2, 3]].nparray,
                            [[4, 5]].nparray) == [iota(6)]);

    // axis=-1 is the same to axis=$-1
    assert(concatenate!(-1)([[0, 1]].nparray,
                            [[2, 3]].nparray,
                            [[4, 5]].nparray) == [iota(6)]);
    assert(concatenate!(-1)([[0, 1]].nparray, [[2]].nparray) == [[0, 1, 2]]);
}

/++
Return a view of an n-dimensional slice with a dimension added at `axis`. Used
to unsqueeze a squeezed slice.

Params:
    axis = dimension to be unsqueezed (add new dimension
    s = n-dimensional slice

Returns:
    unsqueezed slice
+/
auto unsqueeze(long axis, S)(S s) pure
{
    import numir.core.utility : Ndim, view;

    enum long n = Ndim!S;
    enum size_t[1] input = [1];
    enum a = axis < 0 ? n + axis + 1 : axis;
    ptrdiff_t[n + 1] shape = cast(ptrdiff_t[a]) s.shape[0 .. a]
        ~ input ~ cast(ptrdiff_t[n - a]) s.shape[a .. n];
    return s.view(shape);
}

///
unittest
{
    import mir.ndslice.topology : iota;
    import mir.ndslice.allocation : slice;

    //  -------
    // | 0 1 2 |
    // | 3 4 5 |
    //  -------
    auto s = iota(2, 3);
    assert(s.slice.unsqueeze!0 == [[[0, 1, 2],
                                    [3, 4, 5]]]);
    assert(s.slice.unsqueeze!1 == [[[0, 1, 2]],
                                   [[3, 4, 5]]]);
    assert(s.slice.unsqueeze!2 == [[[0], [1], [2]],
                                   [[3], [4], [5]]]);
    assert(s.slice.unsqueeze!(-1) == [[[0], [1], [2]],
                                      [[3], [4], [5]]]);
}

/++
Returns a new view of an n-dimensional slice with dimension `axis` removed, if
it is single-dimensional.

Params:
    axis = dimension to remove, if it is single-dimensional
    s = n-dimensional slice

Returns:
    new view of a slice with dimension removed
+/
auto squeeze(long axis, S)(S s) pure
{
    import numir.core.utility : Ndim, view;
    enum long n = Ndim!S;
    enum a = axis < 0 ? n + axis : axis;
    assert(s.shape[a] == 1);

    ptrdiff_t[n - 1] shape = cast(ptrdiff_t[a]) s.shape[0 .. a]
        ~ cast(ptrdiff_t[n - a - 1]) s.shape[a + 1 .. n];
    return s.view(shape);
}

///
unittest
{
    import mir.ndslice.topology : iota;
    import mir.ndslice.allocation : slice;

    assert(iota(1, 3, 4).slice.squeeze!0.shape == [3, 4]);
    assert(iota(3, 1, 4).slice.squeeze!1.shape == [3, 4]);
    assert(iota(3, 4, 1).slice.squeeze!(-1).shape == [3, 4]);
}
