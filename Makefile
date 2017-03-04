.PHONY: doc test clean


clean:
	dub clean
	rm -rf *.lst docs  __* *.a

docs/index.html: source/numir.d
	dub build --build=docs
	cd docs
	find ./docs -name "*.html" -not -path "./docs/numir.html" -exec rm {} \;
	mv docs/numir.html $@

doc: docs/index.html

test:
	dub test --build=unittest-cov
	tail -n 1 source-numir.d
