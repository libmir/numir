/++
This is a submodule of numir to provide formatting for ndslices.
Note: This relies on the formatting functionality from Phobos, the D standard
library. As of this writing, parts of it rely on the Garbage Collector and
potentially other non-Better C functionality in D.
+/
module numir.format;

import mir.ndslice : SliceKind, Slice;
import std.traits : isSomeChar, isSomeString;

static if (__VERSION__ >= 2074)
    enum hasDVersion2074 = true;
else
    enum hasDVersion2074 = false;

static if (__VERSION__ >= 2076)
    enum hasDVersion2076 = true;
else
    enum hasDVersion2076 = false;

private struct Counter
{
    import std.range.primitives : isInputRange;
    import std.traits : isSomeChar, isSomeString;

    size_t _data;
    
    @property size_t data() @safe nothrow @nogc pure
    {
        return _data;
    }
    
    @safe nothrow @nogc pure
    void put(E)(E e)
        if(isSomeChar!E)
    {
        _data += 1;
    }

    @safe
    void put(E)(E e)
        if(isSomeString!E)
    {
        import std.uni : byGrapheme;
        import std.range.primitives : walkLength;

        _data += e.byGrapheme.walkLength;
    }

    @safe
    void put(Range)(Range items)
        if(isInputRange!Range &&
           is(typeof(Counter.init.put(Range.init.front))))
    {
        foreach(item; items)
            put(item);
    }
    
    void opOpAssign(string op : "~", U)(U rhs)
        if (__traits(compiles, put(rhs)))
    {
        put(rhs);
    }
    
    void clear() @safe nothrow @nogc pure
    {
        _data = 0;
    }
}

@safe nothrow @nogc pure
unittest
{
    Counter co;
    char data = 'e';
    co.put(data);
    assert(co.data == 1);
}

@safe nothrow @nogc pure
unittest
{
    Counter co;
    const(char) data = 'e';
    co.put(data);
    assert(co.data == 1);
}

@safe nothrow @nogc pure
unittest
{
    Counter co;
    immutable(char) data = 'e';
    co.put(data);
    assert(co.data == 1);
}

@safe nothrow @nogc pure
unittest
{
    Counter co;
    wchar data = 0x03C0;
    co.put(data);
    assert(co.data == 1);
}

@safe nothrow @nogc pure
unittest
{
    Counter co;
    dchar data = 0x00010437;
    co.put(data);
    assert(co.data == 1);
}

@safe
unittest
{
    Counter co;
    string data1 = "e";
    co.put(data1);
    assert(co.data == 1);
    string data2 = "sdfsdfs";
    co.put(data2);
    assert(co.data == 8);
}

@safe
unittest
{
    import std.utf : count, byCodeUnit;

    Counter co;
    wchar data1 = 0x03C0;
    co.put(data1);
    assert(co.data == 1);
    wstring data2 = "sdfsdfs"w;
    co.put(data2);
    assert(co.data == 8);
}

@safe
unittest
{
    Counter co;
    dchar data1 = 0x00010437;
    co.put(data1);
    assert(co.data == 1);
    dstring data2 = "sdfsdfs"d;
    co.put(data2);
    assert(co.data == 8);
}

@safe
unittest
{
    Counter co;
    string data1 = "e";
    co.put(data1);
    assert(co.data == 1);
    dstring data2 = "sdfsdfs"d;
    co.put(data2);
    assert(co.data == 8);
}

@safe
unittest
{
    Counter co;
    char data1 = 'e';
    co.put(data1);
    assert(co.data == 1);
    wstring data2 = "sdfsdfs"w;
    co.put(data2);
    assert(co.data == 8);
}

@safe
unittest
{
    Counter co;
    auto data = 'Ĉ';
    co.put(data);
    assert(co.data == 1);
}

@safe
unittest
{
    Counter co;
    auto data = `Ma Chérie`;
    co.put(data);
    assert(co.data == 9);
}

@safe
unittest
{
    Counter co;
    dstring data = `さいごの果実 / ミツバチと科学者`d;
    co.put(data);
    assert(co.data == 17);
}

@safe
unittest
{
    Counter co;
    string data = "å ø ∑ 😦";
    co.put(data);
    assert(co.data == 7);
}

@safe
unittest
{
    Counter co;
    wstring data = "å ø ∑ 😦";
    co.put(data);
    assert(co.data == 7);
}

@safe
unittest
{
    Counter co;
    dstring data = "å ø ∑ 😦";
    co.put(data);
    assert(co.data == 7);
}

@safe nothrow pure
private void formattedWriteHyphenline(alias fmt, Writer)
                                                 (auto ref Writer w, size_t len)
    if (isSomeString!(typeof(fmt)))
{
    alias String = typeof(fmt);
    enum String space = " ";
    enum String hyphen = "-";
    w.put(space);
    do
    {
        w.put(hyphen);
        len--;
    } while(len > 2);
    w.put(space);
}

@safe nothrow pure
private void formattedWriteHyphenline(Char, Writer)(auto ref Writer w,
                                                                     size_t len)
    if (isSomeChar!Char)
{
    enum Char space = ' ';
    enum Char hyphen = '-';
    w.put(space);
    do
    {
        w.put(hyphen);
        len--;
    } while(len > 2);
    w.put(space);
}

@safe nothrow pure
unittest
{
    import std.array : appender;

    auto w4 = appender!(string);
    w4.formattedWriteHyphenline!"%s"(4);
    assert(w4.data == " -- ");

    auto w7 = appender!(string);
    w7.formattedWriteHyphenline!"%s"(7);
    assert(w7.data == " ----- ");
}

@safe nothrow pure
unittest
{
    import std.array : appender;

    auto w4 = appender!(string);
    w4.formattedWriteHyphenline!char(4);
    assert(w4.data == " -- ");

    auto w7 = appender!(string);
    w7.formattedWriteHyphenline!char(7);
    assert(w7.data == " ----- ");
}

@safe nothrow pure
private void formattedWriteDashline(alias fmt, Writer)
                                                 (auto ref Writer w, size_t len)
    if (isSomeString!(typeof(fmt)))
{
    alias String = typeof(fmt);
    enum String space = " ";
    enum String dash = "-";
    w.put(space);
    do
    {
        w.put(dash);
        len--;
        if (len == 2)
            break;
        w.put(space);
        len--;
    } while(len > 2);
    w.put(space);
}

