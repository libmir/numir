module numir.io;

import std.system : endian, Endian;
import std.format : format, formattedRead;
import std.stdio : File;
import std.algorithm : each, map, filter, reduce;
import std.conv : to;
import std.array : array;
import std.string : split, empty, strip;
import std.file : FileException;

import numir;
import mir.ndslice : sliced, universal, ndarray, flattened, shape, DeepElementType;


/**
   numpy -> dlang type conversion dictionary

   $(BR)
   $(BIG $(LINK2 http://pyopengl.sourceforge.net/pydoc/numpy.lib.format.html, numpy format spec))
   $(BR)
   $(BIG $(LINK2 https://dlang.org/spec/type.html, dlang type spec))
   $(BR)
*/
enum np2d = [
    "f4": "float",
    "f8": "double",
    "i4": "int",
    "i8": "long"
    ];

version (DigitalMars) {
    enum supportStaticForeach = __VERSION__ >= 2076;
} else {
    enum supportStaticForeach = false;
}

/// read bytes from file with dtype and size
auto readBytes(Dtype)(ref File file, string dtype, size_t size)
{
    import std.bitmanip : swapEndian;
    // https://docs.scipy.org/doc/numpy-1.12.0/reference/arrays.interface.html#arrays-interface

    bool littleEndian = dtype[0] == '<';
    bool bigEndian = dtype[0] == '>';

    auto dsize = (littleEndian || bigEndian) ? dtype[1 .. $] : dtype;
    Dtype[] result;

    /*
    static if (supportStaticForeach) /// FIXME: not work because of syntax-check
    {
        bool found = false;
        static foreach (npT, dT; np2d)
        {
            if (dsize == npT)
            {
                mixin ("result = cast(Dtype[]) file.rawRead(new " ~ dT ~ "[size]);");
                found = true;
            }
        }
        if (!found)
        {
            throw new FileException("dtype(%s) is not supported yet: %s".format(dtype, file.name));
        }
    }
    */
    switch (dsize)
    {
    case "i4":
        result = cast(Dtype[]) file.rawRead(new int[size]);
        break;
    case "f4":
        result = cast(Dtype[]) file.rawRead(new float[size]);
        break;
    case "f8":
        result = cast(Dtype[]) file.rawRead(new double[size]);
        break;
    case "i8":
        result = cast(Dtype[]) file.rawRead(new long[size]);
        break;
    default:
        throw new FileException("dtype(%s) is not supported yet: %s".format(dtype, file.name));
    }

    if ((littleEndian && endian == Endian.bigEndian) ||
        (bigEndian && endian == Endian.littleEndian))
    {
        // result.each!((ref a) => a = swapEndian(a));
        throw new FileException("endian conversion (file %s) is not supported yet: %s".format(dtype, file.name));
    }
    return result;
}

immutable npyfmt = "{'descr': '%s', 'fortran_order': %s, 'shape': (%s), }";


struct NpyHeaderInfo(size_t N)
{
    string descr;
    long[N] shape;
}


auto parseHeader(size_t Ndim)(string header, string path) {
    // header parsing
    string descrS, fortranS, shapeS;
    formattedRead(header, npyfmt, descrS, fortranS, shapeS);
    if (fortranS == "True")
    {
        throw new FileException("Fortran ordered ndarray is not supported yet: %s"
                                .format(path));
    }

    // shape parsing
    auto _shape = shapeS.split(",")
        .map!strip
        .filter!(a => !a.empty())
        .map!(to!size_t).array;

    if (_shape.length != Ndim)
    {
        // NOTE: mir.ndslice does not support dynamic dimensions?
        throw new FileException("your expected Ndim %s != %s in the actual npy: %s"
                                .format(Ndim, _shape.length, path));
    }

    auto shape = to!(ptrdiff_t[Ndim])(_shape);
    return NpyHeaderInfo!Ndim(descrS, shape);
}


auto enforceNPY(string magic, string path)
{
    if (magic != "\x93NUMPY")
    {
        throw new FileException("invalid npy header: %s".format(path));
    }
}


