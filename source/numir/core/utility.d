module numir.core.utility;

import mir.ndslice.slice : Slice, SliceKind;

///
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
size_t[rank!T] shapeNested(T)(T array) pure
{
    static if (rank!T == 0)
    {
        return [];
    }
    else
    {
        import std.conv : to;

        return to!(size_t[rank!T])(array.length ~ shapeNested(array[0]));
    }
}

unittest
{
    int[2][3] nested = [[1,2],[3,4],[5,6]];
    assert(nested.shapeNested == [3, 2]);
    assert([1].shapeNested == [1]);
    assert([1, 2].shapeNested == [2]);
    assert([[1,2],[3,4],[5,6]].shapeNested == [3, 2]);
    static assert(is(NestedElementType!(int[][]) == int));
}

/// return
auto dtype(S)(S s) pure
{
    import mir.ndslice.slice : DeepElementType;

    return typeid(DeepElementType!S);
}

///
template Ndim(S)
{
    enum Ndim = ndim(S());
}

///
size_t ndim(SliceKind kind, size_t[] packs, Iterator)(Slice!(kind, packs, Iterator) s)
{
    import mir.ndslice.internal: sum;

    return packs.sum;
}

/// return strides of byte size
size_t[] byteStrides(S)(S s) pure
{
    import mir.ndslice.slice : sliced, DeepElementType;
    import mir.ndslice.topology : map;
    import std.array : array;

    enum b = DeepElementType!S.sizeof;
    return s.strides.sliced.map!(n => n * b).array;
}

/// return size of raveled array
auto size(S)(S s) pure
{
    return s.elementsCount;
}

///
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
