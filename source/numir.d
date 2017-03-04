// -*- tab-width : 2 -*- ; mode : D -*-
module numir;
/*
  this library is motivated by
  https://github.com/torch/torch7/wiki/Torch-for-Numpy-users
 */

import mir.ndslice;
import mir.ndslice.algorithm : all;

import std.stdio;
import std.array : array;
import std.algorithm.iteration : map;

unittest
{
  /* Types

     np.ndarray | D
     -----------+--------
     np.float32 | float
     np.float64 | double
     np.int8    | byte
     np.uint8   | ubyte
     np.int16   | short
     np.int32   | int
     np.int64   | long

     see also https://dlang.org/spec/type.html
  */

  // nothing to test?
}


auto like(alias f, S)(S slice)
{
  return f!(DeepElementType!S)(slice.shape);
}

auto empty(E=double, size_t N)(size_t[N] length...)
{
  return uninitializedSlice!E(length);
}

auto empty_like(S)(S slice)
{
  return slice.like!empty;
}

auto inits(E, size_t N)(E init, size_t[N] length...)
{
  import std.experimental.allocator.mallocator : Mallocator;
  return makeSlice!E(Mallocator.instance, length, init).slice;
}

auto ones(E=double, size_t N)(size_t[N] length...)
{
  return inits!E(1, length);
}

auto ones_like(S)(S slice)
{
  return slice.like!ones;
}

auto zeros(E=double, size_t N)(size_t[N] length...)
{
  return inits!E(0, length);
}

auto zeros_like(S)(S slice)
{
  return slice.like!zeros;
}

auto eye(E=double)(size_t m, size_t n=0, long k=0)
{
  if (n == 0) n = m;
  auto z = zeros!E(m, n);
  z.diag(k)[] = 1;
  return z;
}

auto identity(E=double)(size_t n) {
  return eye!E(n);
}

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

     see also https://dlang.org/phobos/std_experimental_ndslice_slice.html
  */

  // np.empty
  assert(empty(2 ,3).shape == [2, 3]);
  auto e0 = empty([2 ,3]);
  assert(e0.shape == [2, 3]);

  e0[0, 0] += 1;
  auto e1 = empty_like(e0);
  assert(e1.shape == e0.shape);
  assert(e1 != e0);

  // np.empty_like
  alias E0 = DeepElementType!(typeof(e0));
  alias E1 = DeepElementType!(typeof(e1));
  static assert(is(E0 == E1));

  // eye
  assert(identity(2) == [[1.0, 0.0],
                         [0.0, 1.0]]);
  assert(eye(2, 3, 1) == [[0.0, 1.0, 0.0],
                          [0.0, 0.0, 1.0]]);


  // np.ones, ones_like
  auto o = ones(2, 3);
  assert(o.all!(x => x == 1));
  assert(o.shape == [2, 3]);
  assert(o == ones([2, 3]));
  assert(o == o.ones_like);

  // zeros
  auto z = zeros(2, 3);
  assert(z.all!(x => x == 0));
  assert(z.shape == [2, 3]);
  assert(z == zeros([2, 3]));
  assert(z == z.zeros_like);
}


unittest
{
  /* From existing data

     numpy                     | numir
     --------------------------+------------------------
     np.array([ [1,2],[3,4] ]) | sliced([ [1,2],[3,4] ])
     np.ascontiguousarray(x)   | x.assumeContiguous
     np.copy(x)                | ????
     np.fromfile(file)         | <WIP>
     np.concatenate            | <WIP>
   */

  auto m = sliced([ [1,2],[3,4] ]);
}


unittest
{
  /* Numerical Ranges

     numpy                | numir
     ---------------------+--------
     np.arange(10)        |
     np.arange(2, 3, 0.1) |
     np.linspace(1, 4, 6) |
     np.logspace          |

     memo: iotaSlice, iota?
  */
}


auto diag(S)(S s, long k=0)
{
  auto sk = k >= 0 ?  s[0 .. $, k .. $] : s[-k .. $, 0 .. $];
  return sk.diagonal;
}

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
  auto a = iota(2, 3).canonical;
  assert(a.diag == [0, 4]);
  assert(a.diag(1) == [1, 5]);
  assert(a.diag(-1) == [3]);
}

auto dtype(S)(S s)
{
  return typeid(DeepElementType!S);
}

auto ndim(S)(S s)
{
  return s.shape.length;
}

auto byteStrides(S)(S s) {
  import mir.ndslice.topology : map;
  enum b = DeepElementType!S.sizeof;
  return s.strides.sliced.map!(n => n * b).array;
}

auto size(S)(S s) {
  import std.algorithm : reduce;
  return s.shape.array.reduce!"a * b";
}

unittest
{
  /* Attributes

     numpy     | numir
     ----------+---------------
     x.shape   | x.shape
     x.strides | x.byteStrides (!) already, strides defined in mir
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
}


/// Shape Manipulation

/// Item selection and manipulation

/// Calculation

/// Arithmetic and comparison operations
