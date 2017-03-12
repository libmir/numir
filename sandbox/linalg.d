#!/usr/bin/env dub
/+ dub.json:
{
    "name": "numir-sandbox-linalg",
    "targetType":"executable",
    "dependencies": {
         "numir": { "path": "../"},
         "mir-glas": "*",
         "mir-cpuid": "*"
   },
   "lflags": ["-L$MIR_GLAS_PACKAGE_DIR", "-L$MIR_CPUID_PACKAGE_DIR"],
   	"buildTypes": {
		"debug": {
			"buildOptions": ["unittests", "debugMode", "debugInfo", "profile"]
		}
	}
}
+/

module linalg;

import numir;
import glas.ndslice;
import mir.ndslice;

alias darray = s => nparray!double(s).universal;

auto dot(A, B)(A a, B b)
{
    auto c = empty_like(a).universal;
    gemm(1.0, a.universal, b.universal, 0.0, c);
    return c;
}

unittest
{
    import std.stdio;
    auto a = darray([[1,2],[3,4]]);
    auto b = darray([[1,2],[3,4]]);
    assert(a.dot(b) == [[7,10],[15,22]]);
}

void main()
{
}
