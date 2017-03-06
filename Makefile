.PHONY: doc test clean


clean:
	dub clean
	rm -rf *.lst docs  __* *.a

doc:
	rm -rf docs
	dub run -b=docs --compiler=dmd
	cd docs
	find ./docs -name "*.html" -not -path "./docs/numir.html" -exec rm {} \;
	mv docs/numir.html docs/index.html

ddox:
	rm -rf docs
	dub run -b=ddox --compiler=dmd

test:
	dub test --build=unittest-cov
	tail -n 1 source-numir.d
