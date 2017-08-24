/++
This is a submodule of numir to provide formatting for ndslices.

Note: This relies on the formatting functionality from Phobos, the D standard
library. As of this writing, it relies on the Garbage Collector and potentially 
other non-Better C functionality in D.

+/
module numir.format;

import mir.ndslice : SliceKind, Slice;

///
private string hyphenline(size_t n) @safe pure nothrow
{
    import std.array : join;
    
    auto hyphens(size_t n) @safe pure nothrow
    {
        import std.array : replicate;
        
        return replicate("-", n);
    }
    
    return join([" ", hyphens(n - 2), " "]);
}

@safe pure nothrow
unittest
{
    size_t n = 5;
    
    assert(hyphenline(n) == " --- ");
    assert(hyphenline(n + 1) == " ---- ");
    assert(hyphenline(n - 1) == " -- ");
}

///
private string dashline(size_t n) @safe pure nothrow
{
    string dashes(size_t n) @safe pure nothrow
    {
        import std.array : replicate;
        
        return replicate("- ", n);
    }

    size_t dashmatchhyphenlen(size_t n) @nogc @safe pure nothrow
    {
        return (n - 1) / 2;
    }
    
    string dashlineImpl(size_t n) @safe pure nothrow
    {
        import std.array : join;
        
        return join([" ", dashes(n)]);
    }

    return dashlineImpl(dashmatchhyphenlen(n));
}

@safe pure nothrow
unittest
{
    size_t n = 5;
    
    assert(dashline(n) == " - - ");
    assert(dashline(n + 1) == " - - ");
    assert(dashline(n - 1) == " - ");
}

///
private size_t stringWidth(string x)
{
    import std.algorithm : findSplitBefore;
    
    return x.findSplitBefore("\n")[0].length;
}

unittest
{
    string test = "123\n";
    
    assert(test.stringWidth == 3);
}

///
private string formatRow(alias fmt, SliceKind kind, Iterator)
                                                (Slice!(kind, [1], Iterator) sl)
{
    import std.format : format;
    import mir.ndslice.topology : map;
    import mir.ndslice.allocation : ndarray;
    import std.array : appender, join;
        
    auto buf = appender!string();
    buf.put("|");
    buf.put(join(sl.map!(a => format!(fmt)(a)).ndarray));
    buf.put(" |");
    
    return buf.data;
}

///
private string formatRow(SliceKind kind, Iterator, Char)
                                (Slice!(kind, [1], Iterator) sl, in Char[] fmt)
{
    import std.format : format;
    import mir.ndslice.topology : map;
    import mir.ndslice.allocation : ndarray;
    import std.array : appender, join;
        
    auto buf = appender!string();
    buf.put("|");
    buf.put(join(sl.map!(a => format(fmt, a)).ndarray));
    buf.put(" |");
    
    return buf.data;
}

unittest
{
    import mir.ndslice.topology : iota;
    import mir.ndslice.slice : sliced;
    
    mixin formatRowsTest;
    
    assert(1.iota.formatRow!(" %s") == testIota1);
    assert(3.iota.formatRow!(" %s") == testIota3);
    assert(5.iota.formatRow!(" %s") == testIota5);
    assert([1, 20, 300].sliced.formatRow(" %s") == "| 1 20 300 |");

    assert(1.iota.formatRow(" %s") == testIota1);
    assert(3.iota.formatRow(" %s") == testIota3);
    assert(5.iota.formatRow(" %s") == testIota5);
    assert([1, 20, 300].sliced.formatRow(" %s") == "| 1 20 300 |");
}

///
private string formatRowsImpl(alias fmt, 
                                    SliceKind kind, size_t[] packs, Iterator)
                                            (Slice!(kind, packs, Iterator) sl)
    if (packs.length == 1 && packs[0] > 1)
{
    import std.array : array, join, appender;
    import mir.ndslice.allocation : ndarray;
    import mir.ndslice.topology : map, byDim;
    
    size_t N = packs[0];
    
    string[] slFmt = sl
                    .byDim!0
                    .map!(a => a.formatRows!(fmt))
                    .ndarray;
    
    string dash = dashline(slFmt[0].stringWidth);
    
    //This adds dashes to buf when N>2, with more dashes the higher N is
    void bufDash(T)(T buf, size_t N)
    {
        while (N > 2) 
        {
            buf.put("\n");
            buf.put(dash);
            N--;
        }
    }
    
    auto buf = appender!string();
    foreach (size_t i, string t; slFmt)
    {
        buf.put(t);
        if (i < (slFmt.length - 1))
        {
            bufDash(buf, N);
            buf.put("\n");
        }
    }
    return buf.data;
}

