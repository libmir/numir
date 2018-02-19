module numir.core.utility;

import mir.ndslice.slice : Slice, SliceKind;

/++
Returns the number of dimensions of type `R`.
+/
template rank(R)
{
    import std.traits : isArray;
    import std.range.primitives : isInputRange, ElementType;

    static if (isInputRange!R || isArray!R)
    {
        enum size_t rank = 1 + rank!(ElementType!R);
    }
    else
    {
        enum size_t rank = 0;
    }
}

///
unittest
{
    static assert(rank!(int[2]) == 1);
    static assert(rank!(int[2][3]) == 2);
}

/++
Returns the ElementType of a nested type `T`.
+/
template NestedElementType(T)
{
    import std.traits : isArray;

    static if (isArray!T)
    {
        import std.range.primitives : ElementType;

        alias NestedElementType = NestedElementType!(ElementType!T);
    }
    else
    {
        alias NestedElementType = T;
    }
}

///
unittest
{
    static assert(is(NestedElementType!(int[][]) == int));
}

/++
Returns the shape of a nested array length. Note that the array should have
compile-time nested lengths. Dynamic arrays get compile errors.

Params:
    array = input array

Returns:
    shape
+/
size_t[rank!T] shapeNested(T)(T array) pure nothrow
{
    static if (rank!T == 0)
    {
        return [];
    }
    else
    {
        import std.conv : to;
        import std.exception : assumeWontThrow;
        // it won't throw the cast error because array rank is statically given.
        return assumeWontThrow(to!(size_t[rank!T])(array.length ~ shapeNested(array[0])));
    }
}

///
unittest
{
    assert([1].shapeNested == [1]);
    assert([1, 2].shapeNested == [2]);
    assert([[1,2],[3,4],[5,6]].shapeNested == [3, 2]);
}

/++
Returns the typeid of the element type of `S`.
+/
auto dtype(S)(S s) pure
{
    import mir.ndslice.slice : DeepElementType;

    return typeid(DeepElementType!S);
}

///
unittest
{
    import mir.ndslice.topology : iota, as;

    auto e = iota([2, 3, 1, 3]).as!double;
    assert(e.dtype == typeid(double));
    assert(e.dtype != typeid(float));
}

/++
Returns the number of dimensions of a Slice.
+/
template Ndim(S)
{
    enum Ndim = ndim(S());
}

///
unittest
{
    import mir.ndslice.topology : iota;

    auto e = iota(2, 3, 1, 3);
    static assert(Ndim!(typeof(e)) == 4);
}

unittest
{
    import mir.ndslice.topology : iota, pack;

    auto e = iota(3, 4, 5, 6).pack!2;
    static assert(Ndim!(typeof(e)) == 4);
}

/++
Returns the number of dimensions of a slice.

Params:
    s = n-dimensional slice

Returns:
    number of dimensions
+/
size_t ndim(SliceKind kind, size_t[] packs, Iterator)(Slice!(kind, packs, Iterator) s)
{
    import mir.ndslice.internal: sum;

    return packs.sum;
}

///
unittest
{
    import mir.ndslice.topology : iota;

    auto e = iota(2, 3, 1, 3);
    assert(e.ndim == 4);
}

unittest
{
    import mir.ndslice.topology : iota, pack;

    auto e = iota(3, 4, 5, 6).pack!2;
    assert(e.ndim == 4);
}

/++
Return the number of bytes to step in each dimension when traversing a slice.

Params:
    s = n-dimensional slice

Returns:
    array of byte strides
+/
size_t[] byteStrides(S)(S s) pure
{
    import mir.ndslice.slice : sliced, DeepElementType;
    import mir.ndslice.topology : map;
    import std.array : array;

    enum b = DeepElementType!S.sizeof;
    return s.strides.sliced.map!(n => n * b).array;
}

///
unittest
{
    import mir.ndslice.topology : iota, as;

    auto e = iota(2, 3, 1, 3);
    assert(e.as!int.byteStrides == [36, 12, 12, 4]);
    assert(e.as!double.byteStrides == [72, 24, 24, 8]);
}

/++
Returns the total number of elements in a slice

Params:
    s = array

Returns:
    total number of elements in a slice
+/
auto size(S)(S s) pure
{
    return s.elementsCount;
}

///
unittest
{
    import mir.ndslice.topology : iota;

    auto e = iota(2, 3, 1, 3);
    assert(e.size == (2 * 3 * 1 * 3));
}

/++
Returns a new view of a slice with the same data, but reshaped to have shape
equal to `lengths`.

Params:
    sl = n-dimensional slice
    lengths = A list of lengths for each dimension

Returns:
    new view of a slice with the same data
+/
auto view(S, size_t N)(S sl, ptrdiff_t[N] length...) pure
{
    import mir.ndslice.slice : Universal, sliced, kindOf;
    import mir.ndslice.topology : flattened, universal, reshape, ReshapeError;
    import mir.ndslice.allocation : slice;

    static if (kindOf!S != Universal) {
        auto s = sl.universal;
    } else {
        auto s = sl;
    }

    int err;
    auto r = s.reshape(length, err);
    if (!err)
    {
        return r;
    }
    else if (err == ReshapeError.incompatible)
    {
        for (size_t n = 0; n < N; ++n)
        {
            if (length[n] == -1)
            {
                size_t remained = 1;
                for (size_t m = 0; m < N; ++m)
                {
                    if (m != n)
                    {
                        remained *= length[m];
                    }
                }
                length[n] = sl.size / remained;
            }
        }

        // allocates, flattens, reshapes with `sliced`, converts to universal kind
        return s.slice.flattened.sliced(cast(size_t[N])length).universal;
    }
    else
    {
        import std.format : format;
        string msg = "ReshapeError: ";
        string vs = "%s vs %s".format(s.shape, length);
        final switch (err) {
        case ReshapeError.empty:
            msg ~= "Slice should not be empty";
            break;
        case ReshapeError.total:
            msg ~= "Total element count should be the same" ~ vs;
            break;
        }
        throw new Exception(msg);
    }
}

///
unittest
{
    import std.string : split;
    import mir.ndslice.topology : universal, iota;
    import mir.ndslice.allocation : slice;
    import mir.ndslice.dynamic : transposed;

    assert(iota(3, 4).slice.view(-1, 1).shape == [12, 1]);
    assert(iota(3, 4).slice.universal.transposed.view(-1, 6).shape == [2, 6]);
}

/// Invalid views generate ReshapeError
unittest
{
    import std.string : split;
    import mir.ndslice.topology : iota;
    import mir.ndslice.allocation : slice;

    try {
        iota(3, 4).slice.view(2, 1);
    } catch (Exception e) {
        assert(e.msg.split(":")[0] == "ReshapeError");
    }
    try {
        iota(0).slice.view(2, 1);
    } catch (Exception e) {
        assert(e.msg.split(":")[0] == "ReshapeError");
    }
}
