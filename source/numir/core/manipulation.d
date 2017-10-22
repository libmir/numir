module numir.core.manipulation;

///
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