///
private string formatRowsImpl(SliceKind kind, size_t[] packs, Iterator, Char)
                               (Slice!(kind, packs, Iterator) sl, in Char[] fmt)
    if (packs.length == 1 && packs[0] > 1)
{
    import std.array : array, join, appender;
    import mir.ndslice.allocation : ndarray;
    import mir.ndslice.topology : map, byDim;
    
    size_t N = packs[0];
    
    string[] slFmt = sl
                    .byDim!0
                    .map!(a => a.formatRows(fmt))
                    .ndarray;
    
    string dash = dashline(slFmt[0].stringWidth);
    
    //This adds dashes to buf when N>2, with more dashes the higher N is
    void bufDash(T)(T buf, size_t N)
    {
        while (N > 2) 
        {
            buf.put("\n");
            buf.put(dash);
            N--;
        }
    }
    
    auto buf = appender!string();
    foreach (size_t i, string t; slFmt)
    {
        buf.put(t);
        if (i < (slFmt.length - 1))
        {
            bufDash(buf, N);
            buf.put("\n");
        }
    }
    return buf.data;
}

unittest
{
    import mir.ndslice.topology : iota;

    mixin formatRowsTest;

    assert([3, 2].iota.formatRowsImpl!(" %s") == testIota32);
    assert([2, 3].iota.formatRowsImpl!(" %s") == testIota23);
    assert([4, 3].iota.formatRowsImpl!(" %2s") == testIota43);
    assert([4, 3, 2].iota.formatRowsImpl!(" %2s") == testIota432);
    assert([5, 4, 3, 2].iota.formatRowsImpl!(" %3s") == testIota5432);
    
    assert([3, 2].iota.formatRowsImpl(" %s") == testIota32);
    assert([2, 3].iota.formatRowsImpl(" %s") == testIota23);
    assert([4, 3].iota.formatRowsImpl(" %2s") == testIota43);
    assert([4, 3, 2].iota.formatRowsImpl(" %2s") == testIota432);
    assert([5, 4, 3, 2].iota.formatRowsImpl(" %3s") == testIota5432);
}

///
private string formatRows(alias fmt, SliceKind kind, size_t[] packs, Iterator)
                                          (Slice!(kind, packs, Iterator) sl)
{
    import mir.ndslice.topology : unpack;
    import mir.math.sum : sum;
    
    static immutable packsSum = packs.sum;
    auto temp = sl.unpack;
    
    static if (packsSum == 1)
    {
        return temp.formatRow!(fmt);
    }
    else static if (packsSum >= 2)
    {
        return temp.formatRowsImpl!(fmt);
    }
    else
    {
        static assert(0, "Should not be here");
    }
}

///
private string formatRows(SliceKind kind, size_t[] packs, Iterator, Char)
                              (Slice!(kind, packs, Iterator) sl, in Char[] fmt)
{
    import mir.ndslice.topology : unpack;
    import mir.math.sum : sum;
    
    static immutable packsSum = packs.sum;
    auto temp = sl.unpack;
    
    static if (packsSum == 1)
    {
        return temp.formatRow(fmt);
    }
    else static if (packsSum >= 2)
    {
        return temp.formatRowsImpl(fmt);
    }
    else
    {
        static assert(0, "Should not be here");
    }
}

unittest
{
    import mir.ndslice.topology : iota;
    
    mixin formatRowsTest;
    
    assert(1.iota.formatRows!(" %s") == testIota1);
    assert(3.iota.formatRows!(" %s") == testIota3);
    assert(5.iota.formatRows!(" %s") == testIota5);
    assert([3, 2].iota.formatRows!(" %s") == testIota32);
    assert([2, 3].iota.formatRows!(" %s") == testIota23);
    assert([4, 3].iota.formatRows!(" %2s") == testIota43);
    assert([4, 3, 2].iota.formatRows!(" %2s") == testIota432);
    assert([5, 4, 3, 2].iota.formatRows!(" %3s") == testIota5432);

    assert(1.iota.formatRows(" %s") == testIota1);
    assert(3.iota.formatRows(" %s") == testIota3);
    assert(5.iota.formatRows(" %s") == testIota5);
    assert([3, 2].iota.formatRows(" %s") == testIota32);
    assert([2, 3].iota.formatRows(" %s") == testIota23);
    assert([4, 3].iota.formatRows(" %2s") == testIota43);
    assert([4, 3, 2].iota.formatRows(" %2s") == testIota432);
    assert([5, 4, 3, 2].iota.formatRows(" %3s") == testIota5432);
}

