.PHONY: setup all clean-dist clean-venv

SHELL=/bin/bash

all: clean-dist
	mkdir dist
	mkdir dist/latest
	# Static files
	cp -r src/* dist
	# Main prose documentation:
	source venv/bin/activate && cd main && make spelling && make html
	mv main/build/html dist/latest/main

setup: venv requirements.txt
	venv/bin/pip install -U -r requirements.txt

venv:
	virtualenv venv

clean-dist:
	rm -rf dist

clean-venv:
	rm -rf venv
