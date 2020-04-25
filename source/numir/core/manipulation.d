/++
Various slice manipulation (e.g., concatenate, squeeze, resize, alongDim)
 +/
module numir.core.manipulation;

// TODO use more isSlice when template type T assumed to be Slice.
import mir.ndslice.slice : isSlice;
import mir.primitives : DimensionCount;

// version = test_deprecated;

deprecated("use `import mir.ndslice.fuse: fuse, fuseAs;`")
auto nparray(E=void, T)(T a) pure nothrow
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

version(test_deprecated)
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

version(test_deprecated)
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
    slices = slices to concatentate

Returns:
    concatenated slices
+/
auto concatenate(int axis=0, Slices...)(Slices slices) pure
{
    import mir.ndslice.concatenation : concatenation;
    import mir.ndslice.allocation : slice;
    import numir.core.utility : view;
    import std.format : format;
    import std.meta : staticMap;

    enum int N = DimensionCount!(Slices[0]);
    static assert(-N <= axis, "out of bounds: axis(=%s) < %s".format(axis, -N));
    static assert(axis < N, "out of bounds: %s <= axis(=%s)".format(N, axis));
    static if (axis < 0) {
        enum axis = axis + N;
    }

    foreach (S; Slices) {
        static assert(DimensionCount!S == N,
                      "all the input arrays must have same number of dimensions: %s"
                      .format([staticMap!(DimensionCount, Slices)]));
    }

    return concatenation!axis(slices).slice;
}

///
unittest
{
    import mir.ndslice.fuse : fuse;
    import mir.ndslice.topology : universal;
    import mir.ndslice.dynamic : transposed;

    auto m = fuse([[1, 2],[3, 4]]);
    auto u = fuse([[5, 6]]);

    assert(concatenate(m, u) == [[1, 2], [3, 4], [5, 6]]);
    assert(concatenate(u, m) == [[5, 6], [1, 2], [3, 4]]);

    auto uT = u.universal.transposed;
    assert(concatenate!1(m, uT) == [[1, 2, 5], [3, 4, 6]]);
}

///
unittest
{
    import mir.ndslice.fuse : fuse;
    import mir.ndslice.topology : iota;

    assert(concatenate!0([[0, 1]].fuse,
                         [[2, 3]].fuse,
                         [[4, 5]].fuse) == iota(3, 2));
    assert(concatenate!1([[0, 1]].fuse,
                            [[2, 3]].fuse,
                            [[4, 5]].fuse) == [iota(6)]);

    // axis=-1 is the same to axis=$-1
    assert(concatenate!(-1)([[0, 1]].fuse,
                            [[2, 3]].fuse,
                            [[4, 5]].fuse) == [iota(6)]);
    assert(concatenate!(-1)([[0, 1]].fuse, [[2]].fuse) == [[0, 1, 2]]);
}

deprecated("use `import mir.ndslice.topology: unsqueeze;`")
auto unsqueeze(long axis, S)(S s) pure
{
    import numir.core.utility : view;

    enum long n = DimensionCount!S;
    enum size_t[1] input = [1];
    enum a = axis < 0 ? n + axis + 1 : axis;
    ptrdiff_t[n + 1] shape = cast(ptrdiff_t[a]) s.shape[0 .. a]
        ~ input ~ cast(ptrdiff_t[n - a]) s.shape[a .. n];
    return s.view(shape);
}

version(test_deprecated)
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

deprecated("use `import mir.ndslice.topology: squeeze;`")
auto squeeze(long axis, S)(S s) pure
{
    import numir.core.utility : view;
    enum long n = DimensionCount!S;
    enum a = axis < 0 ? n + axis : axis;
    assert(s.shape[a] == 1);

    ptrdiff_t[n - 1] shape = cast(ptrdiff_t[a]) s.shape[0 .. a]
        ~ cast(ptrdiff_t[n - a - 1]) s.shape[a + 1 .. n];
    return s.view(shape);
}

version(test_deprecated)
unittest
{
    import mir.ndslice.topology : iota;
    import mir.ndslice.allocation : slice;

    assert(iota(1, 3, 4).slice.squeeze!0.shape == [3, 4]);
    assert(iota(3, 1, 4).slice.squeeze!1.shape == [3, 4]);
    assert(iota(3, 4, 1).slice.squeeze!(-1).shape == [3, 4]);
}


/++
Returns a resized n-dimensional slice `s` with new size.
When new size is larger, new slice is padded with 0.
When new size is smaller, new slice is just a subslice of `s`.

Params:
    s = n-dimensional slice
    size = new size of s

Returns:
    new slice with new length

TODO:
    support n-dimensional new shape
+/
auto resize(S)(S s, size_t size) pure if (isSlice!S)
out(ret) {
    import mir.algorithm.iteration : all;
    assert(ret.length == size);
    if (s.length < size) assert(ret[s.length .. $].all!"a == 0");
} do {
    import numir.core.creation : zeros;
    import mir.ndslice.slice : DeepElementType;

    if (s.length >= size) {
        return s[0 .. size];
    }
    auto sh = s.shape;
    sh[0] = size;
    auto ret = zeros!(DeepElementType!S)(sh);
    ret[0 .. s.length][] = s;
    return ret;
}

///
unittest {
    import mir.ndslice.fuse : fuse;
    import mir.ndslice.slice : sliced;

    assert([1,2].sliced.resize(3) == [1, 2, 0]);
    assert([1,2].sliced.resize(2) == [1, 2]);
    assert([1,2].sliced.resize(1) == [1]);

    assert([[1,2],[3,4]].fuse.resize(3) == [[1,2], [3,4], [0,0]]);
    assert([[1,2],[3,4]].fuse.resize(2) == [[1,2], [3,4]]);
    assert([[1,2],[3,4]].fuse.resize(1) == [[1,2]]);

    assert([1,2].sliced.resize(0) == [].sliced!int);
    assert([].sliced!int.resize(3) == [0,0,0]);
}


deprecated("use `import mir.ndslice.topology: alongDim;`")
auto alongDim(ptrdiff_t dim, S)(S s) if (isSlice!S)
{
    enum n = DimensionCount!S;
    enum a = dim >= 0 ? dim : n + dim;
    static assert(a < n);

    import std.range : iota;
    import std.array : array;
    import mir.ndslice.dynamic : transposed;
    import mir.ndslice.topology : pack;

    enum size_t[n] ds = iota(0, a).array ~ iota(a+1, n).array ~ [a];
    return s.transposed(ds).pack!1;
}

version(test_deprecated)
pure @safe @nogc
unittest
{
    import numir : alongDim, nparray;
    import mir.ndslice : iota;

    auto s = iota(3, 4, 5);

    // along 0-dim
    static immutable s0 = [4, 5];
    assert(s.alongDim!0.shape == s0);
    static immutable s0f = [3];
    assert(s.alongDim!0[0, 0].shape == s0f);

    // along 1-dim
    static immutable s1 = [3, 5];
    assert(s.alongDim!1.shape == s1);
    static immutable s1f = [4];
    assert(s.alongDim!1[0, 0].shape == s1f);

    // also support negative dim -1-dim == 2-dim
    static immutable s2 = [3, 4];
    assert(s.alongDim!(-1).shape == s2);
    static immutable s2f = [5];
    assert(s.alongDim!(-1)[0, 0].shape == s2f);
}