private string addTopBottomHyphen(string x)
{
    import std.array : appender;
    
    auto rowWidth = x.stringWidth;
    
    auto buf = appender!string();
    buf.put(rowWidth.hyphenline);
    buf.put("\n");
    buf.put(x);
    buf.put("\n");
    buf.put(rowWidth.hyphenline);
    
    return buf.data;
}

/++
Formats ndslice to string

Params:
    fmt = string representing the format style (follows std.format style)
    sl = input slice
Returns:
    string of formatted slice

See_also: 
    std.format
+/
string formatSlice(alias fmt, SliceKind kind, size_t[] packs, Iterator)
                                          (Slice!(kind, packs, Iterator) sl)
{
    import mir.ndslice.topology : unpack;
    
    return sl.unpack.formatRows!(fmt).addTopBottomHyphen;
}

string formatSlice(SliceKind kind, size_t[] packs, Iterator, Char)
                               (Slice!(kind, packs, Iterator) sl, in Char[] fmt)
{
    import mir.ndslice.topology : unpack;
    
    return sl.unpack.formatRows(fmt).addTopBottomHyphen;
}

///
unittest
{
    import mir.ndslice.topology : iota;
    
    assert(1.iota.formatSlice!(" %s") ==
        " --- \n" ~ 
        "| 0 |\n" ~
        " --- "
    );
    
    assert(5.iota.formatSlice(" %s") == 
        " ----------- \n" ~ 
        "| 0 1 2 3 4 |\n" ~
        " ----------- " 
    );
    
    assert([3, 2].iota.formatSlice!(" %s") == 
        " ----- \n" ~ 
        "| 0 1 |\n" ~ 
        "| 2 3 |\n" ~ 
        "| 4 5 |\n" ~ 
        " ----- "
    );
    
    assert([2, 3].iota.formatSlice(" %s") == 
        " ------- \n" ~ 
        "| 0 1 2 |\n" ~ 
        "| 3 4 5 |\n" ~ 
        " ------- "
    );
     
    assert([5, 4, 3, 2].iota.formatSlice!(" %3s") == 
        " --------- \n" ~ 
        "|   0   1 |\n" ~ 
        "|   2   3 |\n" ~ 
        "|   4   5 |\n" ~ 
        " - - - - - \n" ~ 
        "|   6   7 |\n" ~ 
        "|   8   9 |\n" ~ 
        "|  10  11 |\n" ~ 
        " - - - - - \n" ~ 
        "|  12  13 |\n" ~ 
        "|  14  15 |\n" ~ 
        "|  16  17 |\n" ~ 
        " - - - - - \n" ~ 
        "|  18  19 |\n" ~ 
        "|  20  21 |\n" ~ 
        "|  22  23 |\n" ~ 
        " - - - - - \n" ~ 
        " - - - - - \n" ~ 
        "|  24  25 |\n" ~ 
        "|  26  27 |\n" ~ 
        "|  28  29 |\n" ~ 
        " - - - - - \n" ~ 
        "|  30  31 |\n" ~ 
        "|  32  33 |\n" ~ 
        "|  34  35 |\n" ~ 
        " - - - - - \n" ~ 
        "|  36  37 |\n" ~ 
        "|  38  39 |\n" ~ 
        "|  40  41 |\n" ~ 
        " - - - - - \n" ~ 
        "|  42  43 |\n" ~ 
        "|  44  45 |\n" ~ 
        "|  46  47 |\n" ~ 
        " - - - - - \n" ~ 
        " - - - - - \n" ~ 
        "|  48  49 |\n" ~ 
        "|  50  51 |\n" ~ 
        "|  52  53 |\n" ~ 
        " - - - - - \n" ~ 
        "|  54  55 |\n" ~ 
        "|  56  57 |\n" ~ 
        "|  58  59 |\n" ~ 
        " - - - - - \n" ~ 
        "|  60  61 |\n" ~ 
        "|  62  63 |\n" ~ 
        "|  64  65 |\n" ~ 
        " - - - - - \n" ~ 
        "|  66  67 |\n" ~ 
        "|  68  69 |\n" ~ 
        "|  70  71 |\n" ~ 
        " - - - - - \n" ~ 
        " - - - - - \n" ~ 
        "|  72  73 |\n" ~ 
        "|  74  75 |\n" ~ 
        "|  76  77 |\n" ~ 
        " - - - - - \n" ~ 
        "|  78  79 |\n" ~ 
        "|  80  81 |\n" ~ 
        "|  82  83 |\n" ~ 
        " - - - - - \n" ~ 
        "|  84  85 |\n" ~ 
        "|  86  87 |\n" ~ 
        "|  88  89 |\n" ~ 
        " - - - - - \n" ~ 
        "|  90  91 |\n" ~ 
        "|  92  93 |\n" ~ 
        "|  94  95 |\n" ~ 
        " - - - - - \n" ~ 
        " - - - - - \n" ~ 
        "|  96  97 |\n" ~ 
        "|  98  99 |\n" ~ 
        "| 100 101 |\n" ~ 
        " - - - - - \n" ~ 
        "| 102 103 |\n" ~ 
        "| 104 105 |\n" ~ 
        "| 106 107 |\n" ~ 
        " - - - - - \n" ~ 
        "| 108 109 |\n" ~ 
        "| 110 111 |\n" ~ 
        "| 112 113 |\n" ~ 
        " - - - - - \n" ~ 
        "| 114 115 |\n" ~ 
        "| 116 117 |\n" ~ 
        "| 118 119 |\n" ~ 
        " --------- "
    );
}

