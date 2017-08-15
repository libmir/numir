.PHONY: doc test clean


clean:
	dub clean
	rm -rf *.lst .*.lst docs  __* *.a numir-test-library

doc:
	rm -rf docs
	dub run -b=docs --compiler=dmd
	mv docs/package.html docs/index.html

ddox:
	rm -rf docs
	dub run -b=ddox --compiler=dmd

hmod:
	# https://github.com/nemanja-boric-sociomantic/harbored-mod
	rm -rf docs
	hmod --exclude numir.old ./source
	mv doc docs

test:
	dub test --build=unittest-cov --compiler=dmd
	tail -n 1 source-numir*.lst

test-ldc:
	dub test --build=unittest-cov --compiler=ldc2
	tail -n 1 source-numir*.lst
