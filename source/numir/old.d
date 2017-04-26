module numir.old;

import std.algorithm;
import std.functional;
import std.range; // : isInfinite, isForwardRange, isRandomAccessRange;

sizediff_t minIndex(alias pred = "a < b", Range)(Range range)
    if (isForwardRange!Range && !isInfinite!Range &&
        is(typeof(binaryFun!pred(range.front, range.front))))
{
    if (range.empty) return -1;

    sizediff_t minPos = 0;

    static if (isRandomAccessRange!Range && hasLength!Range)
    {
        foreach (i; 1 .. range.length)
        {
            if (binaryFun!pred(range[i], range[minPos]))
            {
                minPos = i;
            }
        }
    }
    else
    {
        sizediff_t curPos = 0;
        Unqual!(typeof(range.front)) min = range.front;
        for (range.popFront(); !range.empty; range.popFront())
        {
            ++curPos;
            if (binaryFun!pred(range.front, min))
            {
                min = range.front;
                minPos = curPos;
            }
        }
    }
    return minPos;
}

sizediff_t maxIndex(alias pred = "a < b", Range)(Range range)
    if (isInputRange!Range && !isInfinite!Range &&
        is(typeof(binaryFun!pred(range.front, range.front))))
 {
     return range.minIndex!((a, b) => binaryFun!pred(b, a));
 }