unittest
{
    import mir.ndslice.topology : iota;
    
    mixin formatSliceTest;
    
    assert(1.iota.formatSlice!(" %s") == testIota1Final);
    assert(3.iota.formatSlice!(" %s") == testIota3Final);
    assert(5.iota.formatSlice!(" %s") == testIota5Final);
    assert([3, 2].iota.formatSlice!(" %s") == testIota32Final);
    assert([2, 3].iota.formatSlice!(" %s") == testIota23Final);
    assert([4, 3].iota.formatSlice!(" %2s") == testIota43Final);
    assert([5, 4, 3, 2].iota.formatSlice!(" %3s") == testIota5432Final);
    
    assert(1.iota.formatSlice(" %s") == testIota1Final);
    assert(3.iota.formatSlice(" %s") == testIota3Final);
    assert(5.iota.formatSlice(" %s") == testIota5Final);
    assert([3, 2].iota.formatSlice(" %s") == testIota32Final);
    assert([2, 3].iota.formatSlice(" %s") == testIota23Final);
    assert([4, 3].iota.formatSlice(" %2s") == testIota43Final);
    assert([5, 4, 3, 2].iota.formatSlice(" %3s") == testIota5432Final);
}

///
unittest
{
    import mir.ndslice.topology : iota;
    import mir.ndslice.slice : sliced;
    import std.datetime: Date;
    import std.format : format;
    
    auto data = [0.12, 3.12, 6.40].sliced;
    auto time = [Date(2017, 01, 01),
                 Date(2017, 03, 01),
                 Date(2017, 04, 01)].sliced;
    
    assert(data.formatSlice!(" %s") ==
        " --------------- \n" ~ 
        "| 0.12 3.12 6.4 |\n" ~
        " --------------- "
    );
    assert(data.formatSlice!(" %.2f") ==
        " ---------------- \n" ~ 
        "| 0.12 3.12 6.40 |\n" ~
        " ---------------- "
    );
    
    assert(data.formatSlice!(" %.2e") ==
        " ---------------------------- \n" ~ 
        "| 1.20e-01 3.12e+00 6.40e+00 |\n" ~
        " ---------------------------- "
    );
    
    assert(time.formatSlice!(" %s") ==
        " ------------------------------------- \n" ~ 
        "| 2017-Jan-01 2017-Mar-01 2017-Apr-01 |\n" ~
        " ------------------------------------- "
    );
}

unittest
{
    import mir.ndslice.topology : iota;
    import mir.ndslice.slice : sliced;
    import std.datetime: Date;
    import std.format : format;
    
    auto data = [0.12, 3.12, 6.40].sliced;
    auto time = [Date(2017, 01, 01),
                 Date(2017, 03, 01),
                 Date(2017, 04, 01)].sliced;
    
    assert(data.formatSlice(" %s") ==
        " --------------- \n" ~ 
        "| 0.12 3.12 6.4 |\n" ~
        " --------------- "
    );
    assert(data.formatSlice(" %.2f") ==
        " ---------------- \n" ~ 
        "| 0.12 3.12 6.40 |\n" ~
        " ---------------- "
    );
    
    assert(data.formatSlice(" %.2e") ==
        " ---------------------------- \n" ~ 
        "| 1.20e-01 3.12e+00 6.40e+00 |\n" ~
        " ---------------------------- "
    );
    
    assert(time.formatSlice(" %s") ==
        " ------------------------------------- \n" ~ 
        "| 2017-Jan-01 2017-Mar-01 2017-Apr-01 |\n" ~
        " ------------------------------------- "
    );
}

