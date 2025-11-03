# Makefile for ETS IEEE Paper
# Compiles LaTeX document with bibliography

PAPER = ets_ieee_paper
TEX = pdflatex
BIB = bibtex
RM = rm -f

# Main build target
all: $(PAPER).pdf

# Full compilation with bibliography
$(PAPER).pdf: $(PAPER).tex
	@echo "=== First LaTeX pass ==="
	$(TEX) $(PAPER).tex
	@echo ""
	@echo "=== BibTeX pass ==="
	$(BIB) $(PAPER)
	@echo ""
	@echo "=== Second LaTeX pass ==="
	$(TEX) $(PAPER).tex
	@echo ""
	@echo "=== Final LaTeX pass ==="
	$(TEX) $(PAPER).tex
	@echo ""
	@echo "=== PDF Generated: $(PAPER).pdf ==="
	@echo ""

# Quick build (no bibliography update)
quick:
	$(TEX) $(PAPER).tex

# Clean auxiliary files
clean:
	$(RM) *.aux *.log *.bbl *.blg *.out *.toc *.lof *.lot *.fls *.fdb_latexmk *.synctex.gz

# Clean everything including PDF
distclean: clean
	$(RM) $(PAPER).pdf

# View PDF (cross-platform)
view: $(PAPER).pdf
ifeq ($(OS),Windows_NT)
	start $(PAPER).pdf
else
	@if command -v xdg-open > /dev/null; then \
		xdg-open $(PAPER).pdf; \
	elif command -v open > /dev/null; then \
		open $(PAPER).pdf; \
	else \
		echo "No PDF viewer found"; \
	fi
endif

# Check for LaTeX errors
check:
	@echo "Checking for LaTeX errors..."
	@grep -i "error\|warning" $(PAPER).log || echo "No errors found!"

# Word count (approximate)
wordcount:
	@echo "Approximate word count:"
	@detex $(PAPER).tex | wc -w

# Spell check (requires aspell)
spell:
	@echo "Running spell check..."
	@aspell -t -c $(PAPER).tex

# Help
help:
	@echo "ETS Paper Makefile"
	@echo "=================="
	@echo "Targets:"
	@echo "  make          - Full build with bibliography"
	@echo "  make quick    - Quick build (no bib update)"
	@echo "  make clean    - Remove auxiliary files"
	@echo "  make distclean - Remove all generated files"
	@echo "  make view     - Open PDF in viewer"
	@echo "  make check    - Check for LaTeX errors"
	@echo "  make wordcount - Count words (requires detex)"
	@echo "  make spell    - Spell check (requires aspell)"

.PHONY: all quick clean distclean view check wordcount spell help

