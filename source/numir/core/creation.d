module numir.core.creation;

import mir.ndslice.slice : Slice, SliceKind;
import mir.ndslice.traits : isMatrix, isVector;

/++
 construct new uninitialized slice of an element type `E` and shape(`length ...`)

 Params:
 length = elements of shape
 Returns:
 new uninitialized slice
 +/
auto empty(E=double, size_t N)(size_t[N] length...) pure
{
    import mir.ndslice.allocation : uninitSlice;

    return uninitSlice!E(length);
}

/++
 construct new slice having the same element type and shape to given slice

 Params:
 initializer = template function(ElementType)(shape) that initializes slice
 slice = source slice to refer shape and element type
 Returns:
 new uninitialized slice
 +/
auto like(alias initializer, S)(S slice) pure
{
    import mir.ndslice.slice : DeepElementType;

    return initializer!(DeepElementType!S)(slice.shape);
}

///
auto empty_like(S)(S slice) pure
{
    return slice.like!empty;
}

///
auto ones(E=double, size_t N)(size_t[N] length...) pure
{
    import mir.ndslice.allocation : slice;

    return slice!E(length, 1);
}

///
auto ones_like(S)(S slice) pure
{
    return slice.like!ones;
}

///
auto zeros(E=double, size_t N)(size_t[N] length...) pure
{
    import mir.ndslice.allocation : slice;

    return slice!E(length, 0);
}

///
auto zeros_like(S)(S slice) pure
{
    return slice.like!zeros;
}

///
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

auto eye(size_t dimension)(size_t m, size_t n=0, size_t k=0) pure
{
    return eye!(double, dimension)(m, n, k);
}

///
auto identity(E=double)(size_t n) pure
{
    return eye!E(n);
}

///
auto arange(size_t size)
{
    import mir.ndslice.topology : iota;

    return size.iota;
}

///
auto arange(E)(E start, E end, E step=1) pure
{
    import std.conv : to;

    size_t num = to!size_t((end - start) / step) + 1;
    return num.steppedIota!E(step, start);
}

///
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
auto steppedIota(E)(size_t num, E step, E start=0) pure
{
    import mir.ndslice.topology : iota, map;

    return iota(num).map!(i => E(i * step + start));
}

///
auto logspace(E=double)(E start, E stop, size_t num=50, E base=10)
{
    import mir.ndslice.topology : map;

    return linspace(start, stop, num).map!(x => base ^^ x);
}

/++ return diagonal slice +/
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

/++ create new diagonal matrix +/
auto diag(SliceKind kind, size_t[] packs, Iterator)
                       (Slice!(kind, packs, Iterator) s) pure
    if (isVector!(Slice!(kind, packs, Iterator)))
{
     import mir.ndslice.topology : diagonal;

     auto result = zeros([s.length, s.length]);
     result.diagonal[] = s;
     return result;
}