@safe nothrow pure
private void formattedWriteDashline(Char, Writer)(auto ref Writer w, size_t len)
    if (isSomeChar!Char)
{
    enum Char space = ' ';
    enum Char dash = '-';
    w.put(space);
    do
    {
        w.put(dash);
        len--;
        if (len == 2)
            break;
        w.put(space);
        len--;
    } while(len > 2);
    w.put(space);
}

@safe nothrow pure
unittest
{
    import std.array : appender;

    auto w4 = appender!(string);
    w4.formattedWriteDashline!"%s"(4);
    assert(w4.data == " -  ");

    auto w7 = appender!(string);
    w7.formattedWriteDashline!"%s"(7);
    assert(w7.data == " - - - ");
}

@safe nothrow pure
unittest
{
    import std.array : appender;

    auto w4 = appender!(string);
    w4.formattedWriteDashline!char(4);
    assert(w4.data == " -  ");

    auto w7 = appender!(string);
    w7.formattedWriteDashline!char(7);
    assert(w7.data == " - - - ");
}

@safe nothrow @nogc pure
private template deepFrontString(size_t N)
{
    static if (N >= 1)
    {
        enum string deepFrontString = "][0" ~ deepFrontString!(N - 1);
    }
    else
    {
        enum string deepFrontString = "";
    }
}

@safe nothrow @nogc pure
unittest
{
    assert(deepFrontString!0 == "");
    assert(deepFrontString!1 == "][0");
    assert(deepFrontString!2 == "][0][0");
}

@safe nothrow @nogc pure
private Slice!(kind, [1], Iterator) deepFront(SliceKind kind, size_t[1] packs,
                                                                       Iterator)
                                              (Slice!(kind, packs, Iterator) sl)
{
    static if (packs[0] == 1)
    {
        return sl;
    }
    else static if (packs[0] > 1)
    {
        return mixin("sl[0" ~ deepFrontString!(packs[0] - 2) ~ "]");
    }
    else
    {
        static assert("Should not be here");
    }
}

@safe nothrow @nogc pure
unittest
{
    import mir.ndslice : iota;
    auto data = [3, 2].iota;
    assert(data.deepFront == data.front);
}

@safe nothrow @nogc pure
unittest
{
    import mir.ndslice : iota;
    auto data = [4, 3, 2].iota;
    assert(data.deepFront == data[0][0]);
}

@safe nothrow @nogc pure
unittest
{
    import mir.ndslice : iota;
    auto data = [5, 4, 3, 2].iota;
    assert(data.deepFront == data[0][0][0]);
}

@safe nothrow @nogc pure
private typeof(fmt) formattedWriteRowString(alias fmt)()
    if (isSomeString!(typeof(fmt)))
{
    return "|%( " ~ fmt ~ "%) |";
}

@safe nothrow pure
private auto formattedWriteRowString(Char)(in Char[] fmt)
    if (isSomeChar!Char)
{
    return "|%( " ~ fmt ~ "%) |";
}

@safe nothrow @nogc pure
unittest
{
    assert(formattedWriteRowString!"%s" == "|%( " ~ "%s" ~ "%) |");
}

@safe nothrow pure
unittest
{
    import std.array : appender;
    auto w = appender!(string);

    assert(formattedWriteRowString("%s") == "|%( " ~ "%s" ~ "%) |");
}

static if (hasDVersion2074)
@safe
private uint formattedWriteRow(alias fmt, Writer, SliceKind kind, Iterator)
                                (auto ref Writer w,
                                                 Slice!(kind, [1], Iterator) sl)
    if (isSomeString!(typeof(fmt)))
{
    import std.format : formattedWrite;

    enum typeof(fmt) rowFmt = formattedWriteRowString!(fmt);
    return formattedWrite!(rowFmt)(w, sl);
}

@safe
private uint formattedWriteRow(Writer, Char, SliceKind kind, Iterator)
                                (auto ref Writer w, in Char[] fmt,
                                                 Slice!(kind, [1], Iterator) sl)
    if (isSomeChar!Char)
{
    import std.format : formattedWrite;

    auto rowFmt = formattedWriteRowString(fmt);
    return formattedWrite(w, rowFmt, sl);
}

static if (hasDVersion2074)
@safe pure
unittest
{
    import mir.ndslice.topology : iota;
    import mir.ndslice.slice : sliced;
    import std.array : appender;

    mixin formatRowsTest;

    auto w1 = appender!(string);
    formattedWriteRow!("%s")(w1, 1.iota);
    assert(w1.data == testIota1);

    auto w3 = appender!(string);
    formattedWriteRow!("%s")(w3, 3.iota);
    assert(w3.data == testIota3);

    auto w5 = appender!(string);
    formattedWriteRow!("%s")(w5, 5.iota);
    assert(w5.data == testIota5);

    auto wAlt1 = appender!(string);
    formattedWriteRow!("%s")(wAlt1, [1, 20, 300].sliced);
    assert(wAlt1.data == "| 1 20 300 |");

    auto wAlt2 = appender!(string);
    formattedWriteRow!("%2s")(wAlt2, [1, 20, 300].sliced);
    assert(wAlt2.data == "|  1 20 300 |");

    auto wAlt3 = appender!(string);
    formattedWriteRow!("%3s")(wAlt3, [1, 20, 300].sliced);
    assert(wAlt3.data == "|   1  20 300 |");
}

@safe pure
unittest
{
    import mir.ndslice.topology : iota;
    import mir.ndslice.slice : sliced;
    import std.array : appender;

    mixin formatRowsTest;

    auto w1 = appender!(string);
    formattedWriteRow(w1, "%s", 1.iota);
    assert(w1.data == testIota1);

    auto w3 = appender!(string);
    formattedWriteRow(w3, "%s", 3.iota);
    assert(w3.data == testIota3);

    auto w5 = appender!(string);
    formattedWriteRow(w5, "%s", 5.iota);
    assert(w5.data == testIota5);

    auto wAlt1 = appender!(string);
    formattedWriteRow(wAlt1, "%s", [1, 20, 300].sliced);
    assert(wAlt1.data == "| 1 20 300 |");

    auto wAlt2 = appender!(string);
    formattedWriteRow(wAlt2, "%2s", [1, 20, 300].sliced);
    assert(wAlt2.data == "|  1 20 300 |");

    auto wAlt3 = appender!(string);
    formattedWriteRow(wAlt3, "%3s", [1, 20, 300].sliced);
    assert(wAlt3.data == "|   1  20 300 |");
}

