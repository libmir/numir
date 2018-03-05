/++
Core functions in numir.
 +/
module numir.core;


///
public import numir.core.creation;
///
public import numir.core.manipulation;
///
public import numir.core.utility;

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
    
    import mir.ndslice.slice : sliced, DeepElementType;
    import mir.ndslice.algorithm : all;

    // np.empty, empty_like
    assert(empty(2 ,3).shape == [2, 3]);
    assert(empty([2 ,3]).shape == [2, 3]);
    auto e0 = empty!int(2, 3);
    auto e1 = empty_like(e0);
    assert(e1.shape == e0.shape);
    e0[0, 0] += 1;
    assert(e1 != e0);

    // np.ones, ones_like
    auto o = ones(2, 3);
    assert(o.all!(x => x == 1));
    assert(o.shape == [2, 3]);

    // np.zeros, np.zeros_like
    auto z = zeros(2, 3);
    assert(z.all!(x => x == 0));
    assert(z.shape == [2, 3]);

    // np.eye, identity
    assert(eye(2, 3, 1) == [[0.0, 1.0, 0.0],
                            [0.0, 0.0, 1.0]]);
    assert(identity(2) == [[1.0, 0.0],
                           [0.0, 1.0]]);
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

    import mir.ndslice.slice : sliced;

    auto s = [[1, 2],[3, 4]].sliced; // mir's sliced
    // error: s[0, 0] = -1;

    auto m = nparray([[1, 2],[3, 4]]);
    m[0, 0] = -1;
    assert(m == [[-1, 2], [3, 4]]);

    auto u = nparray([[5, 6]]);
    assert(concatenate(m, u) == [[-1, 2], [3, 4], [5, 6]]);
    assert(concatenate(u, m) == [[5, 6], [-1, 2], [3, 4]]);
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

    import mir.ndslice.topology : universal, iota, pack;

    auto e = empty!double(2, 3, 1, 3);
    assert(e.dtype == typeid(double));
    assert(e.dtype != typeid(float));
    assert(e.length == 2);
    assert(e.size == (2 * 3 * 1 * 3));
    assert(e.ndim == 4);
    assert(e.strides == [9, 3, 3, 1]);
    assert(e.byteStrides == [72, 24, 24, 8]);
}

/// Shape Manipulation
unittest
{
    /* Shape Manipulation
       numpy       | numir
       ------------+------------------
       x.reshape   | x.view(-1,2), x.reshape([-1, 2], error) (from mir)
       x.resize    | None
       x.transpose | x.transposed (from mir)
       x.flatten   | x.flattened (from mir)
       x.squeeze   | x.squeeze, x.unsqueeze
     */
     
    import mir.ndslice.topology : universal, iota;
    import mir.ndslice.allocation : slice;
    import mir.ndslice.dynamic : transposed;

    assert(iota(3, 4).slice.view(-1, 1).shape == [12, 1]);
    assert(iota(3, 4).slice.universal.transposed.view(-1, 6).shape == [2, 6]);

    assert(iota(2, 3).slice.unsqueeze!0 == [[[0, 1, 2],
                                             [3, 4, 5]]]);
    assert(iota(2, 3).slice.unsqueeze!1 == [[[0, 1, 2]],
                                            [[3, 4, 5]]]);
    assert(iota(2, 3).slice.unsqueeze!2 == [[[0], [1], [2]], 
                                            [[3], [4], [5]]]);

    assert(iota(1, 3, 4).slice.squeeze!0.shape == [3, 4]);
    assert(iota(3, 1, 4).slice.squeeze!1.shape == [3, 4]);
    assert(iota(3, 4, 1).slice.squeeze!(-1).shape == [3, 4]);
}
