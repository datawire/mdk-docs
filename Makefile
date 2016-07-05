.PHONY: setup all clean-dist

SHELL=/bin/bash

all: clean-dist
	mkdir dist
	mkdir dist/latest
	# Static files
	cp -r src/* dist
	# Main prose documentation:
	source venv/bin/activate && cd main && make spelling && make html
	mv main/build/html dist/latest/main

clean-dist:
	rm -rf dist

setup: venv requirements.txt
	venv/bin/pip install -U -r requirements.txt

venv:
	virtualenv venv
