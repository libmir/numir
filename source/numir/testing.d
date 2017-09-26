module numir.testing;


/// testing function for float-point slices
bool approxEqual(T, U, V)(T lhs, U rhs, V maxRelDiff=1e-2, V maxAbsDiff=1e-5)
{
    import mir.ndslice : equal;
    import std.math : stdApproxEqual = approxEqual;
    assert(lhs.shape == rhs.shape);
    return equal!((a, b) => stdApproxEqual(a, b, maxRelDiff, maxAbsDiff))(lhs, rhs);
}


///
unittest
{
    import numir : nparray;
    auto eps = 1e-6;
    auto a = [[1.0, 0.0], [0.0, 1.0]].nparray;
    auto b = [[1.0, eps], [-eps, 1.0]].nparray;
    assert(approxEqual(a, b, eps*2, eps*2));
    assert(!approxEqual(a, b, eps/2, eps/2));
}
