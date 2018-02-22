/++
Audio separation using STFT and non-negative matrix factorization

See_Also: https://github.com/r9y9/julia-nmf-ss-toy
+/

import std.stdio;
import std.array;
import std.format : format;
import std.file : exists;
import std.net.curl : download;
import std.complex : abs, arg, expi;
import std.typecons : tuple;

import mir.math : log, sum, sqrt;
import mir.ndslice : sliced, ndarray, map, transposed, reversed, slice, isSlice, maxPos;
import lubeck : mtimes;
import ggplotd.ggplotd : GGPlotD;
import ggplotd.axes : xaxisLabel, yaxisLabel;
import ggplotd.colour : colourGradient;
import ggplotd.colourspace : XYZ;

import numir;
import plot : plot1d, plot2d;
import numir.signal : blackman, hann, stft, istft;
import dffmpeg : Audio;

/++
Non-negative matrix factorization

Params:
    y = input mixed matrix with the shape of (ntime x nfreq)
    nbasis = number of basis vectors
    maxiter = the maximum number of iterations
    eps = numerical stability factor in the denominator

Returns:
    matrix tuple [h, u] where

    argmin_{h, u} ||y - h \times u||_2

    h = shape (ntime x nbasis)
    u = shape (nbasis x nfreq)
 +/
auto nmf(S)(S y, size_t nbasis, size_t maxiter=100, double eps=1e-21) if (isSlice!S)
{
    auto h = uniform(y.length!0, nbasis).slice;
    auto u = uniform(nbasis, y.length!1).slice;
    foreach (i; 0 .. maxiter)
    {
        h[] *= y.mtimes(u.transposed) / (h.mtimes(u).mtimes(u.transposed) + eps);
        u[] *= h.transposed.mtimes(y) / (h.transposed.mtimes(h).mtimes(u) + eps);
        u[] /= u.maxPos.first;
        if (i % 10 == 0)
        {
            auto residual = y - h.mtimes(u);
            auto loss = sum!"fast"(residual * residual).sqrt;
            writefln!"L2 loss: %f at iter %d / %d"(loss, i, maxiter);
        }
    }
    return tuple!("h", "u")(h, u);
}

void main()
{
    // prepare audio
    auto filename = "test10k.wav";
    if (!filename.exists)
        download("https://raw.githubusercontent.com/ShigekiKarita/torch-nmf-ss-toy/master/test10k.wav",
                 filename);
    auto wav = Audio!short().load(filename);
    writeln(wav.now);

    // plot waveform
    auto xs = wav.data.sliced;
    GGPlotD().plot1d(xs, 1.0, 0.1).save("mixed.png");

    // STFT
    auto zs = stft(xs, 512); // take real part
    auto ys = zs[0..$, 0..$/2].map!abs.slice;
    auto phase = zs[0..$, 0..$/2].map!arg.map!expi.slice;

    // plot STFT result
    auto logy = ys.map!log.reversed!(1).transposed;
    GGPlotD().plot2d(logy)
        .put("white-cornflowerBlue-crimson".colourGradient!XYZ)
        .put("time".xaxisLabel)
        .put("freq".yaxisLabel)
        .save("mixed-stft.png");

    // NMF
    auto nbasis = 4;
    auto factorized = nmf(ys, nbasis);

    // plot NMF time/freq basis
    GGPlotD hfig, ufig;
    hfig = hfig.plot2d(logy * 0.5);
    ufig = ufig.plot2d(logy.transposed.reversed!(1, 0) * 0.5);
    auto lmax = logy.maxPos.first;
    auto hmax = cast(double) ys.front.length / factorized.h.maxPos.first;
    auto umax = cast(double) ys.length / factorized.u.maxPos.first;
    foreach (i; 0..nbasis)
    {
        auto color = lmax * (i + 1) / nbasis + lmax;
        hfig = hfig.plot1d(hmax * factorized.h[0..$, i], color);
        ufig = ufig.plot1d(umax * factorized.u[i, 0..$], color);
    }
    auto cg = "white-orange-green-cornflowerBlue-crimson";
    hfig.put(cg.colourGradient!XYZ)
        .put("time".xaxisLabel)
        .put("gain".yaxisLabel)
        .save("time_basis.png");
    ufig.put(cg.colourGradient!XYZ)
        .put("freq".xaxisLabel)
        .put("gain".yaxisLabel)
        .save("freq_basis.png");

    // generate separated audio
    auto info = wav.now;
    GGPlotD facwav;
    foreach (k; 0..nbasis)
    {
        auto y = factorized.h[0..$, k..k+1].mtimes(factorized.u[k..k+1, 0..$]) * phase;
        auto ydouble = concatenate!1(y, y.reversed!1);
        auto yk = istft(y).map!"a.re";
        facwav = facwav.plot1d(yk, cast(double) k / nbasis, 0.1);
        wav.data = yk.map!(a => a.to!short).array;
        wav.save("%d.wav".format(k));
    }
    facwav
        .put("time".xaxisLabel)
        .put("gain".yaxisLabel)
        .save("factorized.png");
}