static if (hasDVersion2076)
@safe
unittest
{
    import mir.ndslice.topology : iota;

    mixin formatRowsTest;

    Counter w3;
    formattedWriteRow!"%s"(w3, 3.iota);
    assert(w3.data == testIota3.length);
}

static if (hasDVersion2076)
@safe
unittest
{
    import mir.ndslice.topology : iota;

    mixin formatRowsTest;

    Counter w3;
    formattedWriteRow(w3, "%s", 3.iota);
    assert(w3.data == testIota3.length);
}

static if (hasDVersion2076)
@safe
private size_t getRowWidth(alias fmt, Writer, SliceKind kind,
                                                       size_t[] packs, Iterator)
                            (auto ref Writer w,
                                               Slice!(kind, packs, Iterator) sl)
    if (isSomeString!(typeof(fmt)))
{
    static if (packs.length == 1)
    {
        formattedWriteRow!fmt(w, sl.deepFront);
    }
    else static if (packs.length > 1)
    {
        import mir.ndslice.topology : unpack;

        formattedWriteRow!fmt(w, sl.unpack.deepFront);
    }
    else
    {
        static assert("Should not be here");
    }

    return w.data;
}

static if (hasDVersion2076)
@safe
private size_t getRowWidth(Writer, Char, SliceKind kind, size_t[] packs,
                                                                       Iterator)
                                (auto ref Writer w, in Char[] fmt,
                                               Slice!(kind, packs, Iterator) sl)
    if (isSomeChar!Char)
{
    static if (packs.length == 1)
    {
        formattedWriteRow(w, fmt, sl.deepFront);
    }
    else static if (packs.length > 1)
    {
        import mir.ndslice.topology : unpack;

        formattedWriteRow(w, fmt, sl.unpack.deepFront);
    }
    else
    {
        static assert("Should not be here");
    }

    return w.data;
}

static if (hasDVersion2076)
@safe
unittest
{
    import mir.ndslice.topology : iota;

    Counter w432;
    auto data = [4, 3, 2].iota;
    assert(getRowWidth!"%2s"(w432, data) == 9);
}

static if (hasDVersion2076)
@safe
unittest
{
    import mir.ndslice.topology : iota;

    Counter w432;
    auto data = [4, 3, 2].iota;
    assert(getRowWidth(w432, "%2s", data) == 9);
}

@safe nothrow @nogc pure
private template formattedWriteRowsString(alias fmt)
    if (isSomeString!(typeof(fmt)))
{
    enum typeof(fmt) formattedWriteRowsString =
                         "%(" ~ formattedWriteRowString!fmt ~ "\n%) |";
}

@safe nothrow pure
private auto formattedWriteRowsString(Char)(in Char[] fmt)
    if (isSomeChar!Char)
{
    return "%(" ~ formattedWriteRowString(fmt) ~ "\n%) |";
}

static if (hasDVersion2076)
@safe
private uint formattedWriteRowsImpl(alias fmt, Writer, SliceKind kind,
                                                      size_t[1] packs, Iterator)
                                        (auto ref Writer w,
                                               Slice!(kind, packs, Iterator) sl)
    if ((packs[0] > 1) && (isSomeString!(typeof(fmt))))
{
    import std.format : formattedWrite;

    static if (packs == [2])
    {
        return formattedWrite!(formattedWriteRowsString!fmt)(w, sl);
    }
    else
    {
        @safe nothrow pure
        void formattedWriteDashes(alias fmt, Writer)
                                       (auto ref Writer w, size_t N, size_t len)
            if (isSomeString!(typeof(fmt)))
        {
            while (N > 2)
            {
                w.put("\n");
                w.formattedWriteDashline!fmt(len);
                N--;
            }
        }

        import mir.ndslice.topology : byDim;

        auto slByRow = sl.byDim!0;
        size_t slByRowLen = slByRow.length;

        size_t N = packs[0];
        Counter wDash;
        size_t len = getRowWidth!fmt(wDash, sl);

        uint result;

        size_t i = 0;
        foreach (e; slByRow)
        {
            result = formattedWriteRowsImpl!fmt(w, e);
            if (i < (slByRowLen - 1))
            {
                formattedWriteDashes!fmt(w, N, len);
                w.put("\n");
            }
            i++;
        }

        return result;
    }
}

static if (hasDVersion2076)
@safe
private uint formattedWriteRowsImpl(Writer, Char, SliceKind kind,
                                                      size_t[1] packs, Iterator)
                                        (auto ref Writer w,
                                            in Char[] fmt,
                                               Slice!(kind, packs, Iterator) sl)
    if ((packs[0] > 1) && (isSomeChar!Char))
{
    import std.format : formattedWrite;

    static if (packs == [2])
    {
        return formattedWrite(w, formattedWriteRowsString(fmt), sl);
    }
    else
    {
        @safe nothrow pure
        void formattedWriteDashes(Char, Writer)
                                     (auto ref Writer w, size_t N, size_t len)
            if (isSomeChar!Char)
        {
            while (N > 2)
            {
                w.put("\n");
                w.formattedWriteDashline!Char(len);
                N--;
            }
        }

        import mir.ndslice.topology : byDim;

        auto slByRow = sl.byDim!0;
        size_t slByRowLen = slByRow.length;

        size_t N = packs[0];
        Counter wDash;
        size_t len = getRowWidth(wDash, fmt, sl);

        uint result;

        size_t i = 0;
        foreach (e; slByRow)
        {
            result = formattedWriteRowsImpl(w, fmt, e);
            if (i < (slByRowLen - 1))
            {
                formattedWriteDashes!Char(w, N, len);
                w.put("\n");
            }
            i++;
        }

        return result;
    }
}

static if (hasDVersion2076)
@safe
unittest
{
    import mir.ndslice.topology : iota;
    import std.array : appender;

    mixin formatRowsTest;

    auto w32 = appender!(string);
    formattedWriteRowsImpl!("%s")(w32, [3, 2].iota);
    assert(w32.data == testIota32);

    auto w23 = appender!(string);
    formattedWriteRowsImpl!("%s")(w23, [2, 3].iota);
    assert(w23.data == testIota23);

    auto w43 = appender!(string);
    formattedWriteRowsImpl!("%2s")(w43, [4, 3].iota);
    assert(w43.data == testIota43);

    auto w432 = appender!(string);
    formattedWriteRowsImpl!("%2s")(w432, [4, 3, 2].iota);
    assert(w432.data == testIota432);

    auto w5432 = appender!(string);
    formattedWriteRowsImpl!("%3s")(w5432, [5, 4, 3, 2].iota);
    assert(w5432.data == testIota5432);
}

