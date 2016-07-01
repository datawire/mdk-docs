.PHONY: setup all

SHELL=/bin/bash

all:
	source venv/bin/activate && cd main && make spelling && make html
	echo "\n\n\nNew docs available for preview: main/build/html/index.html"

setup: venv requirements.txt
	venv/bin/pip install -U -r requirements.txt

venv:
	virtualenv venv
