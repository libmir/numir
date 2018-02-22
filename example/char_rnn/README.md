# Character-level recurrent neural networks for language modeling

Demonstrates how to use numir with the [mir-family](https://github.com/libmir)
- [mir-algorithm](http://docs.algorithm.dlang.io/latest/index.html) for the basic algorithm,
- [mir-random](http://docs.random.dlang.io/latest/index.html) for the random number generation,
- [lubeck](https://github.com/kaleidicassociates/lubeck) for the high-level wrapper of BLAS/LAPACK functions
- [mir-blas](https://github.com/libmir/mir-blas) for the low-level wrapper of BLAS/LAPACK functions.

Also you can see how I improved this code in https://github.com/kaleidicassociates/lubeck/issues/8

This implementation is based on [tiny numpy RNN](https://gist.github.com/karpathy/d4dee566867f8291f086).

## usage

``` console
$ wget https://raw.githubusercontent.com/karpathy/char-rnn/master/data/tinyshakespeare/input.txt

$ export OMP_NUM_THREADS=1

$ time dub run -b=release-nobounds --compiler=ldc2
...
iter 9900, loss: 54.466940, iter/sec: 2173.913043
./numir-char-rnn  4.78s user 0.02s system 99% cpu 4.793 total

$ time dub run -b=release-nobounds --compiler=dmd
...
iter 9900, loss: 55.695879, iter/sec: 1298.701299
./numir-char-rnn  7.94s user 0.00s system 99% cpu 7.953 total

$ time python rnn.py
...
iter 9900, loss: 56.042335, iter/sec 529.142218
python rnn.py  18.46s user 0.02s system 99% cpu 18.491 total
```

## results

my environment
- anaconda=4.3.30
- numpy=1.13.3
- numir=0.1.0 (see dub.selections.json)
- BLAS/Lapack=IntelMKL in anaconda
- CPU=Intel(R) Core(TM) i7-6820HQ CPU @ 2.70GHz

| lib                 | `OMP_NUM_THREADS` | 10000 iter time (sec) | 10000 iter loss |
| :--                 | :--               |                   --: |             --: |
| numpy               | 1                 |                 18.46 |           56.04 |
| numir (dmd 2.078.3) | 1                 |                  7.94 |           55,69 |
| numir (ldc2 1.7.0)  | 1                 |              **4.78** |           54.46 |


numir is about 3.86 times faster than numpy


## examples

after 1000000 iter (13 min), the sampled chars become

```
deremer not o', spear
So; these were through kis.

HENRY PERCY:
Him!
Now'd man is a many bone chait.
Th.

THIN:
Nor air true evern dey'd truity I coming warn you hands
Finched Tybsh soultan the is wit
-----
iter 999900, loss: 43.986925, iter/sec: 1204.819277
dub run -b=release-nobounds --compiler=ldc2  829.59s user 1.04s system 99% cpu 13:52.50 total
```