static if (hasDVersion2076)
@safe
unittest
{
    import mir.ndslice.topology : iota;
    import std.array : appender;

    mixin formatRowsTest;

    auto w32 = appender!(string);
    formattedWriteRowsImpl(w32, "%s", [3, 2].iota);
    assert(w32.data == testIota32);

    auto w23 = appender!(string);
    formattedWriteRowsImpl(w23, "%s", [2, 3].iota);
    assert(w23.data == testIota23);

    auto w43 = appender!(string);
    formattedWriteRowsImpl(w43, "%2s", [4, 3].iota);
    assert(w43.data == testIota43);

    auto w432 = appender!(string);
    formattedWriteRowsImpl(w432, "%2s", [4, 3, 2].iota);
    assert(w432.data == testIota432);

    auto w5432 = appender!(string);
    formattedWriteRowsImpl(w5432, "%3s", [5, 4, 3, 2].iota);
    assert(w5432.data == testIota5432);
}

static if (hasDVersion2076)
@safe
private uint formattedWriteRows(alias fmt, Writer, SliceKind kind,
                                                       size_t[] packs, Iterator)
                                    (auto ref Writer w,
                                               Slice!(kind, packs, Iterator) sl)
    if (isSomeString!(typeof(fmt)))
{
    import mir.math.sum : sum;

    static if (packs == [1])
    {
        return formattedWriteRow!(fmt)(w, sl);
    }
    else static if (packs.sum >= 2)
    {
        static if (packs.length == 1)
        {
            return formattedWriteRowsImpl!(fmt)(w, sl);
        }
        else static if (packs.length > 1)
        {
            import mir.ndslice.topology : unpack;

            return formattedWriteRowsImpl!(fmt)(w, sl.unpack);
        }
        else
        {
            static assert(0, "Should not be here");
        }
    }
    else
    {
        static assert(0, "Should not be here");
    }
}

static if (hasDVersion2076)
@safe
private uint formattedWriteRows(Writer, Char, SliceKind kind,
                                                       size_t[] packs, Iterator)
                                    (auto ref Writer w, in Char[] fmt,
                                               Slice!(kind, packs, Iterator) sl)
    if (isSomeChar!Char)
{
    import mir.math.sum : sum;

    static if (packs == [1])
    {
        return formattedWriteRow(w, fmt, sl);
    }
    else static if (packs.sum >= 2)
    {
        static if (packs.length == 1)
        {
            return formattedWriteRowsImpl(w, fmt, sl);
        }
        else static if (packs.length > 1)
        {
            import mir.ndslice.topology : unpack;

            return formattedWriteRowsImpl(w, fmt, sl.unpack);
        }
        else
        {
            static assert(0, "Should not be here");
        }
    }
    else
    {
        static assert(0, "Should not be here");
    }
}

static if (hasDVersion2076)
@safe
unittest
{
    import mir.ndslice.topology : iota;
    import std.array : appender;

    mixin formatRowsTest;

    auto w1 = appender!(string);
    formattedWriteRows!("%s")(w1, 1.iota);
    assert(w1.data == testIota1);

    auto w3 = appender!(string);
    formattedWriteRows!("%s")(w3, 3.iota);
    assert(w3.data == testIota3);

    auto w5 = appender!(string);
    formattedWriteRows!("%s")(w5, 5.iota);
    assert(w5.data == testIota5);

    auto w32 = appender!(string);
    formattedWriteRows!("%s")(w32, [3, 2].iota);
    assert(w32.data == testIota32);

    auto w23 = appender!(string);
    formattedWriteRows!("%s")(w23, [2, 3].iota);
    assert(w23.data == testIota23);

    auto w43 = appender!(string);
    formattedWriteRows!("%2s")(w43, [4, 3].iota);
    assert(w43.data == testIota43);

    auto w432 = appender!(string);
    formattedWriteRows!("%2s")(w432, [4, 3, 2].iota);
    assert(w432.data == testIota432);

    auto w5432 = appender!(string);
    formattedWriteRows!("%3s")(w5432, [5, 4, 3, 2].iota);
    assert(w5432.data == testIota5432);
}

static if (hasDVersion2076)
@safe
unittest
{
    import mir.ndslice.topology : iota;
    import std.array : appender;

    mixin formatRowsTest;

    auto w1 = appender!(string);
    formattedWriteRows(w1, "%s", 1.iota);
    assert(w1.data == testIota1);

    auto w3 = appender!(string);
    formattedWriteRows(w3, "%s", 3.iota);
    assert(w3.data == testIota3);

    auto w5 = appender!(string);
    formattedWriteRows(w5, "%s", 5.iota);
    assert(w5.data == testIota5);

    auto w32 = appender!(string);
    formattedWriteRows(w32, "%s", [3, 2].iota);
    assert(w32.data == testIota32);

    auto w23 = appender!(string);
    formattedWriteRows(w23, "%s", [2, 3].iota);
    assert(w23.data == testIota23);

    auto w43 = appender!(string);
    formattedWriteRows(w43, "%2s", [4, 3].iota);
    assert(w43.data == testIota43);

    auto w432 = appender!(string);
    formattedWriteRows(w432, "%2s", [4, 3, 2].iota);
    assert(w432.data == testIota432);

    auto w5432 = appender!(string);
    formattedWriteRows(w5432, "%3s", [5, 4, 3, 2].iota);
    assert(w5432.data == testIota5432);
}

/++
Formatted write of slice.
Params:
    fmt = string representing the format style (follows std.format style)
    w = Output is sent to this writer. Typical output writers include
           std.array.Appender!string and std.stdio.LockingTextWriter.
    sl = input slice
See_also:
    std.format
+/
static if (hasDVersion2076)
@safe
uint formattedWrite(alias fmt, Writer, SliceKind kind, size_t[] packs,
                                                                       Iterator)
                        (auto ref Writer w, Slice!(kind, packs, Iterator) sl)
    if (isSomeString!(typeof(fmt)))
{
    Counter wDash;
    size_t rowWidth = getRowWidth!(fmt)(wDash, sl);

    w.formattedWriteHyphenline!fmt(rowWidth);
    w.put("\n");
    uint result = formattedWriteRows!fmt(w, sl);
    w.put("\n");
    w.formattedWriteHyphenline!fmt(rowWidth);

    return result;
}