// Testing packed versions
unittest
{
    import mir.ndslice.topology : iota, pack, ipack;
    
    mixin formatSliceTest;

    assert([3, 2].iota.pack!1.formatSlice!(" %s") == testIota32Final);
    assert([3, 2].iota.ipack!1.formatSlice!(" %s") == testIota32Final);
    assert([4, 3, 2].iota.formatSlice!(" %2s") == testIota432Final);
    assert([4, 3, 2].iota.pack!1.formatSlice!(" %2s") == testIota432Final);
    assert([4, 3, 2].iota.pack!2.formatSlice!(" %2s") == testIota432Final);
    assert([4, 3, 2].iota.ipack!1.formatSlice!(" %2s") == testIota432Final);
    assert([4, 3, 2].iota.ipack!2.formatSlice!(" %2s") == testIota432Final);
    assert([5, 4, 3, 2].iota.pack!1.formatSlice!(" %3s") == testIota5432Final);
    assert([5, 4, 3, 2].iota.pack!2.formatSlice!(" %3s") == testIota5432Final);
    assert([5, 4, 3, 2].iota.pack!3.formatSlice!(" %3s") == testIota5432Final);
    assert([5, 4, 3, 2].iota.ipack!1.formatSlice!(" %3s") == testIota5432Final);
    assert([5, 4, 3, 2].iota.ipack!2.formatSlice!(" %3s") == testIota5432Final);
    assert([5, 4, 3, 2].iota.ipack!3.formatSlice!(" %3s") == testIota5432Final);


    assert([3, 2].iota.pack!1.formatSlice(" %s") == testIota32Final);
    assert([3, 2].iota.ipack!1.formatSlice(" %s") == testIota32Final);
    assert([4, 3, 2].iota.formatSlice(" %2s") == testIota432Final);
    assert([4, 3, 2].iota.pack!1.formatSlice(" %2s") == testIota432Final);
    assert([4, 3, 2].iota.pack!2.formatSlice(" %2s") == testIota432Final);
    assert([4, 3, 2].iota.ipack!1.formatSlice(" %2s") == testIota432Final);
    assert([4, 3, 2].iota.ipack!2.formatSlice(" %2s") == testIota432Final);
    assert([5, 4, 3, 2].iota.pack!1.formatSlice(" %3s") == testIota5432Final);
    assert([5, 4, 3, 2].iota.pack!2.formatSlice(" %3s") == testIota5432Final);
    assert([5, 4, 3, 2].iota.pack!3.formatSlice(" %3s") == testIota5432Final);
    assert([5, 4, 3, 2].iota.ipack!1.formatSlice(" %3s") == testIota5432Final);
    assert([5, 4, 3, 2].iota.ipack!2.formatSlice(" %3s") == testIota5432Final);
    assert([5, 4, 3, 2].iota.ipack!3.formatSlice(" %3s") == testIota5432Final);
}

