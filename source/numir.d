import std.array : array;
import std.range : repeat, take;


auto zeros(T=double)(size_t n) pure nothrow {
  return repeat(0.to!T, n).array;
}


import std.experimental.allocator.mallocator;


import mir.ndslice; //.algorithm;
import std.stdio;
import numir;

unittest
{
  /* Types
     np.ndarray | mir.ndslice.slice

     np.float32 | float
     np.float64 | double
     np.int8 	  | byte
     np.uint8 	| ubyte
     np.int16 	| short
     np.int32   | int
     np.int64 	| long

     see also https://dlang.org/spec/type.html
  */
}

auto empty(E=double, size_t N)(size_t[N] length...) {
  return uninitializedSlice!E(length);
}

auto empty_like(S)(S slice) {
  return empty!(DeepElementType!S)(slice.shape);
}

auto ones(E=double, size_t N)(size_t[N] length...) {
  return makeSlice!E(Mallocator.instance, [length], 1);
}


unittest {
  /* Constructors

     np.empty([2,2])  | numir.empty(2, 2), numir.empty([2, 2])
     np.empty_like(x) |	numir.empty_like(x)
     np.eye 	        | <WIP>
     np.identity 	    | <WIP>
     np.ones 	        | numir.ones
     np.ones_like 	torch.ones(x:size())
     np.zeros 	torch.zeros
     np.zeros_like 	torch.zeros(x:size())

     see also https://dlang.org/phobos/std_experimental_ndslice_slice.html
  */

  // np.empty
  auto e0 = empty([2 ,2]);
  assert(e0.shape == [2, 2]);
  e0[0, 0] += 1;
  auto e1 = empty_like(e0);
  assert(e1.shape == e0.shape);
  assert(e1 != e0);

  alias E0 = DeepElementType!(typeof(e0));
  alias E1 = DeepElementType!(typeof(e1));
  static assert(is(E0 == E1));

  // auto o0 = ones([2, 3]);
}