/// load numpy format file into mir.ndslice.Slice
auto loadNpy(Dtype, size_t Ndim)(string path)
{
    auto f = File(path, "rb");
    const magic = cast(string) f.rawRead(new ubyte[6]);
    enforceNPY(magic, path);

    // TODO: check version compatibility
    const majorVer = f.rawRead(new ubyte[1]);
    const minorVer = f.rawRead(new ubyte[1]);

    // header parsing
    const headerLength = f.rawRead(new ushort[1])[0];
    auto header = cast(string) f.rawRead(new ubyte[headerLength]);
    auto info = parseHeader!Ndim(header, path);
    auto size = info.shape.reduce!"a * b";
    auto storage = readBytes!Dtype(f, info.descr, size);
    return storage.sliced.view(info.shape);
}


template toDtype(D)
{
    enum endianMark = endian == Endian.littleEndian ? "<" : ">";

    /*
    static if (supportStaticForeach) /// FIXME: not work because of syntax-check
    {
        static foreach (npT, dT; np2d)
        {
            static if (D.stringof == dT)
            {
                enum toDtype = endianMark ~ npT;
            }
        }
    }
    */

    static if (is(D == float))
    {
        enum toDtype = endianMark ~ "f4";
    }
    else static if (is(D == double))
    {
        enum toDtype = endianMark ~ "f8";
    }
    else static if (is(D == int))
    {
        enum toDtype = endianMark ~ "i4";
    }
    else static if (is(D == long))
    {
        enum toDtype = endianMark ~ "i8";
    }
    else
    {
        static assert(false, "unknown type for npy %s".format(typeid(D)));
    }
}

/// create numpy format header from mir.ndslice.Slice
string npyHeader(S)(S x)
{
    enum dtype = toDtype!(DeepElementType!S);
    auto shapeStr = x.shape.to!string[1..$-1]; // omit [ and ]
    if (x.shape.length == 1)
    {
        shapeStr ~= ",";
    }
    return format(npyfmt ~ "\n", dtype, "False", shapeStr);
}

///
unittest
{
    import mir.ndslice : iota, sliced, map;

    auto endianMark = endian == Endian.littleEndian ? "<" : ">";
    string descrS, fortranS, shapeS;

    auto a1 = iota(1).map!(to!int);
    auto h1 = a1.npyHeader;
    formattedRead(h1, npyfmt, descrS, fortranS, shapeS);
    assert(descrS == endianMark ~ "i4");
    assert(fortranS == "False");
    assert(shapeS == "1,");

    auto a23 = iota(2, 3).map!(to!double);
    auto h23 = a23.npyHeader;
    formattedRead(h23, npyfmt, descrS, fortranS, shapeS);
    assert(descrS == endianMark ~ "f8");
    assert(fortranS == "False");
    assert(shapeS == "2, 3");

}

/// save mir.ndslice.Slice as numpy file format
void saveNpy(S)(string path, S x)
{
    auto f = File(path, "wb");
    f.rawWrite(cast(ubyte[]) "\x93NUMPY");

    ubyte major = 1;
    ubyte minor = 0;
    f.rawWrite([major, minor]);

    auto header = cast(ubyte[]) npyHeader(x);
    f.rawWrite([cast(ushort) header.length]);
    f.rawWrite(header);
    f.rawWrite(x.flattened.ndarray);
}


