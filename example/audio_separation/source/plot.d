module plot;

/++
GGPlot helper functions
 +/
import ggplotd.aes : aes;
import ggplotd.ggplotd : GGPlotD, putIn;
import ggplotd.geom : geomPoint, geomRectangle;


auto geomPointRect(AES)(AES aesRange)
{
    import ggplotd.aes : aes, Pixel, DefaultValues, merge;
    import std.algorithm : cartesianProduct, map;
    import ggplotd.range : mergeRange;

    return DefaultValues.mergeRange(aesRange)
        .map!((a) => a.merge(aes!("sizeStore", "width", "height", "fill")
                             (a.size, a.width, a.height, a.alpha)))
        .geomRectangle;
}

auto plot2d(T)(GGPlotD gg, T array2d)
{
    import std.algorithm : cartesianProduct, map;
    import std.range : iota;
    auto xstep = 1;
    auto ystep = 1;
    auto xlen = array2d[0].length;
    auto ylen = array2d.length;
    auto xys = cartesianProduct(xlen.iota, ylen.iota);
    return xys.map!(xy => aes!("x", "y", "colour", "size", "width",
            "height")(xy[0], xy[1], array2d[$-1-xy[1]][xy[0]], 1.0, xstep, ystep))
        .geomPointRect
        .putIn(gg);
}

auto plot1d(T, C)(GGPlotD gg, T xs, C color=0, double size=1.0)
{
    import std.range : enumerate;
    import std.algorithm : map;
    import ggplotd.geom : geomLine;

    return xs.enumerate
        .map!(a => aes!("x", "y", "colour", "size")(a[0], a[1], color, size))
        .geomLine.putIn(gg);
}
