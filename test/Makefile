TEXLIVEONFLY = $(shell which texliveonfly)

test-pdflatex:
	python3 $(TEXLIVEONFLY) -c latexmk -a "-g -pdf -halt-on-error -interaction=nonstopmode" test.tex
	file test.pdf | grep -q ' PDF '

test-bibtex:
	python3 $(TEXLIVEONFLY) -c latexmk -a "-g -pdf -halt-on-error -interaction=nonstopmode" bibtex.tex
	file bibtex.pdf | grep -q ' PDF '

test-biblatex:
	python3 $(TEXLIVEONFLY) -c latexmk -a "-g -pdf -halt-on-error -interaction=nonstopmode" biblatex.tex
	file biblatex.pdf | grep -q ' PDF '

test-latexindent:
	latexindent -g=/dev/null test.tex

clean:
	latexmk -C

.PHONY: test-pdflatex test-bibtex test-biblatex test-latexindent clean