version(unittest)
{
    mixin template formatRowsTest()
    {
        string testIota1 =
            "| 0 |";
    
        string testIota3 =
            "| 0 1 2 |";
        
        string testIota5 =
            "| 0 1 2 3 4 |";
    
        string testIota32 =
            "| 0 1 |\n" ~ 
            "| 2 3 |\n" ~ 
            "| 4 5 |";
                        
        string testIota23 =
            "| 0 1 2 |\n" ~ 
            "| 3 4 5 |";
                         
        string testIota43 = 
            "|  0  1  2 |\n" ~ 
            "|  3  4  5 |\n" ~ 
            "|  6  7  8 |\n" ~ 
            "|  9 10 11 |";
            
        string testIota432 = 
            "|  0  1 |\n" ~ 
            "|  2  3 |\n" ~ 
            "|  4  5 |\n" ~ 
            " - - - - \n" ~ 
            "|  6  7 |\n" ~ 
            "|  8  9 |\n" ~ 
            "| 10 11 |\n" ~ 
            " - - - - \n" ~ 
            "| 12 13 |\n" ~ 
            "| 14 15 |\n" ~ 
            "| 16 17 |\n" ~ 
            " - - - - \n" ~ 
            "| 18 19 |\n" ~ 
            "| 20 21 |\n" ~ 
            "| 22 23 |";
            
        string testIota5432 = 
            "|   0   1 |\n" ~ 
            "|   2   3 |\n" ~ 
            "|   4   5 |\n" ~ 
            " - - - - - \n" ~ 
            "|   6   7 |\n" ~ 
            "|   8   9 |\n" ~ 
            "|  10  11 |\n" ~ 
            " - - - - - \n" ~ 
            "|  12  13 |\n" ~ 
            "|  14  15 |\n" ~ 
            "|  16  17 |\n" ~ 
            " - - - - - \n" ~ 
            "|  18  19 |\n" ~ 
            "|  20  21 |\n" ~ 
            "|  22  23 |\n" ~ 
            " - - - - - \n" ~ 
            " - - - - - \n" ~ 
            "|  24  25 |\n" ~ 
            "|  26  27 |\n" ~ 
            "|  28  29 |\n" ~ 
            " - - - - - \n" ~ 
            "|  30  31 |\n" ~ 
            "|  32  33 |\n" ~ 
            "|  34  35 |\n" ~ 
            " - - - - - \n" ~ 
            "|  36  37 |\n" ~ 
            "|  38  39 |\n" ~ 
            "|  40  41 |\n" ~ 
            " - - - - - \n" ~ 
            "|  42  43 |\n" ~ 
            "|  44  45 |\n" ~ 
            "|  46  47 |\n" ~ 
            " - - - - - \n" ~ 
            " - - - - - \n" ~ 
            "|  48  49 |\n" ~ 
            "|  50  51 |\n" ~ 
            "|  52  53 |\n" ~ 
            " - - - - - \n" ~ 
            "|  54  55 |\n" ~ 
            "|  56  57 |\n" ~ 
            "|  58  59 |\n" ~ 
            " - - - - - \n" ~ 
            "|  60  61 |\n" ~ 
            "|  62  63 |\n" ~ 
            "|  64  65 |\n" ~ 
            " - - - - - \n" ~ 
            "|  66  67 |\n" ~ 
            "|  68  69 |\n" ~ 
            "|  70  71 |\n" ~ 
            " - - - - - \n" ~ 
            " - - - - - \n" ~ 
            "|  72  73 |\n" ~ 
            "|  74  75 |\n" ~ 
            "|  76  77 |\n" ~ 
            " - - - - - \n" ~ 
            "|  78  79 |\n" ~ 
            "|  80  81 |\n" ~ 
            "|  82  83 |\n" ~ 
            " - - - - - \n" ~ 
            "|  84  85 |\n" ~ 
            "|  86  87 |\n" ~ 
            "|  88  89 |\n" ~ 
            " - - - - - \n" ~ 
            "|  90  91 |\n" ~ 
            "|  92  93 |\n" ~ 
            "|  94  95 |\n" ~ 
            " - - - - - \n" ~ 
            " - - - - - \n" ~ 
            "|  96  97 |\n" ~ 
            "|  98  99 |\n" ~ 
            "| 100 101 |\n" ~ 
            " - - - - - \n" ~ 
            "| 102 103 |\n" ~ 
            "| 104 105 |\n" ~ 
            "| 106 107 |\n" ~ 
            " - - - - - \n" ~ 
            "| 108 109 |\n" ~ 
            "| 110 111 |\n" ~ 
            "| 112 113 |\n" ~ 
            " - - - - - \n" ~ 
            "| 114 115 |\n" ~ 
            "| 116 117 |\n" ~ 
            "| 118 119 |";
    }
    
    mixin template formatSliceTest()
    {
        mixin formatRowsTest;
        
        string testIota1Final = testIota1.addTopBottomHyphen;
        string testIota3Final = testIota3.addTopBottomHyphen;
        string testIota5Final = testIota5.addTopBottomHyphen;
        string testIota32Final = testIota32.addTopBottomHyphen;
        string testIota23Final = testIota23.addTopBottomHyphen;
        string testIota43Final = testIota43.addTopBottomHyphen;
        string testIota432Final = testIota432.addTopBottomHyphen;
        string testIota5432Final = testIota5432.addTopBottomHyphen;
    }
    

}