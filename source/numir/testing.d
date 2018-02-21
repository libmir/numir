/++
Various testing utility on the ndslice (e.g., approxEqual, assertShapeEqual)
 +/
module numir.testing;

import mir.ndslice.slice : isSlice;


/// testing function for float-point slices
pure nothrow @nogc
bool approxEqual(L, R, V)(L lhs, R rhs, V maxRelDiff=1e-2, V maxAbsDiff=1e-5)
    if (isSlice!L && isSlice!R)
{
    import mir.ndslice : equal;
    import std.math : stdApproxEqual = approxEqual;
    assertShapeEqual(lhs, rhs);
    return equal!((a, b) => stdApproxEqual(a, b, maxRelDiff, maxAbsDiff))(lhs, rhs);
}


///
pure nothrow @nogc
unittest
{
    import mir.ndslice : sliced;
    static immutable eps = 1e-6;
    static immutable _a = [1.0, 0.0,
                           0.0, 1.0];
    auto a = _a.sliced(2, 2);
    static immutable _b = [1.0, eps,
                           -eps, 1.0];
    auto b = _b.sliced(2, 2);
    assert(approxEqual(a, b, eps*2, eps*2));
    assert(!approxEqual(a, b, eps/2, eps/2));
}

/// testing function for shape equality
pure nothrow @nogc
void assertShapeEqual(L, R)(L lhs, R rhs) if (isSlice!L && isSlice!R)
{
    import numir.core : Ndim;
    import std.range : iota;
    import std.array : array;

    static assert(Ndim!L == Ndim!R);
    // LDC1.7.0 cannot compile this but DMD2.078.1 is OK
    // static foreach (i; 0 .. Ndim!R) cannot be used here
    // https://github.com/dlang/DIPs/blob/master/DIPs/DIP1010.md#proposal-2-add-static-foreach-declaration-and-static-foreach-statement
    static foreach (i; iota(Ndim!R).array)
    {
        assert(lhs.length!i == rhs.length!i);
    }
}

///
pure nothrow @nogc
unittest
{
    import mir.ndslice : iota;
    import core.exception;

    // test OK
    assertShapeEqual(iota(3, 4), iota(3, 4));
    assertShapeEqual(iota(0), iota(0));

    // test NG
    static assert(!__traits(compiles, assertShapeEqual(iota(3, 4), iota(3, 4, 5))));
    try
    {
        assertShapeEqual(iota(3, 4), iota(3, 2));
    }
    catch (AssertError)
    {
        // OK!
    }
    catch (Error)
    {
        assert(false);
    }
}
