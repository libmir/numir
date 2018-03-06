.PHONY: doc test test-ldc clean


clean:
	dub clean
	rm -rf *.lst .*.lst docs  __* *.a numir-test-library

doc:
	rm -rf docs
	# allow failure
	dub build -b=ddox --compiler=dmd && mv docs ddox || true
	dub run -b=docs --compiler=dmd
	mv docs/package.html docs/index.html
	mv ddox docs/ddox || true

ddoc:
	rm -rf docs
	dub run -b=docs --compiler=dmd
	mv docs/package.html docs/index.html

ddox:
	rm -rf docs
	dub build -b=ddox --compiler=dmd

hmod:
	# https://github.com/nemanja-boric-sociomantic/harbored-mod
	rm -rf docs
	hmod --exclude numir.old ./source
	mv doc docs

test/a1_f4.npy: test/test_npy_fileio.py
	cd test && python test_npy_fileio.py && cd ..

test: test/a1_f4.npy
	dub test --build=unittest-cov --compiler=dmd --arch=x86
	tail -n 1 source-numir*.lst
	dub test --build=unittest-cov --compiler=dmd --arch=x86
	tail -n 1 source-numir*.lst

test-ldc: test/a1_f4.npy
	dub test --build=unittest-cov --compiler=ldc2
	tail -n 1 source-numir*.lst
	dub test --build=unittest-cov --compiler=dmd --arch=x86
	tail -n 1 source-numir*.lst
