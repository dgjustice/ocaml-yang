default:
	dune build

clean:
	dune clean

lint:
	find ./{tests,src}/ -name *.ml  -exec ocamlformat -i {} \;

test:
	dune runtest --instrument-with bisect_ppx --force

coverage:
	bisect-ppx-report html

.PHONY: default lint coverage clean