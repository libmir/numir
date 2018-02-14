module numir.core;

import mir.ndslice;
import mir.ndslice.slice : Slice, SliceKind;
import mir.ndslice.traits : isMatrix, isVector;

import std.array : array;
import std.conv : to;
import std.format : format;
import std.meta : staticMap;
import std.range : ElementType, isInputRange;
import std.stdio : writeln;
import std.traits : CommonType, isArray, isFloatingPoint;


static if (__VERSION__ < 2073)
{
    import numir.old : maxIndex; // not supported yet (2.071)
}
else
{
    import std.algorithm.searching: maxIndex;
}

///
unittest
{
    /*
      Types

      np.ndarray | mir
      -----------+--------
      np.float32 | float
      np.float64 | double
      np.int8    | byte
      np.uint8   | ubyte
      np.int16   | short
      np.int32   | int
      np.int64   | long
      np.astype  | as

      see also https://dlang.org/spec/type.html
    */
}

/++
Construct new uninitialized slice of element type `E` and shape(`length ...`).

Params:
    length = elements of shape

Returns:
    new uninitialized slice
+/
auto empty(E=double, size_t N)(size_t[N] length...) pure
{
    return uninitializedSlice!E(length);
}

/++
Construct new slice having the same element type and shape to given slice.

Params:
    initializer = template function(ElementType)(shape) that initializes slice
    slice = n-dimensional slice to refer shape and element type

Returns:
    new uninitialized slice
