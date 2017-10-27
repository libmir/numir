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

///
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

///
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

///
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

///
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

///
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

///
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
unittest
{
    assert(arange(3) == [0, 1, 2]);
    assert(arange(2, 3, 0.3) == [2.0, 2.3, 2.6, 2.9]);
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
unittest
{
    assert(linspace(1, 2, 3) == [1.0, 1.5, 2.0]);
}

///
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

///
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

/++ create new diagonal matrix +/
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
