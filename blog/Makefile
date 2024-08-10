
MD_FILES = $(wildcard *.md)
HTML_FILES = $(MD_FILES:.md=.html)

.PHONY: all

all: ${HTML_FILES}

%.html: pandoc_template.html %.md
	pandoc -s --toc -o $@ --template=$^

