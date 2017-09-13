import numpy

a = numpy.arange(6)
for t in ["f", "i"]:
    for word in ["4", "8"]:
        dtype = t + word
        numpy.save("a1_" + dtype + ".npy", a.astype(dtype))
        numpy.save("a2_" + dtype + ".npy", a.reshape(2, 3).astype(dtype))