/// 
unittest
{
    import mir.ndslice : iota, map;

    // FIXME: make this generic
    auto a1_i4 = loadNpy!(int, 1)("./test/a1_i4.npy");
    assert(a1_i4 == iota(6).map!(to!int));
    auto a2_i4 = loadNpy!(int, 2)("./test/a2_i4.npy");
    assert(a2_i4 == iota(2, 3).map!(to!int));
    saveNpy("./test/b1_i4.npy", a1_i4);
    saveNpy("./test/b2_i4.npy", a2_i4);
    auto b1_i4 = loadNpy!(int, 1)("./test/b1_i4.npy");
    assert(b1_i4 == iota(6).map!(to!int));
    auto b2_i4 = loadNpy!(int, 2)("./test/b2_i4.npy");
    assert(b2_i4 == iota(2, 3).map!(to!int));

    auto a1_i8 = loadNpy!(long, 1)("./test/a1_i8.npy");
    assert(a1_i8 == iota(6).map!(to!long));
    auto a2_i8 = loadNpy!(long, 2)("./test/a2_i8.npy");
    assert(a2_i8 == iota(2, 3).map!(to!long));
    saveNpy("./test/b1_i8.npy", a1_i8);
    saveNpy("./test/b2_i8.npy", a2_i8);
    auto b1_i8 = loadNpy!(long, 1)("./test/b1_i8.npy");
    assert(b1_i8 == iota(6).map!(to!long));
    auto b2_i8 = loadNpy!(long, 2)("./test/b2_i8.npy");
    assert(b2_i8 == iota(2, 3).map!(to!long));

    auto a1_f4 = loadNpy!(float, 1)("./test/a1_f4.npy");
    assert(a1_f4 == iota(6).map!(to!float));
    auto a2_f4 = loadNpy!(float, 2)("./test/a2_f4.npy");
    assert(a2_f4 == iota(2, 3).map!(to!float));
    saveNpy("./test/b1_f4.npy", a1_f4);
    saveNpy("./test/b2_f4.npy", a2_f4);
    auto b1_f4 = loadNpy!(float, 1)("./test/b1_f4.npy");
    assert(b1_f4 == iota(6).map!(to!float));
    auto b2_f4 = loadNpy!(float, 2)("./test/b2_f4.npy");
    assert(b2_f4 == iota(2, 3).map!(to!float));

    auto a1_f8 = loadNpy!(double, 1)("./test/a1_f8.npy");
    assert(a1_f8 == iota(6).map!(to!double));
    auto a2_f8 = loadNpy!(double, 2)("./test/a2_f8.npy");
    assert(a2_f8 == iota(2, 3).map!(to!double));
    saveNpy("./test/b1_f8.npy", a1_f8);
    saveNpy("./test/b2_f8.npy", a2_f8);
    auto b1_f8 = loadNpy!(double, 1)("./test/b1_f8.npy");
    assert(b1_f8 == iota(6).map!(to!double));
    auto b2_f8 = loadNpy!(double, 2)("./test/b2_f8.npy");
    assert(b2_f8 == iota(2, 3).map!(to!double));
}

unittest
{
    // test exceptions
    auto f = File("./test/b1_f8.npy", "rb");
    try
    {
        readBytes!double(f, "x4", 1LU);
    }
    catch (FileException e)
    {
        // NOTE: why ": Success" is appended on Linux?
        auto expected = "dtype(%s) is not supported yet: %s".format("x4", f.name);
        assert(e.msg[0 .. expected.length] == expected);
    }

    auto fi8 = File("./test/b1_f8.npy", "rb");
    auto es = (endian == Endian.littleEndian ? ">" : "<") ~ "i8";
    try
    {
        readBytes!double(fi8, es, 1LU);
    }
    catch (FileException e)
    {
        // NOTE: why ": Success" is appended?
        auto expected = "endian conversion (file %s) is not supported yet: %s".format(es, fi8.name);
        assert(e.msg[0 .. expected.length] == expected);
    }


    auto fname = "foo.npy";
    try
    {
        parseHeader!1("{'descr': '<f4', 'fortran_order': True, 'shape': (6,), }", fname);
    }
    catch (FileException e)
    {
        // NOTE: why ": Success" is appended?
        auto expected = "Fortran ordered ndarray is not supported yet: %s".format(fname);
        assert(e.msg[0 .. expected.length] == expected);
    }

    try
    {
        parseHeader!2("{'descr': '<f4', 'fortran_order': False, 'shape': (6,), }", fname);
    }
    catch (FileException e)
    {
        // NOTE: why ": Success" is appended?
        auto expected = "your expected Ndim %s != %s in the actual npy: %s".format(2, 1, fname);
        assert(e.msg[0 .. expected.length] == expected);
    }

    try
    {
        enforceNPY("foo", fname);
    }
    catch (FileException e)
    {
        auto expected = "invalid npy header: %s".format(fname);
        assert(e.msg[0 .. expected.length] == expected);
    }
}
