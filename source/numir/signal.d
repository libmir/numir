/++
Signal processing package
 +/

module numir.signal;

import mir.ndslice.slice : isSlice, DeepElementType;
import std.traits : isFloatingPoint;
import numir.core : Ndim;

/++
Classic Blackman window slice generator

Params:
     n = length of window
     a0 = window parameter
     a1 = window parameter
     a2 = window parameter

Returns: window weight slice

See_Also:
    https://ccrma.stanford.edu/~jos/sasp/Blackman_Window_Family.html
    https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.blackman.html
 +/
pure nothrow @nogc @safe
auto blackman(size_t n, double a0=0.42, double a1=0.5, double a2=0.08)
{
    import mir.ndslice.topology : iota, map;
    import mir.math.common : cos;
    import std.math : PI;
    immutable t = 2.0 * PI / (n - 1);
    auto ks = iota(n);
    return a0 - a1 * map!cos(t * ks) + a2 * map!cos(t * 2 * ks);
}

/++
Hann window slice generator

Params:
    n = length of window
    a = window parameter
    b = window parameter
Returns: window weight slice

See_Also:
    https://ccrma.stanford.edu/~jos/sasp/Generalized_Hamming_Window_Family.html
    https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.hann.html
 +/
pure nothrow @nogc @safe
auto hann(size_t n, double a = 0.5, double b = 0.25)
{
    import mir.math.common : cos;
    import mir.ndslice.topology : iota, map;
    import std.math : PI;
    immutable t = 2.0 * PI / (n - 1);
    return a - b / 2 * map!cos(t * iota(n));
}

///
pure nothrow @nogc @safe
unittest
{
    import numir.signal;
    import std.meta : AliasSeq;
    import mir.ndslice : maxIndex;
    import std.numeric : approxEqual;
    // test windows are symmetry and peaked at median
    auto n = 11;
    static foreach (wfun; AliasSeq!(blackman, hann))
    {{
        auto w = wfun(n);
        assert(w.maxIndex[0] == n / 2);
        foreach (i; 0 .. n / 2 - 1)
        {
            assert(w[i].approxEqual(w[$ - 1 - i]));
        }
    }}
}

/++
Split (window and stride) time frames for FFT or convolutions

Params:
     xs = input slice
     width = length of each segment
     stride = the number of skipped frames between the head of split slices
Returns: slice of split (windowed and strided) slices
 +/
pure nothrow @safe @nogc
auto splitFrames(Xs)(Xs xs, size_t width, size_t stride)
{
    import mir.ndslice.topology : windows; // , s = stride;
    import mir.ndslice.dynamic : strided;
    immutable nframes = (xs.length - width) / stride + 1;
    return xs.windows(width).strided!0(stride);
}

///
pure nothrow @safe @nogc
unittest
{
    import numir.signal;
    import mir.ndslice.topology : iota;
    static immutable ys = [[0,1,2], [2,3,4]];
    assert(iota(6).splitFrames(3, 2) == ys);
}


/++
Computes the short time Fourier transform

Params:
    xs = input 1d slice with the shape (ntimes,)
    nperseg = (default 256) short-time frame width for each FFT segment
    noverlap = (default nperseg / 2) short-time frame overlapped length for each FFT segment
Returns: comlex 2d slice (nframes, nfreqs=nperseg)
See_Also:
    https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.stft.html
 +/
auto stft(alias windowFun=hann, Xs)(Xs xs, size_t nperseg, size_t noverlap)
    if (isSlice!Xs && Ndim!Xs == 1)
out(ret)
{
    static assert(Ndim!(typeof(return)) == 2);
    assert(ret.length!1 == nperseg);
}
do
{
    import std.numeric : fft;
    import std.complex : Complex;
    import numir : empty;
    auto frames = splitFrames(xs, nperseg, nperseg - noverlap);
    auto ret = empty!(Complex!double)(frames.length, nperseg);
    auto window = windowFun(nperseg);
    foreach (i; 0 .. frames.length)
    {
        fft(frames[i] * window, ret[i]);
    }
    return ret;
}

///ditto
auto stft(alias windowFun=hann, Xs)(Xs xs, size_t nperseg=256)
    if (isSlice!Xs && Ndim!Xs == 1)
{
    return stft!(windowFun, Xs)(xs, nperseg, nperseg / 2);
}

/++
Computes the inverse short time Fourier transform

Params:
    xs = input 2d complex slice with the shape (ntimes, nfreq)
    noverlap = (default nperseg / 2) short-time frame overlapped length for each FFT segment
Returns 1d real slice with the shape (ntimes,)
See_Also:
    https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.stft.html
 +/
auto istft(alias windowFun=hann, Xs)(Xs xs, size_t noverlap)
    if (isSlice!Xs && Ndim!Xs == 2)
{
    import std.array : array;
    import std.numeric : inverseFft;
    import std.complex : Complex;
    import mir.ndslice.topology : iota;
    import mir.ndslice.allocation : slice, ndarray, sliced;
    import numir : empty;

    auto nperseg = xs.length!1; // = nfreqs
    auto nstride = nperseg - noverlap;
    auto ntimes = nperseg + (xs.length!0 - 1) * nstride;

    auto ret = empty!(Complex!double)(ntimes);
    auto windowsum = empty(ntimes);
    auto window = windowFun(nperseg).slice;
    auto windowsquare = slice(window * window);
    auto invbuf = empty!(Complex!double)(nperseg);
    auto xbuf = empty!(Complex!double)(nperseg);
    foreach (i; 0 .. xs.length!0)
    {
        inverseFft(xs[i].array, invbuf); // TODO remove .array
        auto ids = iota([nperseg], i * nstride);
        ret[ids] += invbuf * window;
        windowsum[ids] += windowsquare;
    }
    foreach (i; 0 .. ret.length)
    {
        if (windowsum[i] > 1e-7)
        {
            ret[i] /= windowsum[i];
        }
    }
    return ret;
}

///ditto
auto istft(alias windowFun=hann, Xs)(Xs xs)
    if (isSlice!Xs && Ndim!Xs == 2)
{
    return istft!(windowFun, Xs)(xs, xs.length!1 / 2); // default noverlap
}

/// test stft-istft health
unittest
{
    import std.complex;
    import std.stdio;
    import mir.ndslice : map, sliced;
    import numir.testing : approxEqual;
    // first 16 samples from https://raw.githubusercontent.com/ShigekiKarita/torch-nmf-ss-toy/master/test10k.wav
    auto xs = [-10, 15, 106, -1, -655, -1553, -1501, -522,
               -106, 831, 1250, 381, 1096, 2302, 2686, 2427].sliced;
    // need larger overlaps to revert well
    auto ys = stft(xs, 8, 7);
    auto ixs = istft(ys, 7).map!(c => c.re);
    assert(approxEqual(ixs, xs));
}