+/
auto like(alias initializer, S)(S slice) pure
{
    return initializer!(DeepElementType!S)(slice.shape);
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

/++
Construct a new slice, filled with ones, of element type `E` and 
shape(`length ...`).

Params:
    lengths = elements of shape

Returns:
    new ones slice
+/
auto ones(E=double, size_t N)(size_t[N] length...) pure
{
    return slice!E(length, 1);
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

/++
Construct a new slice, filled with zeroes, of element type `E` and 
shape(`length ...`).

Params:
    lengths = elements of shape

Returns:
    new zeroes slice
+/
auto zeros(E=double, size_t N)(size_t[N] length...) pure
{
    return slice!E(length, 0);
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
    /* Constructors

       numpy            | numir
       -----------------+---------------------------------------
       np.empty([2,2])  | numir.empty(2, 2), numir.empty([2, 2])
       np.empty_like(x) | numir.empty_like(x)
       np.eye           | numir.eye
       np.identity      | numir.identity
       np.ones          | numir.ones
       np.ones_like     | numir.ones_like
       np.zeros         | numir.zeros
       np.zeros_like    | numir.zeros_like

       see also http://mir.dlang.io/mir_ndslice_allocation.html
    */

    // np.empty, empty_like
    assert(empty(2 ,3).shape == [2, 3]);
    assert(empty([2 ,3]).shape == [2, 3]);
    auto e0 = empty!int(2, 3);
    auto e1 = empty_like(e0);
    assert(e1.shape == e0.shape);
    e0[0, 0] += 1;
    assert(e1 != e0);
    alias E0 = DeepElementType!(typeof(e0));
    alias E1 = DeepElementType!(typeof(e1));
    static assert(is(E0 == E1));

    // np.ones, ones_like
    auto o = ones(2, 3);
    assert(o.all!(x => x == 1));
    assert(o.shape == [2, 3]);
    assert(o == ones([2, 3]));
    assert(o == o.ones_like);

    // np.zeros, np.zeros_like
    auto z = zeros(2, 3);
    assert(z.all!(x => x == 0));
    assert(z.shape == [2, 3]);
    assert(z == zeros([2, 3]));
    assert(z == z.zeros_like);

    // np.eye, identity
    assert(eye(2, 3, 1) == [[0.0, 1.0, 0.0],
                            [0.0, 0.0, 1.0]]);
    assert(identity(2) == [[1.0, 0.0],
                           [0.0, 1.0]]);
}

/++
Returns the number of dimensions of type `R`.
+/
template rank(R)
{
    static if (isInputRange!R || isArray!R)
    {
        enum size_t rank = 1 + rank!(ElementType!R);
    }
    else
    {
        enum size_t rank = 0;
    }
}

/++
Returns the ElementType of a nested type `T`.
+/
template NestedElementType(T)
{
    static if (isArray!T)
    {
        alias NestedElementType = NestedElementType!(ElementType!T);
    }
    else
    {
        alias NestedElementType = T;
    }
}

/++
Returns the shape of a nested type.

Params:
    array = input array

Returns:
    shape
+/
size_t[rank!T] shapeNested(T)(T array) pure
{
    static if (rank!T == 0)
    {
        return [];
    }
    else
    {
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

/++
Create a slice of element type `E` with shape matching the shape of `a` and
filled with its values.

Params:
    a = input used to fill result

Returns:
    slice filled with values of `a`
+/
auto nparray(E=void, T)(T a)
{
    static if (is(E == void))
    {
        alias E = NestedElementType!T;
    }
    auto m = slice!E(a.shapeNested);
    m[] = a;
    return m;
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

    import mir.ndslice.concatenation: concatenation;
    return concatenation!axis(slices).slice;
}

///
unittest
{
    /* From existing data

       numpy                     | numir
       --------------------------+------------------------
       np.array([ [1,2],[3,4] ]) | nparray([ [1,2],[3,4] ])
       np.ascontiguousarray(x)   | x.assumeContiguous
       np.copy(x)                | ????
       np.fromfile(file)         | ????
       np.concatenate            | concatenate
    */

    auto s = [[1,2],[3,4]].sliced; // mir's sliced
    // error: s[0, 0] = -1;

    auto m = nparray([[1,2],[3,4]]);
    m[0, 0] = -1;
    assert(m == [[-1,2], [3,4]]);
    static assert(is(DeepElementType!(typeof(m)) == int)); // maybe double?

    auto v = nparray([1, 2]);
    v[1] = -2;
    assert(v == [1, -2]);

    auto u = nparray([[5, 6]]);
    assert(concatenate(m, u) == [[-1, 2], [3, 4], [5, 6]]);
    assert(concatenate(u, m) == [[5, 6], [-1, 2], [3, 4]]);

    auto uT = u.universal.transposed;
    assert(concatenate!1(m, uT) == [[-1, 2, 5], [3, 4, 6]]);

    assert(concatenate!0([[0,1]].nparray, [[2,3]].nparray, [[4,5]].nparray) == iota(3, 2));
    // axis=-1 is the same to axis=$-1
    assert(concatenate!(-1)([[0,1]].nparray, [[2,3]].nparray, [[4,5]].nparray) == [iota(6)]);
    assert(concatenate!(-1)([[0,1]].nparray, [[2]].nparray) == [[0, 1, 2]]);
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
    size_t num = to!size_t((end - start) / step) + 1;
    return num.steppedIota!E(step, start);
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
    static if (!isFloatingPoint!E) {
        alias E = double;
    }
    return mir.ndslice.linspace([num].to!(size_t[1]), [[start, stop]].to!(E[2][1]));
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
    return iota(num).map!(i => E(i * step + start));
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
    return linspace(start, stop, num).map!(x => base ^^ x);
}

///
unittest
{
    /* Numerical Ranges

       numpy                | numir
       ---------------------+--------
       np.arange(10)        | arange(10)
       np.arange(2, 3, 0.1) | arange(2, 3, 0.1)
       np.linspace(1, 4, 6) | linspace(1, 4, 6)
       np.logspace          | logspace

       see also: http://mir.dlang.io/mir_ndslice_topology.html#.iota
    */
    assert(arange(3) == [0, 1, 2]);
    assert(arange(2, 3, 0.3) == [2.0, 2.3, 2.6, 2.9]);
    assert(linspace(1, 2, 3) == [1.0, 1.5, 2.0]);
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
        auto sk = s.select!dimension(k, s.length!dimension);
        return sk.diagonal;
    }
}

///
unittest
{
    /* Building Matrices

       numpy    | numir
       ---------+---------
       np.diag  | diagonal
       np.tril  | <WIP>
       np.triu  | <WIP>
    */

    //  -------
    // | 0 1 2 |
    // | 3 4 5 |
    //  -------
    auto a = iota(2, 3);
    assert(a.diag == [0, 4]);
    assert(a.diag!(1)(1) == [1, 5]);
    assert(a.diag!(0)(1) == [3]);
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
     import mir.ndslice : diagonal;

     auto result = zeros([s.length, s.length]);
     result.diagonal[] = s;
     return result;
}

///
unittest
{
    import mir.ndslice.topology : iota;
    import mir.ndslice.slice : sliced;

    auto a = iota(3).diag;
    auto result = [[0.0, 0.0, 0.0], 
                   [0.0, 1.0, 0.0], 
                   [0.0, 0.0, 2.0]].sliced;
    assert(a[0] == result[0]);
    assert(a[1] == result[1]);
    assert(a[2] == result[2]);
}

/++
Returns the typeid of the element type of `S`.
+/
auto dtype(S)(S s) pure
{
    return typeid(DeepElementType!S);
}

/++
Returns the number of dimensions of a Slice.
+/
template Ndim(S)
{
    enum Ndim = ndim(S());
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

/++
Return the number of bytes to step in each dimension when traversing a slice.

Params:
    s = n-dimensional slice

Returns:
    array of byte strides
+/
size_t[] byteStrides(S)(S s) pure
{
    enum b = DeepElementType!S.sizeof;
    return s.strides.sliced.map!(n => n * b).array;
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
    /* Attributes

       numpy     | numir
       ----------+---------------
       x.shape   | x.shape
       x.strides | x.byteStrides (!) already <strides> function is defined in mir
       x.ndim    | x.ndim
       x.data    | ???
       x.size    | x.size
       len(x)    | x.length
       x.dtype   | x.dtype
    */

    auto e = empty!double(2, 3, 1, 3);
    assert(e.dtype == typeid(double));
    assert(e.dtype != typeid(float));
    assert(e.length == 2);
    assert(e.size == 2*3*1*3);
    assert(e.ndim == 4);
    assert(e.strides == [9, 3, 3, 1]);
    assert(e.byteStrides == [72, 24, 24, 8]);

    auto a = iota(3, 4, 5, 6);
    auto b = a.pack!2;
    assert(b.ndim == 4);
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
    enum long n = Ndim!S;
    enum size_t[1] input = [1];
    enum a = axis < 0 ? n + axis + 1 : axis;
    ptrdiff_t[n + 1] shape = cast(ptrdiff_t[a]) s.shape[0 .. a]
        ~ input ~ cast(ptrdiff_t[n - a]) s.shape[a .. n];
    return s.view(shape);
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
    enum long n = Ndim!S;
    enum a = axis < 0 ? n + axis : axis;
    assert(s.shape[a] == 1);

    ptrdiff_t[n - 1] shape = cast(ptrdiff_t[a]) s.shape[0 .. a]
        ~ cast(ptrdiff_t[n - a - 1]) s.shape[a + 1 .. n];
    return s.view(shape);
}

/// Shape Manipulation
unittest
{
    import std.string;
    /* Shape Manipulation
       numpy       | numir
       ------------+------------------
       x.reshape   | x.view(-1,2), x.reshape([-1, 2], error) (from mir)
       x.resize    | None
       x.transpose | x.transposed (from mir)
       x.flatten   | x.flattened (from mir)
       x.squeeze   | x.squeeze, x.unsqueeze
     */

    assert(iota(3, 4).slice.view(-1, 1).shape == [12, 1]);
    assert(iota(3, 4).slice.universal.transposed.view(-1, 6).shape == [2, 6]);

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

    assert(iota(2, 3).slice.unsqueeze!0 == [[[0,1,2], [3,4,5]]]);
    assert(iota(2, 3).slice.unsqueeze!1 == [[[0,1,2]], [[3,4,5]]]);
    assert(iota(2, 3).slice.unsqueeze!2 == [[[0],[1],[2]], [[3],[4],[5]]]);
    assert(iota(2, 3).slice.unsqueeze!(-1) == [[[0],[1],[2]], [[3],[4],[5]]]);

    assert(iota(1, 3, 4).slice.squeeze!0.shape == [3, 4]);
    assert(iota(3, 1, 4).slice.squeeze!1.shape == [3, 4]);
    assert(iota(3, 4, 1).slice.squeeze!(-1).shape == [3, 4]);
}


/// Item selection and manipulation

/// Calculation

/// Arithmetic and comparison operations