///
static if (hasDVersion2076)
@safe
uint formattedWrite(Writer, Char, SliceKind kind, size_t[] packs, Iterator)
                        (auto ref Writer w, in Char[] fmt,
                                               Slice!(kind, packs, Iterator) sl)
    if (isSomeChar!Char)
{
    Counter wDash;
    size_t rowWidth = getRowWidth(wDash, fmt, sl);

    w.formattedWriteHyphenline!Char(rowWidth);
    w.put("\n");
    uint result = formattedWriteRows(w, fmt, sl);
    w.put("\n");
    w.formattedWriteHyphenline!Char(rowWidth);

    return result;
}

///
static if (hasDVersion2076)
@safe
unittest
{
    import mir.ndslice.topology : iota;
    import std.array : appender;

    auto w1 = appender!(string);
    formattedWrite!"%s"(w1, 1.iota);

    assert(w1.data ==
        " --- \n" ~
        "| 0 |\n" ~
        " --- "
    );

    auto w5 = appender!(string);
    formattedWrite!"%s"(w5, 5.iota);
    assert(w5.data ==
        " ----------- \n" ~
        "| 0 1 2 3 4 |\n" ~
        " ----------- "
    );

    auto w32 = appender!(string);
    formattedWrite!"%s"(w32, [3, 2].iota);
    assert(w32.data ==
        " ----- \n" ~
        "| 0 1 |\n" ~
        "| 2 3 |\n" ~
        "| 4 5 |\n" ~
        " ----- "
    );

    auto w23 = appender!(string);
    formattedWrite!"%s"(w23, [2, 3].iota);
    assert(w23.data ==
        " ------- \n" ~
        "| 0 1 2 |\n" ~
        "| 3 4 5 |\n" ~
        " ------- "
    );

    auto w5432 = appender!(string);
    formattedWrite!"%3s"(w5432, [5, 4, 3, 2].iota);
    assert(w5432.data ==
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

///
static if (hasDVersion2076)
@safe
unittest
{
    import mir.ndslice.topology : iota;
    import std.array : appender;

    auto w1 = appender!(string);
    formattedWrite(w1, "%s", 1.iota);

    assert(w1.data ==
        " --- \n" ~
        "| 0 |\n" ~
        " --- "
    );

    auto w5 = appender!(string);
    formattedWrite(w5, "%s", 5.iota);
    assert(w5.data ==
        " ----------- \n" ~
        "| 0 1 2 3 4 |\n" ~
        " ----------- "
    );

    auto w32 = appender!(string);
    formattedWrite(w32, "%s", [3, 2].iota);
    assert(w32.data ==
        " ----- \n" ~
        "| 0 1 |\n" ~
        "| 2 3 |\n" ~
        "| 4 5 |\n" ~
        " ----- "
    );

    auto w23 = appender!(string);
    formattedWrite(w23, "%s", [2, 3].iota);
    assert(w23.data ==
        " ------- \n" ~
        "| 0 1 2 |\n" ~
        "| 3 4 5 |\n" ~
        " ------- "
    );

    auto w5432 = appender!(string);
    formattedWrite(w5432, "%3s", [5, 4, 3, 2].iota);
    assert(w5432.data ==
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

static if (hasDVersion2076)
@safe
unittest
{
    import mir.ndslice.topology : iota;
    import std.array : appender;

    mixin formatSliceTest;

    auto w1 = appender!(string);
    formattedWrite!("%s")(w1, 1.iota);
    assert(w1.data == testIota1Final);

    auto w3 = appender!(string);
    formattedWrite!("%s")(w3, 3.iota);
    assert(w3.data == testIota3Final);

    auto w5 = appender!(string);
    formattedWrite!("%s")(w5, 5.iota);
    assert(w5.data == testIota5Final);

    auto w32 = appender!(string);
    formattedWrite!("%s")(w32, [3, 2].iota);
    assert(w32.data == testIota32Final);

    auto w23 = appender!(string);
    formattedWrite!("%s")(w23, [2, 3].iota);
    assert(w23.data == testIota23Final);

    auto w43 = appender!(string);
    formattedWrite!("%2s")(w43, [4, 3].iota);
    assert(w43.data == testIota43Final);

    auto w432 = appender!(string);
    formattedWrite!("%2s")(w432, [4, 3, 2].iota);
    assert(w432.data == testIota432Final);

    auto w5432 = appender!(string);
    formattedWrite!("%3s")(w5432, [5, 4, 3, 2].iota);
    assert(w5432.data == testIota5432Final);
}

static if (hasDVersion2076)
@safe
unittest
{
    import mir.ndslice.topology : iota;
    import std.array : appender;

    mixin formatSliceTest;

    auto w1 = appender!(string);
    formattedWrite(w1, "%s", 1.iota);
    assert(w1.data == testIota1Final);

    auto w3 = appender!(string);
    formattedWrite(w3, "%s", 3.iota);
    assert(w3.data == testIota3Final);

    auto w5 = appender!(string);
    formattedWrite(w5, "%s", 5.iota);
    assert(w5.data == testIota5Final);

    auto w32 = appender!(string);
    formattedWrite(w32, "%s", [3, 2].iota);
    assert(w32.data == testIota32Final);

    auto w23 = appender!(string);
    formattedWrite(w23, "%s", [2, 3].iota);
    assert(w23.data == testIota23Final);

    auto w43 = appender!(string);
    formattedWrite(w43, "%2s", [4, 3].iota);
    assert(w43.data == testIota43Final);

    auto w432 = appender!(string);
    formattedWrite(w432, "%2s", [4, 3, 2].iota);
    assert(w432.data == testIota432Final);

    auto w5432 = appender!(string);
    formattedWrite(w5432, "%3s", [5, 4, 3, 2].iota);
    assert(w5432.data == testIota5432Final);
}

///
static if (hasDVersion2076)
@safe
unittest
{
    import mir.ndslice.topology : iota;
    import mir.ndslice.slice : sliced;
    import std.datetime : Date;
    import std.array : appender;

    auto val = [0.12, 3.12, 6.40].sliced;
    auto time = [Date(2017, 01, 01),
                 Date(2017, 03, 01),
                 Date(2017, 04, 01)].sliced;

    auto w = appender!(string);
    formattedWrite!"%s"(w, val);
    assert(w.data ==
        " --------------- \n" ~
        "| 0.12 3.12 6.4 |\n" ~
        " --------------- "
    );

    auto x = appender!(string);
    formattedWrite!"%.2f"(x, val);
    assert(x.data ==
        " ---------------- \n" ~
        "| 0.12 3.12 6.40 |\n" ~
        " ---------------- "
    );

    auto y = appender!(string);
    formattedWrite!"%.2e"(y, val);
    assert(y.data ==
        " ---------------------------- \n" ~
        "| 1.20e-01 3.12e+00 6.40e+00 |\n" ~
        " ---------------------------- "
    );

    auto z = appender!(string);
    formattedWrite!"%s"(z, time);
    assert(z.data ==
        " ------------------------------------- \n" ~
        "| 2017-Jan-01 2017-Mar-01 2017-Apr-01 |\n" ~
        " ------------------------------------- "
    );
}

///
static if (hasDVersion2076)
@safe
unittest
{
    import mir.ndslice.topology : iota;
    import mir.ndslice.slice : sliced;
    import std.datetime : Date;
    import std.array : appender;

    auto val = [0.12, 3.12, 6.40].sliced;
    auto time = [Date(2017, 01, 01),
                 Date(2017, 03, 01),
                 Date(2017, 04, 01)].sliced;

    auto w = appender!(string);
    formattedWrite(w, "%s", val);
    assert(w.data ==
        " --------------- \n" ~
        "| 0.12 3.12 6.4 |\n" ~
        " --------------- "
    );

    auto x = appender!(string);
    formattedWrite(x, "%.2f", val);
    assert(x.data ==
        " ---------------- \n" ~
        "| 0.12 3.12 6.40 |\n" ~
        " ---------------- "
    );

    auto y = appender!(string);
    formattedWrite(y, "%.2e", val);
    assert(y.data ==
        " ---------------------------- \n" ~
        "| 1.20e-01 3.12e+00 6.40e+00 |\n" ~
        " ---------------------------- "
    );

    auto z = appender!(string);
    formattedWrite(z, "%s", time);
    assert(z.data ==
        " ------------------------------------- \n" ~
        "| 2017-Jan-01 2017-Mar-01 2017-Apr-01 |\n" ~
        " ------------------------------------- "
    );
}

//testing packed versions
static if (hasDVersion2076)
@safe
unittest
{
    import mir.ndslice.topology : iota, pack, ipack;
    import std.array : appender;

    mixin formatSliceTest;

    auto w1 = appender!(string);
    formattedWrite!("%s")(w1, 1.iota);
    assert(w1.data == testIota1Final);

    auto w3 = appender!(string);
    formattedWrite!("%s")(w3, 3.iota);
    assert(w3.data == testIota3Final);

    auto w5 = appender!(string);
    formattedWrite!("%s")(w5, 5.iota);
    assert(w5.data == testIota5Final);

    auto w32 = appender!(string);
    formattedWrite!("%s")(w32, [3, 2].iota);
    assert(w32.data == testIota32Final);

    auto w23 = appender!(string);
    formattedWrite!("%s")(w23, [2, 3].iota);
    assert(w23.data == testIota23Final);

    auto w43 = appender!(string);
    formattedWrite!("%2s")(w43, [4, 3].iota);
    assert(w43.data == testIota43Final);

    auto w432 = appender!(string);
    formattedWrite!("%2s")(w432, [4, 3, 2].iota);
    assert(w432.data == testIota432Final);

    auto w5432 = appender!(string);
    formattedWrite!("%3s")(w5432, [5, 4, 3, 2].iota);
    assert(w5432.data == testIota5432Final);
}

//testing packed versions
static if (hasDVersion2076)
@safe
unittest
{
    import mir.ndslice.topology : iota, pack, ipack;
    import std.array : appender;

    mixin formatSliceTest;

    auto w32 = appender!(string);
    formattedWrite!"%s"(w32, [3, 2].iota.pack!1);
    assert(w32.data == testIota32Final);

    auto w32Alt = appender!(string);
    formattedWrite!"%s"(w32Alt, [3, 2].iota.ipack!1);
    assert(w32Alt.data == testIota32Final);

    auto w432 = appender!(string);
    formattedWrite!"%2s"(w432, [4, 3, 2].iota.pack!1);
    assert(w432.data == testIota432Final);

    auto w432Alt = appender!(string);
    formattedWrite!"%2s"(w432Alt, [4, 3, 2].iota.pack!2);
    assert(w432Alt.data == testIota432Final);

    auto w432Alt2 = appender!(string);
    formattedWrite!"%2s"(w432Alt2, [4, 3, 2].iota.ipack!1);
    assert(w432Alt2.data == testIota432Final);

    auto w432Alt3 = appender!(string);
    formattedWrite!"%2s"(w432Alt3, [4, 3, 2].iota.ipack!2);
    assert(w432Alt3.data == testIota432Final);

    auto w5432 = appender!(string);
    formattedWrite!"%3s"(w5432, [5, 4, 3, 2].iota.pack!1);
    assert(w5432.data == testIota5432Final);

    auto w5432Alt = appender!(string);
    formattedWrite!"%3s"(w5432Alt, [5, 4, 3, 2].iota.pack!2);
    assert(w5432Alt.data == testIota5432Final);

    auto w5432Alt2 = appender!(string);
    formattedWrite!"%3s"(w5432Alt2, [5, 4, 3, 2].iota.pack!3);
    assert(w5432Alt2.data == testIota5432Final);

    auto w5432Alt3 = appender!(string);
    formattedWrite!"%3s"(w5432Alt3, [5, 4, 3, 2].iota.ipack!1);
    assert(w5432Alt3.data == testIota5432Final);

    auto w5432Alt4 = appender!(string);
    formattedWrite!"%3s"(w5432Alt4, [5, 4, 3, 2].iota.ipack!2);
    assert(w5432Alt4.data == testIota5432Final);

    auto w5432Alt5 = appender!(string);
    formattedWrite!"%3s"(w5432Alt5, [5, 4, 3, 2].iota.ipack!3);
    assert(w5432Alt5.data == testIota5432Final);
}

static if (hasDVersion2076)
@safe
unittest
{
    import mir.ndslice.topology : iota, pack, ipack;
    import std.array : appender;

    mixin formatSliceTest;

    auto w32 = appender!(string);
    formattedWrite(w32, "%s", [3, 2].iota.pack!1);
    assert(w32.data == testIota32Final);

    auto w32Alt = appender!(string);
    formattedWrite(w32Alt, "%s", [3, 2].iota.ipack!1);
    assert(w32Alt.data == testIota32Final);

    auto w432 = appender!(string);
    formattedWrite(w432, "%2s", [4, 3, 2].iota.pack!1);
    assert(w432.data == testIota432Final);

    auto w432Alt = appender!(string);
    formattedWrite(w432Alt, "%2s", [4, 3, 2].iota.pack!2);
    assert(w432Alt.data == testIota432Final);

    auto w432Alt2 = appender!(string);
    formattedWrite(w432Alt2, "%2s", [4, 3, 2].iota.ipack!1);
    assert(w432Alt2.data == testIota432Final);

    auto w432Alt3 = appender!(string);
    formattedWrite(w432Alt3, "%2s", [4, 3, 2].iota.ipack!2);
    assert(w432Alt3.data == testIota432Final);

    auto w5432 = appender!(string);
    formattedWrite(w5432, "%3s", [5, 4, 3, 2].iota.pack!1);
    assert(w5432.data == testIota5432Final);

    auto w5432Alt = appender!(string);
    formattedWrite(w5432Alt, "%3s", [5, 4, 3, 2].iota.pack!2);
    assert(w5432Alt.data == testIota5432Final);

    auto w5432Alt2 = appender!(string);
    formattedWrite(w5432Alt2, "%3s", [5, 4, 3, 2].iota.pack!3);
    assert(w5432Alt2.data == testIota5432Final);

    auto w5432Alt3 = appender!(string);
    formattedWrite(w5432Alt3, "%3s", [5, 4, 3, 2].iota.ipack!1);
    assert(w5432Alt3.data == testIota5432Final);

    auto w5432Alt4 = appender!(string);
    formattedWrite(w5432Alt4, "%3s", [5, 4, 3, 2].iota.ipack!2);
    assert(w5432Alt4.data == testIota5432Final);

    auto w5432Alt5 = appender!(string);
    formattedWrite(w5432Alt5, "%3s", [5, 4, 3, 2].iota.ipack!3);
    assert(w5432Alt5.data == testIota5432Final);
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
static if (hasDVersion2076)
@safe
typeof(fmt) format(alias fmt, SliceKind kind, size_t[] packs, Iterator)
                                              (Slice!(kind, packs, Iterator) sl)
    if (isSomeString!(typeof(fmt)))
{
    import std.array : appender;

    auto w = appender!(typeof(fmt));
    uint n = formattedWrite!fmt(w, sl);
    return w.data;
}

///
static if (hasDVersion2076)
@safe
immutable(Char)[] format(Char, SliceKind kind, size_t[] packs, Iterator)
                               (in Char[] fmt, Slice!(kind, packs, Iterator) sl)
    if (isSomeChar!Char)
{
    import std.array : appender;

    auto w = appender!(immutable(Char)[]);
    uint n = formattedWrite(w, fmt, sl);
    return w.data;
}

///
static if (hasDVersion2076)
@safe
unittest
{
    import mir.ndslice.topology : iota;

    assert(1.iota.format!("%s") ==
        " --- \n" ~
        "| 0 |\n" ~
        " --- "
    );

    assert(5.iota.format!("%s") ==
        " ----------- \n" ~
        "| 0 1 2 3 4 |\n" ~
        " ----------- "
    );

    assert([3, 2].iota.format!("%s") ==
        " ----- \n" ~
        "| 0 1 |\n" ~
        "| 2 3 |\n" ~
        "| 4 5 |\n" ~
        " ----- "
    );

    assert([2, 3].iota.format!("%s") ==
        " ------- \n" ~
        "| 0 1 2 |\n" ~
        "| 3 4 5 |\n" ~
        " ------- "
    );

    assert([5, 4, 3, 2].iota.format!("%3s") ==
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

///
static if (hasDVersion2076)
@safe
unittest
{
    import mir.ndslice.topology : iota;

    assert(format("%s", 1.iota) ==
        " --- \n" ~
        "| 0 |\n" ~
        " --- "
    );

    assert(format("%s", 5.iota) ==
        " ----------- \n" ~
        "| 0 1 2 3 4 |\n" ~
        " ----------- "
    );

    assert(format("%s", [3, 2].iota) ==
        " ----- \n" ~
        "| 0 1 |\n" ~
        "| 2 3 |\n" ~
        "| 4 5 |\n" ~
        " ----- "
    );

    assert(format("%s", [2, 3].iota) ==
        " ------- \n" ~
        "| 0 1 2 |\n" ~
        "| 3 4 5 |\n" ~
        " ------- "
    );

    assert(format("%3s", [5, 4, 3, 2].iota) ==
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

static if (hasDVersion2076)
@safe
unittest
{
    import mir.ndslice.topology : iota;

    mixin formatSliceTest;

    assert(1.iota.format!("%s") == testIota1Final);
    assert(3.iota.format!("%s") == testIota3Final);
    assert(5.iota.format!("%s") == testIota5Final);
    assert([3, 2].iota.format!("%s") == testIota32Final);
    assert([2, 3].iota.format!("%s") == testIota23Final);
    assert([4, 3].iota.format!("%2s") == testIota43Final);
    assert([5, 4, 3, 2].iota.format!("%3s") == testIota5432Final);
}

static if (hasDVersion2076)
@safe
unittest
{
    import mir.ndslice.topology : iota;

    mixin formatSliceTest;

    assert(format("%s", 1.iota) == testIota1Final);
    assert(format("%s", 3.iota) == testIota3Final);
    assert(format("%s", 5.iota) == testIota5Final);
    assert(format("%s", [3, 2].iota) == testIota32Final);
    assert(format("%s", [2, 3].iota) == testIota23Final);
    assert(format("%2s", [4, 3].iota) == testIota43Final);
    assert(format("%3s", [5, 4, 3, 2].iota) == testIota5432Final);
}

///
static if (hasDVersion2076)
@safe
unittest
{
    import mir.ndslice.topology : iota;
    import mir.ndslice.slice : sliced;
    import std.datetime: Date;

    auto data = [0.12, 3.12, 6.40].sliced;
    auto time = [Date(2017, 01, 01),
                 Date(2017, 03, 01),
                 Date(2017, 04, 01)].sliced;

    assert(data.format!("%s") ==
        " --------------- \n" ~
        "| 0.12 3.12 6.4 |\n" ~
        " --------------- "
    );
    assert(data.format!("%.2f") ==
        " ---------------- \n" ~
        "| 0.12 3.12 6.40 |\n" ~
        " ---------------- "
    );

    assert(data.format!("%.2e") ==
        " ---------------------------- \n" ~
        "| 1.20e-01 3.12e+00 6.40e+00 |\n" ~
        " ---------------------------- "
    );

    assert(time.format!("%s") ==
        " ------------------------------------- \n" ~
        "| 2017-Jan-01 2017-Mar-01 2017-Apr-01 |\n" ~
        " ------------------------------------- "
    );
}

///
static if (hasDVersion2076)
@safe
unittest
{
    import mir.ndslice.topology : iota;
    import mir.ndslice.slice : sliced;
    import std.datetime: Date;

    auto data = [0.12, 3.12, 6.40].sliced;
    auto time = [Date(2017, 01, 01),
                 Date(2017, 03, 01),
                 Date(2017, 04, 01)].sliced;

    assert(format("%s", data) ==
        " --------------- \n" ~
        "| 0.12 3.12 6.4 |\n" ~
        " --------------- "
    );
    assert(format("%.2f", data) ==
        " ---------------- \n" ~
        "| 0.12 3.12 6.40 |\n" ~
        " ---------------- "
    );

    assert(format("%.2e", data) ==
        " ---------------------------- \n" ~
        "| 1.20e-01 3.12e+00 6.40e+00 |\n" ~
        " ---------------------------- "
    );

    assert(format("%s", time) ==
        " ------------------------------------- \n" ~
        "| 2017-Jan-01 2017-Mar-01 2017-Apr-01 |\n" ~
        " ------------------------------------- "
    );
}

// Testing packed versions
static if (hasDVersion2076)
@safe
unittest
{
    import mir.ndslice.topology : iota, pack, ipack;

    mixin formatSliceTest;

    assert([3, 2].iota.pack!1.format!("%s") == testIota32Final);
    assert([3, 2].iota.ipack!1.format!("%s") == testIota32Final);
    assert([4, 3, 2].iota.format!("%2s") == testIota432Final);
    assert([4, 3, 2].iota.pack!1.format!("%2s") == testIota432Final);
    assert([4, 3, 2].iota.pack!2.format!("%2s") == testIota432Final);
    assert([4, 3, 2].iota.ipack!1.format!("%2s") == testIota432Final);
    assert([4, 3, 2].iota.ipack!2.format!("%2s") == testIota432Final);
    assert([5, 4, 3, 2].iota.pack!1.format!("%3s") == testIota5432Final);
    assert([5, 4, 3, 2].iota.pack!2.format!("%3s") == testIota5432Final);
    assert([5, 4, 3, 2].iota.pack!3.format!("%3s") == testIota5432Final);
    assert([5, 4, 3, 2].iota.ipack!1.format!("%3s") == testIota5432Final);
    assert([5, 4, 3, 2].iota.ipack!2.format!("%3s") == testIota5432Final);
    assert([5, 4, 3, 2].iota.ipack!3.format!("%3s") == testIota5432Final);
}

static if (hasDVersion2076)
@safe
unittest
{
    import mir.ndslice.topology : iota, pack, ipack;

    mixin formatSliceTest;

    assert(format("%s", [3, 2].iota.pack!1) == testIota32Final);
    assert(format("%s", [3, 2].iota.ipack!1) == testIota32Final);
    assert(format("%2s", [4, 3, 2].iota) == testIota432Final);
    assert(format("%2s", [4, 3, 2].iota.pack!1) == testIota432Final);
    assert(format("%2s", [4, 3, 2].iota.pack!2) == testIota432Final);
    assert(format("%2s", [4, 3, 2].iota.ipack!1) == testIota432Final);
    assert(format("%2s", [4, 3, 2].iota.ipack!2) == testIota432Final);
    assert(format("%3s", [5, 4, 3, 2].iota.pack!1) == testIota5432Final);
    assert(format("%3s", [5, 4, 3, 2].iota.pack!2) == testIota5432Final);
    assert(format("%3s", [5, 4, 3, 2].iota.pack!3) == testIota5432Final);
    assert(format("%3s", [5, 4, 3, 2].iota.ipack!1) == testIota5432Final);
    assert(format("%3s", [5, 4, 3, 2].iota.ipack!2) == testIota5432Final);
    assert(format("%3s", [5, 4, 3, 2].iota.ipack!3) == testIota5432Final);
}

static if (hasDVersion2076)
@safe
unittest
{
    import mir.ndslice.slice : sliced;

    auto data = [0.12, 3.12, 6.40].sliced;

    assert(format("%s"w, data) ==
        " --------------- \n"w ~
        "| 0.12 3.12 6.4 |\n"w ~
        " --------------- "w
    );
}

static if (hasDVersion2076)
@safe
unittest
{
    import mir.ndslice.slice : sliced;

    auto data = [0.12, 3.12, 6.40].sliced;

    assert(format("%s"d, data) ==
        " --------------- \n"d ~
        "| 0.12 3.12 6.4 |\n"d ~
        " --------------- "d
    );
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

    @safe nothrow pure
    private string addTopBottomHyphen(string x, size_t rowWidth)
    {
        import std.array : appender;

        auto buf = appender!string();
        buf.formattedWriteHyphenline!char(rowWidth);
        buf.put("\n");
        buf.put(x);
        buf.put("\n");
        buf.formattedWriteHyphenline!char(rowWidth);

        return buf.data;
    }

    @safe nothrow pure
    unittest
    {
        mixin formatSliceTest;
        assert(testIota3.addTopBottomHyphen(9) == testIota3Final);
    }

    mixin template formatSliceTest()
    {
        mixin formatRowsTest;

        string testIota1Final = testIota1.addTopBottomHyphen(5);
        string testIota3Final = testIota3.addTopBottomHyphen(9);
        string testIota5Final = testIota5.addTopBottomHyphen(13);
        string testIota32Final = testIota32.addTopBottomHyphen(7);
        string testIota23Final = testIota23.addTopBottomHyphen(9);
        string testIota43Final = testIota43.addTopBottomHyphen(12);
        string testIota432Final = testIota432.addTopBottomHyphen(9);
        string testIota5432Final = testIota5432.addTopBottomHyphen(11);
    }
}
